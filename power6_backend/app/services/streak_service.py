from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Dict, Tuple

from sqlalchemy import Date, cast, func
from sqlalchemy.orm import Session

from app.models.models import Task

# ----------------------------
# Config++
# ----------------------------
DEFAULT_STREAK_THRESHOLD: int = 6

# ----------------------------
# Helpers (UTC + counts)
# ----------------------------
def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def daily_counts(db: Session, user_id: int) -> Dict[str, int]:
    """Return {YYYY-MM-DD: count} for completed, streak-bound tasks grouped by UTC day.
    We group on DATE(completed_at) to align with UI expectations and avoid TZ drift.
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
    return {r.day.isoformat(): int(r.cnt) for r in rows if r.day is not None}


def today_count(db: Session, user_id: int) -> int:
    today = now_utc().date()
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


def compute_streak(
    db: Session,
    user_id: int,
    *,
    threshold: int = DEFAULT_STREAK_THRESHOLD,
) -> Tuple[int, int, bool]:
    """Compute (streak_count, today_count, has_completed_today) using consecutive-day logic.
    A day counts if completed_count >= threshold.
    """
    counts = daily_counts(db, user_id)
    today = now_utc().date()

    t_key = today.isoformat()
    t_count = counts.get(t_key, 0)
    has_today = t_count >= threshold

    streak = 0
    cursor = today
    while True:
        key = cursor.isoformat()
        if counts.get(key, 0) >= threshold:
            streak += 1
            cursor = cursor - timedelta(days=1)
        else:
            break

    return streak, t_count, has_today


# ----------------------------
# Service API
# ----------------------------
def get_streak_payload(
    db: Session, user_id: int, *, threshold: int = DEFAULT_STREAK_THRESHOLD
) -> dict:
    streak_count, t_count, has_today = compute_streak(db, user_id, threshold=threshold)
    return {
        "streak_count": streak_count,
        "today_count": t_count,
        "has_completed_today": has_today,
        "threshold": threshold,
    }


def refresh_streak_payload(
    db: Session, user_id: int, *, threshold: int = DEFAULT_STREAK_THRESHOLD
) -> dict:
    # Idempotent recompute; return same shape with an ok flag
    streak_count, t_count, has_today = compute_streak(db, user_id, threshold=threshold)
    return {
        "ok": True,
        "streak_count": streak_count,
        "today_count": t_count,
        "has_completed_today": has_today,
        "threshold": threshold,
    }
