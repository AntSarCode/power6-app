# SPDX-License-Identifier: AGPL-3.0-or-later
"""Fulfil only owned sessions using current Stripe API state, never redirect claims."""
from datetime import datetime, timezone
from hashlib import sha256

import stripe
from fastapi import HTTPException

from app.config.settings import settings
from app.models.models import AppleIapTransaction, StripeCheckout, Subscription, User
from app.routes.iap import APPLE_PRODUCT_TIERS
from app.services.event_service import record_event

RANK = {"free": 0, "expired": 0, "plus": 1, "pro": 2, "elite": 3}
CHECKOUT_EVENTS = {"checkout.session.completed", "checkout.session.async_payment_succeeded"}
SUBSCRIPTION_EVENTS = {
    "customer.subscription.updated", "customer.subscription.deleted",
    "customer.subscription.paused", "customer.subscription.resumed",
}


def stripe_data(value):
    return value if isinstance(value, dict) else value.to_dict()


def price_for(tier, interval):
    if tier not in {"plus", "pro", "elite"} or interval not in {"monthly", "yearly"}:
        raise HTTPException(status_code=422, detail="Unsupported plan or billing interval.")
    value = getattr(settings, f"STRIPE_PRICE_ID_{tier.upper()}_{interval.upper()}", None)
    if not value:
        raise HTTPException(status_code=503, detail="This Stripe plan is not configured.")
    return value


def configured_mode():
    key = settings.STRIPE_SECRET_KEY or ""
    if key.startswith(("sk_live_", "rk_live_")):
        return True
    if key.startswith(("sk_test_", "rk_test_")):
        return False
    raise HTTPException(status_code=503, detail="Stripe checkout is not configured.")


def _id(value):
    return value.get("id") if isinstance(value, dict) else value


def _retrieve_subscription(subscription_id):
    return stripe_data(stripe.Subscription.retrieve(subscription_id, api_key=settings.STRIPE_SECRET_KEY))


def _price(subscription):
    items = subscription.get("items", {})
    data = items.get("data", [])
    if items.get("has_more") or len(data) != 1 or data[0].get("quantity") != 1:
        raise HTTPException(status_code=422, detail="Unexpected Stripe subscription items.")
    return _id(data[0].get("price"))


def _reconcile_user(db, user, order):
    if user.is_admin or str(user.tier).lower() == "admin":
        return
    tiers = [order.baseline_tier]
    tiers.extend(row.entitlement_tier or row.tier for row in db.query(StripeCheckout).filter_by(user_id=user.id, active=True))
    for purchase in db.query(AppleIapTransaction).filter(
        AppleIapTransaction.user_id == user.id,
        AppleIapTransaction.revoked.is_(False),
        AppleIapTransaction.expiration_date > datetime.now(timezone.utc),
    ):
        tiers.append(APPLE_PRODUCT_TIERS.get(purchase.product_id, "free"))
    user.tier = max(tiers, key=lambda tier: RANK.get(tier, 0))


def process_event(db, event):
    event = stripe_data(event)
    kind = event.get("type")
    if kind not in CHECKOUT_EVENTS | SUBSCRIPTION_EVENTS:
        return {"status": "ignored"}
    obj = event.get("data", {}).get("object", {})
    object_id = obj.get("id")
    if not isinstance(object_id, str) or not object_id:
        raise HTTPException(status_code=400, detail="Missing Stripe object ID.")
    query = db.query(StripeCheckout)
    order = (query.filter_by(session_id=object_id).first() if kind in CHECKOUT_EVENTS else
             query.filter_by(subscription_id=object_id).first())
    if order is None:
        # Legacy or unrelated checkouts have no server ownership record: no grant.
        return {"status": "untracked"}
    if type(event.get("livemode")) is not bool or event["livemode"] != order.livemode or configured_mode() != order.livemode:
        raise HTTPException(status_code=400, detail="Stripe mode mismatch.")
    if not order.livemode and not settings.STRIPE_ENABLE_TEST_ENTITLEMENTS:
        return {"status": "test_mode_ignored"}

    # Hold the account lock while fetching current state. All webhook paths use
    # this order, so delayed/duplicate events cannot overwrite a newer decision.
    user = db.query(User).filter_by(id=order.user_id).with_for_update().one()
    db.refresh(order)
    try:
        if kind in CHECKOUT_EVENTS:
            session = stripe_data(stripe.checkout.Session.retrieve(
                object_id, expand=["line_items"], api_key=settings.STRIPE_SECRET_KEY,
            ))
            if (session.get("id") != order.session_id or session.get("mode") != "subscription"
                    or session.get("livemode") != order.livemode
                    or session.get("client_reference_id") != str(user.id)):
                raise HTTPException(status_code=422, detail="Stripe checkout ownership mismatch.")
            if session.get("status") != "complete" or session.get("payment_status") != "paid":
                return {"status": "unpaid"}
            items = session.get("line_items", {})
            data = items.get("data", [])
            if (items.get("has_more") or len(data) != 1 or data[0].get("quantity") != 1
                    or _id(data[0].get("price")) != order.price_id):
                raise HTTPException(status_code=422, detail="Stripe checkout price mismatch.")
            subscription_id = _id(session.get("subscription"))
            customer_id = _id(session.get("customer"))
            if not subscription_id or not customer_id:
                raise HTTPException(status_code=422, detail="Incomplete Stripe checkout.")
            subscription = _retrieve_subscription(subscription_id)
        else:
            subscription_id, customer_id = order.subscription_id, order.customer_id
            subscription = _retrieve_subscription(subscription_id)
    except stripe.StripeError:
        # Retryable: no acknowledgement or partial grant after Stripe API failure.
        raise HTTPException(status_code=502, detail="Stripe verification is temporarily unavailable.")

    if (subscription.get("id") != subscription_id or _id(subscription.get("customer")) != customer_id
            or subscription.get("livemode") != order.livemode):
        raise HTTPException(status_code=422, detail="Stripe subscription ownership mismatch.")
    verified_price = _price(subscription)
    if verified_price == order.price_id:
        tier, interval = order.tier, order.interval
    else:
        plans = [(tier, interval) for tier in ("plus", "pro", "elite")
                 for interval in ("monthly", "yearly")
                 if getattr(settings, f"STRIPE_PRICE_ID_{tier.upper()}_{interval.upper()}", None) == verified_price]
        if len(plans) != 1:
            raise HTTPException(status_code=422, detail="Unrecognized Stripe subscription price.")
        tier, interval = plans[0]
    active = subscription.get("status") == "active"
    # Never grant a first entitlement from an unpaid or already-cancelled checkout.
    if not order.fulfilled and not active:
        return {"status": "inactive"}
    first = not order.fulfilled
    order.subscription_id, order.customer_id = subscription_id, customer_id
    # Keep the original checkout price/plan immutable: delayed completion events
    # must still validate after a legitimate subscription plan change.
    order.entitlement_tier = tier
    order.active, order.fulfilled = active, True
    row = db.get(Subscription, order.subscription_row_id) if order.subscription_row_id else None
    if row is None:
        row = Subscription(user_id=user.id, tier=tier, active=active)
        db.add(row)
        db.flush()
        order.subscription_row_id = row.id
    row.tier, row.active = tier, active
    db.flush()
    _reconcile_user(db, user, order)
    if first:
        receipt_key = "stripe-purchase:" + sha256(order.session_id.encode()).hexdigest()
        record_event(db, user, "purchase_verified", once_key=receipt_key, properties={
            "plan": tier, "interval": interval, "platform": "web",
            "environment": "production" if order.livemode else "sandbox",
        })
    db.commit()
    return {"status": "success"}
