from __future__ import annotations

from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import User, UserEvent
from app.routes.auth import get_current_user
from app.schemas import EventCreate, EventRead
from app.services.event_service import CLIENT_EVENTS, LEGACY_CLIENT_EVENTS, safe_properties
from app.services.launch_report import build_launch_report

router = APIRouter(prefix="/events", tags=["Events"])

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


@router.get("/launch")
def launch_report(
    days: int = Query(30, ge=1, le=120),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin(current_user)
    return build_launch_report(db, days=days)


@router.post("/", response_model=EventRead, status_code=status.HTTP_201_CREATED)
def create_event(
    payload: EventCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    name = payload.name.strip().lower()
    # Older released clients still send these. The action endpoints now own them.
    if name in LEGACY_CLIENT_EVENTS:
        return Response(status_code=status.HTTP_204_NO_CONTENT)
    if name not in CLIENT_EVENTS:
        raise HTTPException(status_code=422, detail="Unknown or server-owned event.")
    source = payload.source.strip().lower()
    if source not in {"mobile", "web"}:
        raise HTTPException(status_code=422, detail="Unsupported event source.")
    event = UserEvent(
        user_id=current_user.id, name=name, source=source,
        tier=str(current_user.tier or "free").strip().lower(),
        properties=safe_properties(payload.properties),
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return event
