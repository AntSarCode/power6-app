import os
from typing import List, Optional

class Settings:
    # --- Stripe core ---
    STRIPE_SECRET_KEY: Optional[str] = os.getenv("STRIPE_SECRET_KEY")
    STRIPE_PUBLISHABLE_KEY: Optional[str] = os.getenv("STRIPE_PUBLISHABLE_KEY")
    STRIPE_WEBHOOK_SECRET: Optional[str] = os.getenv("STRIPE_WEBHOOK_SECRET")

    # --- Stripe success/cancel redirects ---
    STRIPE_SUCCESS_URL: str = os.getenv("STRIPE_SUCCESS_URL", "https://power6-app.web.app/subscribe?success=1")
    STRIPE_CANCEL_URL: str = os.getenv("STRIPE_CANCEL_URL", "https://power6-app.web.app/subscribe?canceled=1")

    # --- Legacy single-price vars (kept for backward compat) ---
    STRIPE_PRICE_ID_FREE: Optional[str] = os.getenv("STRIPE_PRICE_ID_FREE")
    STRIPE_PRICE_ID_PLUS: Optional[str] = os.getenv("STRIPE_PRICE_ID_PLUS")
    STRIPE_PRICE_ID_PRO: Optional[str] = os.getenv("STRIPE_PRICE_ID_PRO")
    STRIPE_PRICE_ID_ELITE: Optional[str] = os.getenv("STRIPE_PRICE_ID_ELITE")

    # --- New monthly/yearly price IDs ---
    STRIPE_PRICE_ID_PLUS_MONTHLY: Optional[str] = os.getenv("STRIPE_PRICE_ID_PLUS_MONTHLY") or os.getenv("STRIPE_PRICE_ID_PLUS")
    STRIPE_PRICE_ID_PLUS_YEARLY: Optional[str] = os.getenv("STRIPE_PRICE_ID_PLUS_YEARLY")

    STRIPE_PRICE_ID_PRO_MONTHLY: Optional[str] = os.getenv("STRIPE_PRICE_ID_PRO_MONTHLY") or os.getenv("STRIPE_PRICE_ID_PRO")
    STRIPE_PRICE_ID_PRO_YEARLY: Optional[str] = os.getenv("STRIPE_PRICE_ID_PRO_YEARLY")

    STRIPE_PRICE_ID_ELITE_MONTHLY: Optional[str] = os.getenv("STRIPE_PRICE_ID_ELITE_MONTHLY") or os.getenv("STRIPE_PRICE_ID_ELITE")
    STRIPE_PRICE_ID_ELITE_YEARLY: Optional[str] = os.getenv("STRIPE_PRICE_ID_ELITE_YEARLY")

    # --- App meta ---
    APP_NAME: Optional[str] = os.getenv("APP_NAME", "Power6")
    ENVIRONMENT: Optional[str] = os.getenv("ENVIRONMENT", "development")

    # --- Auth/JWT ---
    SECRET_KEY: Optional[str] = os.getenv("SECRET_KEY")
    REFRESH_SECRET_KEY: Optional[str] = os.getenv("REFRESH_SECRET_KEY")
    ALGORITHM: Optional[str] = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60))
    REFRESH_TOKEN_EXPIRE_DAYS: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", 7))

    # --- CORS / DB ---
    ALLOWED_ORIGINS: Optional[str] = os.getenv("ALLOWED_ORIGINS", "*")
    DATABASE_URL: Optional[str] = os.getenv("DATABASE_URL")

    @property
    def allowed_origins_list(self) -> List[str]:
        raw = self.ALLOWED_ORIGINS or "*"
        if raw.strip() == "*":
            return ["*"]
        return [o.strip() for o in raw.split(",") if o.strip()]

settings = Settings()
