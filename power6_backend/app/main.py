from __future__ import annotations

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import SQLAlchemyError

# --- DB metadata creation ---
try:
    from app.database import Base, engine  # type: ignore
except ImportError:
    Base = None
    engine = None

from app.routes import api_router
from app.routes.stripe import router as stripe_router

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

    # mount routes at root
    application.include_router(api_router, prefix="")
    application.include_router(stripe_router, prefix="/stripe")

    # --- optional automatic metadata creation (safe-guarded) ---
    if Base is not None and engine is not None:
        try:
            Base.metadata.create_all(bind=engine)  # type: ignore[attr-defined]
        except SQLAlchemyError:
            pass

    @application.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    return application

app = build_app()
