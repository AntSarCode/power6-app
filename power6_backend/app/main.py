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

                        # Ensure core columns exist
            ident = f'{schema+"." if schema else ""}{target_table}'

            def ensure(col: str, ddl: str):
                try:
                    if col not in existing_cols:
                        conn.execute(text(f"ALTER TABLE {ident} ADD COLUMN IF NOT EXISTS {col} {ddl}"))
                        existing_cols.add(col)
                except Exception as _e:
                    # continue boot even if one statement fails
                    print(f"bootstrap: skip {col}:", _e)

            ensure("reviewed_at",  "timestamptz NULL")
            ensure("scheduled_for", "timestamptz NULL")
            ensure("streak_bound",  "boolean NOT NULL DEFAULT true")
            ensure("completed_at",  "timestamptz NULL")
            ensure("updated_at",    "timestamptz NULL")

    except SQLAlchemyError as e:  # pragma: no cover
        print("⚠️  Skipped bootstrap migration:", e)


# ---------------------------------------------------------------------------
# Application factory
# ---------------------------------------------------------------------------

def build_app() -> FastAPI:
    application = FastAPI(title="Power6 API")

    # --- CORS ---
    # Allow a strict list in prod, but enable a one-switch wildcard for debugging
    allow_all = os.getenv("CORS_ALLOW_ALL", "0") == "1"

    if allow_all:
        cors_kwargs = dict(
            allow_origins=["*"],  # wildcard allowed only when not sending credentials
            allow_credentials=False,
            allow_methods=["*"],
            # Some browsers don't accept '*' for request headers; include explicit list
            allow_headers=["*", "Authorization", "authorization", "Content-Type", "Accept", "X-Requested-With"],
            expose_headers=["*", "Authorization"],
            max_age=86400,
        )
    else:
        origins = [
            "https://power6.app",
            "https://www.power6.app",
            "https://power6-app.web.app",
            "https://power6-app.firebaseapp.com",
        ]
        # Optional: support subdomains via regex
        origin_regex = r"https://([a-zA-Z0-9-]+\.)*power6\.app"

        extra = os.getenv("ALLOWED_ORIGINS", "")
        if extra.strip():
            origins.extend([o.strip() for o in extra.split(",") if o.strip()])

        cors_kwargs = dict(
            allow_origins=origins,
            allow_origin_regex=origin_regex,
            allow_credentials=True,
            allow_methods=["*"],
            # Explicitly include Authorization to satisfy strict browsers
            allow_headers=["*", "Authorization", "authorization", "Content-Type", "Accept", "X-Requested-With"],
            expose_headers=["*", "Authorization"],
            max_age=86400,
        )

    application.add_middleware(CORSMiddleware, **cors_kwargs)

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
