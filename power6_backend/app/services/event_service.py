# SPDX-License-Identifier: AGPL-3.0-or-later
"""A small, closed event vocabulary; no task text or arbitrary strings."""
from datetime import datetime, timezone

from sqlalchemy.exc import IntegrityError

from app.models.models import EventReceipt, UserEvent

CLIENT_EVENTS = {
    "onboarding_started", "onboarding_completed", "dashboard_viewed",
    "subscription_screen_viewed", "checkout_started", "pro_insights_viewed",
    "csv_export_started",
}
SERVER_EVENTS = {
    "signup_completed", "task_created", "task_completed",
    "six_tasks_planned", "six_tasks_completed", "purchase_verified",
}
LEGACY_CLIENT_EVENTS = {"signup_completed", "task_created", "task_completed"}
PROPERTY_VALUES = {
    "source": {"dashboard", "planner", "timeline", "subscription"},
    "tier": {"free", "expired", "plus", "pro", "elite", "admin"},
    "plan": {"plus", "pro", "elite"},
    "interval": {"monthly", "yearly"},
    "platform": {"ios", "android", "web", "other"},
    "environment": {"production", "sandbox"},
}
COUNTERS = {"count", "completed_today", "today_task_count"}


def begin_claim(db):
    # sqlite3's legacy mode does not BEGIN for SELECT or SAVEPOINT. Ensure that
    # releasing a nested savepoint cannot commit a claim before the outer action.
    connection = db.connection()
    if connection.dialect.name == "sqlite" and not connection.connection.driver_connection.in_transaction:
        connection.exec_driver_sql("BEGIN")


def safe_properties(raw):
    safe = {}
    for key, value in raw.items():
        if key in COUNTERS and type(value) is int and 0 <= value <= 100000:
            safe[key] = value
        elif key in PROPERTY_VALUES and isinstance(value, str):
            value = value.strip().lower()
            if value in PROPERTY_VALUES[key]:
                safe[key] = value
    return safe


def record_event(db, user, name, *, properties=None, once_key=None, now=None):
    """Join the caller's transaction. Receipt uniqueness also covers concurrent retries."""
    if name not in CLIENT_EVENTS | SERVER_EVENTS:
        raise ValueError("Unknown event")
    if once_key is not None:
        begin_claim(db)
        try:
            with db.begin_nested():
                db.add(EventReceipt(user_id=user.id, key=once_key))
                db.flush()
        except IntegrityError:
            return False
    db.add(UserEvent(
        user_id=user.id, name=name, source="server",
        tier=str(user.tier or "free").strip().lower(),
        properties=safe_properties(properties or {}),
        created_at=now or datetime.now(timezone.utc),
    ))
    return True
