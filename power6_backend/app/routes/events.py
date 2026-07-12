from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, Request, status
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
