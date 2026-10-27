# SPDX-License-Identifier: AGPL-3.0-or-later
import stripe

from app.config.settings import settings
from app.services.stripe_fulfillment import configured_mode, price_for, stripe_data


def create_checkout_session(user_id: str, tier_with_interval: str):
    tier, interval = tier_with_interval.split(":", 1)
    configured_mode()
    return stripe_data(stripe.checkout.Session.create(
        mode="subscription", payment_method_types=["card"],
        line_items=[{"price": price_for(tier, interval), "quantity": 1}],
        success_url=settings.STRIPE_SUCCESS_URL, cancel_url=settings.STRIPE_CANCEL_URL,
        client_reference_id=str(user_id),
        metadata={"user_id": str(user_id), "tier": tier, "interval": interval},
        subscription_data={"metadata": {"user_id": str(user_id)}},
        api_key=settings.STRIPE_SECRET_KEY,
    ))
