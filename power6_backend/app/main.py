from __future__ import annotations

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Optional SQLAlchemy bits (safe if not present)
try:
    from app.database import Base, engine  # type: ignore
except ImportError:
    Base = None  # type: ignore
    engine = None  # type: ignore

# Import the top-level API router (support common layouts)
api_router = None
for path in (
    "app.api.api_router",
    "app.api_router",
    "app.routes.api_router",
    "app.routes",
):
    try:
        module = __import__(path, fromlist=["api_router"])
        api_router = getattr(module, "api_router")
        break
    except (ImportError, AttributeError):
        continue

if api_router is None:
    raise RuntimeError(
        "Could not import api_router from app.api.api_router, app.api_router, app.routes.api_router, or app.routes"
    )

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
        allow_headers=["*"],
        expose_headers=["*"],
        max_age=86400,
    )

    application.include_router(api_router)

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
