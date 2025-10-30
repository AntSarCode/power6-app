from __future__ import annotations

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

# --- DB imports (safe on local/test) ---
try:
    from app.database import Base, engine  # type: ignore
except ImportError:  # pragma: no cover
    Base = None
    engine = None

# --- Core routers ---
from app.routes import api_router
try:
    from app.routes.stripe import router as stripe_router
except Exception:  # pragma: no cover
    stripe_router = None  # type: ignore


# ---------------------------------------------------------------------------
# Minimal bootstrap migration so fresh DBs don't miss critical columns
# ---------------------------------------------------------------------------

from sqlalchemy import inspect

def _bootstrap_migrations(db_engine) -> None:
    """Ensure critical columns exist in production DB.

    Uses SQLAlchemy's inspector to avoid IDE SQL warnings and to work
    regardless of whether a schema name is configured. Falls back to
    direct ALTER TABLE if needed.
    """
    if not db_engine:
        return

    schema = os.getenv("DB_SCHEMA", "public").strip() or None

    try:
        inspector = inspect(db_engine)
        # Prefer explicit schema if provided; also check default schema
        tables = set()
        try:
            if schema:
                tables.update(inspector.get_table_names(schema=schema))
        except Exception:
            pass
        try:
            tables.update(inspector.get_table_names())
        except Exception:
            pass

        target_table = "tasks"
        has_tasks = target_table in tables

        with db_engine.begin() as conn:
            if not has_tasks:
                # If table not visible via inspector (permissions/caching), try creating metadata at least
                # but don't create here—`Base.metadata.create_all` above handles that. Continue column path.
                pass

            # Collect existing column names (try both with and without schema)
            existing_cols = set()
            try:
                if schema:
                    existing_cols.update(c["name"] for c in inspector.get_columns(target_table, schema=schema))
            except Exception:
                pass
            try:
                existing_cols.update(c["name"] for c in inspector.get_columns(target_table))
            except Exception:
                pass

            # Ensure reviewed_at exists
            if "reviewed_at" not in existing_cols:
                ident = f'{schema+"." if schema else ""}{target_table}'
                conn.execute(text(
                    f"ALTER TABLE {ident} ADD COLUMN IF NOT EXISTS reviewed_at timestamptz NULL"
                ))

    except SQLAlchemyError as e:  # pragma: no cover
        print("⚠️  Skipped bootstrap migration:", e)


# ---------------------------------------------------------------------------
# Application factory
# ---------------------------------------------------------------------------

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

    # --- Routes ---
    application.include_router(api_router, prefix="")
    application.include_router(api_router, prefix="/api")

    if stripe_router is not None:
        application.include_router(stripe_router, prefix="/stripe")
        application.include_router(stripe_router, prefix="/api/stripe")

    # --- DB metadata + bootstrap ---
    if Base is not None and engine is not None:
        try:
            Base.metadata.create_all(bind=engine)  # type: ignore[attr-defined]
        except SQLAlchemyError:
            pass
        _bootstrap_migrations(engine)

    # --- Health checks ---
    @application.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    @application.get("/api/health")
    def api_health() -> dict[str, str]:
        return {"status": "ok"}

    return application


app = build_app()
