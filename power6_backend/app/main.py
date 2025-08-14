from __future__ import annotations

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Optional SQLAlchemy bits (safe if not present)
try:  # narrow exception type
    from app.database import Base, engine  # type: ignore
except ImportError:
    Base = None  # type: ignore
    engine = None  # type: ignore

# Import the top-level API router (support common layouts)
try:
    from app.api.api_router import api_router  # type: ignore
except ImportError:
    try:
        from app.api_router import api_router  # type: ignore
    except ImportError as e:
        try:
            from app.routes.api_router import api_router  # type: ignore
        except ImportError:
            raise RuntimeError(
                "Could not import api_router from app.api.api_router, app.api_router, or app.routes.api_router"
            ) from e

# SQLAlchemy error type (if available) for narrow exception handling
try:
    from sqlalchemy.exc import SQLAlchemyError  # type: ignore
except ImportError:
    class SQLAlchemyError(Exception):
        pass

def _build_allowed_origins() -> list[str]:
    env_origins = os.getenv("ALLOWED_ORIGINS")
    if env_origins:
        return [o.strip() for o in env_origins.split(",") if o.strip()]

    environment = os.getenv("ENVIRONMENT", os.getenv("APP_ENV", "production")).lower()

    prod_defaults = [
        "https://power6-app.web.app",
        "https://power6-app.firebaseapp.com",
        "https://power6.app",
        "https://www.power6.app",
    ]

    if environment in {"prod", "production", "live"}:
        return prod_defaults

    return ["*"]

def build_app() -> FastAPI:
    application = FastAPI(title="Power6 Backend", version=os.getenv("APP_VERSION", "0.1.0"))

    # --- CORS ---
    origins = _build_allowed_origins()
    application.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_origin_regex=os.getenv(
            "ALLOWED_ORIGIN_REGEX",
            r"^https://([a-z0-9-]+\.)?power6\.app$",
        ),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],  # includes Authorization, Content-Type, X-Requested-With, etc.
        expose_headers=["*"],
        max_age=86400,
    )

    # --- Routers ---
    application.include_router(api_router)

    # --- Optional: ensure tables exist (skip if using Alembic migrations) ---
    if Base is not None and engine is not None:
        try:
            Base.metadata.create_all(bind=engine)  # type: ignore[attr-defined]
        except SQLAlchemyError:
            pass

    @application.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    return application

# Uvicorn/Gunicorn entrypoint
app = build_app()
