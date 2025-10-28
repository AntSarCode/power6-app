from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func, cast, Date

from app.database import get_db
from app.routes.auth import get_current_user
from app.models.models import Task, User

router = APIRouter(prefix="/streak", tags=["Streak"])

STREAK_THRESHOLD = 6

def _yyyy_mm_dd(dt: datetime) -> str:
    return dt.date().isoformat()

def _compute_daily_counts(db: Session, user_id: int) -> dict[str, int]:
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

def _compute_current_streak(db: Session, user_id: int) -> int:
    counts = _compute_daily_counts(db, user_id)
    streak = 0
    cursor = datetime.now(timezone.utc).date()
    while True:
        key = cursor.isoformat()
        if counts.get(key, 0) >= STREAK_THRESHOLD:
            streak += 1
            cursor = cursor - timedelta(days=1)
        else:
            break
    return streak

@router.get("/", summary="Get current streak")
def get_streak(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    streak = _compute_current_streak(db, current_user.id)
    return {"streak": streak}

@router.post("/refresh", summary="Recalculate streak")
def refresh_streak(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # For now, refresh is the same as compute. Hook here if you persist streak later.
    streak = _compute_current_streak(db, current_user.id)
    return {"streak": streak, "refreshed": True}
