from fastapi import APIRouter, Request, HTTPException
from pydantic import BaseModel
import stripe
from app.services.stripe_service import settings, create_checkout_session

router = APIRouter()

class CheckoutRequest(BaseModel):
    user_id: str
    tier: str
    interval: str  # "monthly" or "yearly"

@router.post("/webhook")
async def stripe_webhook(request: Request):
    payload = await request.body()
    sig_header = request.headers.get('stripe-signature')

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")

    if event['type'] == 'checkout.session.completed':
        # session = event['data']['object']
        # TODO: Update user tier in DB using event['data']['object']['metadata']
        pass

    return {"status": "success"}

@router.post("/create-checkout-session")
async def create_checkout(data: CheckoutRequest):
    try:
        session = create_checkout_session(data.user_id, f"{data.tier}:{data.interval}")
        return {"checkout_url": session.url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
