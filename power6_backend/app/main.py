from __future__ import annotations

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import SQLAlchemyError

# --- DB metadata creation ---
try:
    from app.database import Base, engine  # type: ignore
except ImportError:  # pragma: no cover
    Base = None
    engine = None

# --- Core routers (aggregate) ---
from app.routes import api_router

try:
    from app.routes.stripe import router as stripe_router
except Exception:  # pragma: no cover
    stripe_router = None  # type: ignore


def build_app() -> FastAPI:
    application = FastAPI(title="Power6 API")

    # --- CORS ---
    origins = [
        "https://power6.app",
        "https://www.power6.app",
        "https://power6-app.web.app",
        "https://power6-app.firebaseapp.com",
    ]

    extra = os.getenv("ALLOWED_ORIGINS", "")
    if extra.strip():
        origins.extend([o.strip() for o in extra.split(",") if o.strip()])

    application.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=["*"],
        max_age=86400,
    )

    # --- Mount routes ---
    application.include_router(api_router, prefix="")
    application.include_router(api_router, prefix="/api")

    # --- Mount Stripe ---
    if stripe_router is not None:
        application.include_router(stripe_router, prefix="/stripe")
        application.include_router(stripe_router, prefix="/api/stripe")

    # --- DB metadata ---
    if Base is not None and engine is not None:
        try:
            Base.metadata.create_all(bind=engine)  # type: ignore[attr-defined]
        except SQLAlchemyError:
            pass

    # --- Health checks at both roots ---
    @application.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    @application.get("/api/health")
    def api_health() -> dict[str, str]:
        return {"status": "ok"}

    return application


app = build_app()
