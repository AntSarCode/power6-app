from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import User, UserEvent
from app.routes.auth import get_current_user
from app.schemas import EventCreate, EventRead

router = APIRouter(prefix="/events", tags=["Events"])

ALLOWED_EVENTS = {
    "signup_completed",
    "onboarding_started",
    "dashboard_viewed",
    "task_created",
    "task_completed",
    "subscription_screen_viewed",
    "checkout_started",
    "pro_insights_viewed",
    "csv_export_started",
}

SAFE_PROPERTY_KEYS = {
    "count",
    "source",
    "tier",
    "plan",
    "interval",
    "platform",
    "completed_today",
    "today_task_count",
}


def _safe_properties(raw: dict[str, Any]) -> dict[str, Any]:
    safe: dict[str, Any] = {}
    for key, value in raw.items():
        if key not in SAFE_PROPERTY_KEYS:
            continue
        if isinstance(value, (str, int, float, bool)) or value is None:
            safe[key] = value
    return safe


def _require_admin(current_user: User) -> None:
    if not bool(getattr(current_user, "is_admin", False)):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Event summaries require administrator privileges.",
        )


@router.get("/summary")
def event_summary(
    days: int = Query(30, ge=1, le=120),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin(current_user)
    since = datetime.now(timezone.utc) - timedelta(days=days)

    rows = (
        db.query(
            UserEvent.name,
            func.count(UserEvent.id),
            func.count(func.distinct(UserEvent.user_id)),
        )
        .filter(UserEvent.created_at >= since)
        .group_by(UserEvent.name)
        .order_by(UserEvent.name.asc())
        .all()
    )

    counts = {
        name: {"events": int(total), "users": int(users)}
        for name, total, users in rows
    }

    funnel_order = [
        "signup_completed",
        "onboarding_started",
        "dashboard_viewed",
        "task_created",
        "task_completed",
        "subscription_screen_viewed",
        "checkout_started",
    ]

    return {
        "window_days": days,
        "since": since.isoformat(),
        "total_events": sum(item["events"] for item in counts.values()),
        "unique_users": int(
            db.query(func.count(func.distinct(UserEvent.user_id)))
            .filter(UserEvent.created_at >= since)
            .scalar()
            or 0
        ),
        "counts": counts,
        "funnel": [
            {
                "name": name,
                "events": counts.get(name, {}).get("events", 0),
                "users": counts.get(name, {}).get("users", 0),
            }
            for name in funnel_order
        ],
    }


@router.post("/", response_model=EventRead, status_code=status.HTTP_201_CREATED)
def create_event(
    payload: EventCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    name = payload.name.strip().lower()
    if name not in ALLOWED_EVENTS:
        name = "dashboard_viewed"

    user_agent = request.headers.get("user-agent", "")
    event = UserEvent(
        user_id=current_user.id,
        name=name,
        source=payload.source.strip().lower()[:40] or "mobile",
        tier=str(current_user.tier or "free").lower(),
        properties=_safe_properties(payload.properties),
        user_agent=user_agent[:180] if user_agent else None,
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return event
