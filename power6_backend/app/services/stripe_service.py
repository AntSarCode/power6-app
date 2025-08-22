import logging
import stripe
from app.config.settings import settings

stripe.api_key = settings.STRIPE_SECRET_KEY

# Map (tier, interval) -> price id. "free" has no interval.
PRICE_LOOKUP = {
    ("free", None): getattr(settings, "STRIPE_PRICE_ID_FREE", None),
    ("plus", "monthly"): getattr(settings, "STRIPE_PRICE_ID_PLUS_MONTHLY", None),
    ("plus", "yearly"): getattr(settings, "STRIPE_PRICE_ID_PLUS_YEARLY", None),
    ("pro", "monthly"): getattr(settings, "STRIPE_PRICE_ID_PRO_MONTHLY", None),
    ("pro", "yearly"): getattr(settings, "STRIPE_PRICE_ID_PRO_YEARLY", None),
    ("elite", "monthly"): getattr(settings, "STRIPE_PRICE_ID_ELITE_MONTHLY", None),
    ("elite", "yearly"): getattr(settings, "STRIPE_PRICE_ID_ELITE_YEARLY", None),
}

SUCCESS_URL = getattr(settings, "STRIPE_SUCCESS_URL", "https://yourapp.com/success")
CANCEL_URL = getattr(settings, "STRIPE_CANCEL_URL", "https://yourapp.com/cancel")


def _parse_tier_interval(tier_with_interval: str):
    """Accepts forms like 'plus:monthly', 'pro:yearly', or 'free'. Returns (tier, interval|None)."""
    if not tier_with_interval:
        raise ValueError("Tier is required")
    parts = tier_with_interval.strip().lower().split(":")
    if len(parts) == 1:
        return parts[0], None
    if len(parts) == 2:
        tier, interval = parts[0], parts[1]
        if interval not in ("monthly", "yearly"):
            raise ValueError("Interval must be 'monthly' or 'yearly'")
        return tier, interval
    raise ValueError("Invalid tier/interval format")


def _resolve_price_id(tier: str, interval: str | None) -> str:
    key = (tier, interval)
    price_id = PRICE_LOOKUP.get(key)
    if not price_id:
        # Provide a clearer error for missing env var mapping
        if interval is None:
            raise ValueError(f"No price configured for tier '{tier}'. Check your .env.")
        raise ValueError(
            f"No price configured for tier '{tier}' with interval '{interval}'. Check your .env."
        )
    return price_id


def create_checkout_session(user_id: str, tier_with_interval: str):
    """Create a Stripe Checkout Session for subscriptions.

    tier_with_interval examples: 'plus:monthly', 'pro:yearly', 'elite:monthly', or 'free'.
    The router passes a single combined string, so we remain backward compatible with a two-arg signature upstream.
    """
    tier, interval = _parse_tier_interval(tier_with_interval)

    # For free tier, you likely don't need Checkout at all — but keep behavior explicit.
    if tier == "free":
        raise ValueError("Free tier does not require Stripe Checkout.")

    price_id = _resolve_price_id(tier, interval)

    try:
        session = stripe.checkout.Session.create(
            mode="subscription",
            payment_method_types=["card"],
            line_items=[{"price": price_id, "quantity": 1}],
            success_url=SUCCESS_URL,
            cancel_url=CANCEL_URL,
            metadata={"user_id": user_id, "tier": tier, "interval": interval or ""},
        )
        return session
    except Exception as e:
        logging.error(f"Stripe session creation failed: {e}")
        raise
