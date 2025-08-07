import stripe
import logging
from app.config.settings import settings

stripe.api_key = settings.STRIPE_SECRET_KEY

PRICE_LOOKUP = {
    "free": settings.STRIPE_PRICE_ID_FREE,
    "plus": settings.STRIPE_PRICE_ID_PLUS,
    "pro": settings.STRIPE_PRICE_ID_PRO,
    "elite": settings.STRIPE_PRICE_ID_ELITE,
}

def create_checkout_session(user_id: str, tier: str):
    if tier not in PRICE_LOOKUP:
        raise ValueError(f"Invalid tier: {tier}")

    try:
        session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            mode='subscription',
            line_items=[{
                'price': PRICE_LOOKUP[tier],
                'quantity': 1,
            }],
            success_url='https://yourapp.com/success',
            cancel_url='https://yourapp.com/cancel',
            metadata={'user_id': user_id, 'tier': tier},
        )
        return session
    except Exception as e:
        logging.error(f"Stripe session creation failed: {e}")
        raise
