# SPDX-License-Identifier: AGPL-3.0-or-later
from typing import Literal

import stripe
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, field_validator
from sqlalchemy.orm import Session
from starlette.concurrency import run_in_threadpool

from app.database import get_db
from app.models.models import StripeCheckout, User
from app.routes.auth import get_current_user
from app.services.stripe_service import create_checkout_session, settings
from app.services.stripe_fulfillment import configured_mode, price_for, process_event

router = APIRouter()


class CheckoutRequest(BaseModel):
    # Retain old-client compatibility; identity always comes from the bearer token.
    user_id: str | int | None = None
    tier: Literal["plus", "pro", "elite"]
    interval: Literal["monthly", "yearly"]

    @field_validator("tier", "interval", mode="before")
    @classmethod
    def normalize(cls, value):
        return value.strip().lower() if isinstance(value, str) else value


@router.post("/webhook")
async def stripe_webhook(request: Request, db: Session = Depends(get_db)):
    if not settings.STRIPE_WEBHOOK_SECRET:
        raise HTTPException(status_code=503, detail="Stripe webhook is not configured.")
    payload = await request.body()
    if len(payload) > 1024 * 1024:
        raise HTTPException(status_code=413, detail="Webhook payload too large.")
    signature = request.headers.get("stripe-signature")
    if not signature:
        raise HTTPException(status_code=400, detail="Missing Stripe signature.")
    try:
        event = stripe.Webhook.construct_event(payload, signature, settings.STRIPE_WEBHOOK_SECRET)
    except (ValueError, stripe.SignatureVerificationError):
        raise HTTPException(status_code=400, detail="Invalid Stripe payload or signature.")
    return await run_in_threadpool(process_event, db, event)


@router.post("/create-checkout-session")
def create_checkout(data: CheckoutRequest, db: Session = Depends(get_db),
                    current_user: User = Depends(get_current_user)):
    if data.user_id is not None and str(data.user_id) != str(current_user.id):
        raise HTTPException(status_code=403, detail="Checkout account does not match authentication.")
    price_id = price_for(data.tier, data.interval)
    mode = configured_mode()
    # Serialize creation and baseline capture for this account.
    db.query(User.id).filter_by(id=current_user.id).with_for_update().one()
    baseline = db.query(StripeCheckout).filter_by(user_id=current_user.id).order_by(
        StripeCheckout.created_at, StripeCheckout.session_id,
    ).first()
    try:
        session = create_checkout_session(str(current_user.id), f"{data.tier}:{data.interval}")
    except stripe.StripeError:
        raise HTTPException(status_code=502, detail="Stripe checkout is temporarily unavailable.")
    if (not isinstance(session.get("id"), str) or session.get("livemode") is not mode
            or not isinstance(session.get("url"), str) or not session["url"].startswith("https://")):
        raise HTTPException(status_code=502, detail="Stripe returned an invalid checkout session.")
    db.add(StripeCheckout(
        session_id=session["id"], user_id=current_user.id, tier=data.tier,
        interval=data.interval, price_id=price_id, livemode=mode,
        baseline_tier=baseline.baseline_tier if baseline else str(current_user.tier or "free").lower(),
    ))
    db.commit()
    return {"checkout_url": session["url"]}
