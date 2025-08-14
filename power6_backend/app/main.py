from __future__ import annotations

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# If you use SQLAlchemy Base/engine and want to ensure tables exist on startup
try:
    from app.database import Base, engine  # optional; ignore if you use Alembic
except Exception:  # pragma: no cover
    Base = None
    engine = None

# Your top-level API router should already mount sub-routers (auth, stripe, etc.)
try:
    from app.routes import api_router
except Exception as e:  # pragma: no cover
    raise RuntimeError("Could not import app.api.api_router: %r" % e)


def _build_allowed_origins() -> list[str]:
    """Compute CORS allowlist.

    Priority:
      1) ALLOWED_ORIGINS env var (comma-separated)
      2) Production defaults (Firebase + custom domain)
      3) Dev wildcard '*'
    """
    # If explicitly provided, trust env var
    env_origins = os.getenv("ALLOWED_ORIGINS")
    if env_origins:
        return [o.strip() for o in env_origins.split(",") if o.strip()]

    # Otherwise choose sane defaults based on environment
    environment = os.getenv("ENVIRONMENT", os.getenv("APP_ENV", "production")).lower()

    prod_defaults = [
        "https://power6-app.web.app",
        "https://power6-app.firebaseapp.com",
        "https://power6.app",
        "https://www.power6.app",
    ]

    if environment in {"prod", "production", "live"}:
        return prod_defaults

    # Development fallback: allow all
    return ["*"]


def create_app() -> FastAPI:
    app = FastAPI(title="Power6 Backend", version=os.getenv("APP_VERSION", "0.1.0"))

    # --- CORS ---
    origins = _build_allowed_origins()
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],  # includes Authorization, Content-Type, etc.
        expose_headers=["*"],
    )

    # --- Routers ---
    app.include_router(api_router)

    # --- Optional: ensure tables exist (skip if using Alembic migrations) ---
    if Base is not None and engine is not None:
        try:
            Base.metadata.create_all(bind=engine)
        except Exception:
            # Don't crash the process if migrations handle this
            pass

    @app.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    return app


app = create_app()
