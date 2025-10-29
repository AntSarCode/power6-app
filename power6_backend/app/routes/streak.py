from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Dict

from fastapi import APIRouter, Depends
from sqlalchemy import Date, cast, func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import Task, User
from app.routes.auth import get_current_user

router = APIRouter(prefix="/streak", tags=["Streak"])

# Server-side threshold for counting a "hit" day toward the streak
STREAK_THRESHOLD: int = 6


# ----------------------------
# Helpers
# ----------------------------

def _now_utc() -> datetime:
    return datetime.now(timezone.utc)


def _to_iso_date(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).date().isoformat()


def _daily_counts(db: Session, user_id: int) -> Dict[str, int]:
    """Return a mapping { 'YYYY-MM-DD': completed_count } only for
    completed & streak-bound tasks grouped by UTC day(completed_at).
    """
    rows = (
        db.query(
            cast(Task.completed_at, Date).label("day"),
            func.count().label("cnt"),
        )
        .filter(
            Task.user_id == user_id,
            Task.completed.is_(True),
            Task.streak_bound.is_(True),
            Task.completed_at.isnot(None),
        )
        .group_by("day")
        .all()
    )
    return {row.day.isoformat(): int(row.cnt) for row in rows if row.day is not None}


essential_fields = [Task.user_id, Task.completed, Task.streak_bound, Task.completed_at]


def _today_count(db: Session, user_id: int) -> int:
    today = _now_utc().date()
    q = (
        db.query(func.count())
        .filter(
            Task.user_id == user_id,
            Task.completed.is_(True),
            Task.streak_bound.is_(True),
            cast(Task.completed_at, Date) == today,
        )
    )
    return int(q.scalar() or 0)


def _compute_streak(db: Session, user_id: int) -> tuple[int, int, bool]:
    counts = _daily_counts(db, user_id)
    today = _now_utc().date()

    # Compute today first
    today_key = today.isoformat()
    today_count = counts.get(today_key, 0)
    has_completed_today = today_count >= STREAK_THRESHOLD

    # Walk backward from today
    streak = 0
    cursor = today
    while True:
        key = cursor.isoformat()
        if counts.get(key, 0) >= STREAK_THRESHOLD:
            streak += 1
            cursor = cursor - timedelta(days=1)
        else:
            break

    return streak, today_count, has_completed_today


# ----------------------------
# Routes
# ----------------------------

@router.get("/", summary="Get current streak")
def get_streak(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    streak_count, today_count, has_completed_today = _compute_streak(db, current_user.id)
    return {
        "streak_count": streak_count,
        "today_count": today_count,
        "has_completed_today": has_completed_today,
        "threshold": STREAK_THRESHOLD,
    }


@router.post("/refresh", summary="Recalculate streak (idempotent)")
def refresh_streak(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    streak_count, today_count, has_completed_today = _compute_streak(db, current_user.id)
    return {
        "ok": True,
        "streak_count": streak_count,
        "today_count": today_count,
        "has_completed_today": has_completed_today,
        "threshold": STREAK_THRESHOLD,
    }
