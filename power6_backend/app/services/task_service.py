from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import List, Optional #Tuple

from fastapi import HTTPException, status
from sqlalchemy import Date, cast
from sqlalchemy.orm import Session

from app.models.models import Task as TaskModel
from app.schemas import TaskCreate, TaskRead, TaskUpdate

# ----------------------------
# Helpers (UTC, priority, day_key)
# ----------------------------
PRIORITY_MAP = {"low": 0, "normal": 1, "high": 2}


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def priority_to_int(v) -> int:
    if isinstance(v, int):
        return v if v in (0, 1, 2) else 1
    if isinstance(v, str):
        return PRIORITY_MAP.get(v.strip().lower(), 1)
    return 1


def compute_day_key(task: TaskModel) -> str:
    dt = task.scheduled_for or task.created_at or now_utc()
    return dt.astimezone(timezone.utc).date().isoformat()


def to_task_read(task: TaskModel) -> TaskRead:
    return TaskRead(
        id=task.id,
        user_id=task.user_id,
        title=task.title,
        notes=task.notes,
        completed=bool(task.completed),
        priority=int(task.priority),
        scheduled_for=task.scheduled_for,
        created_at=task.created_at,
        completed_at=task.completed_at,
        reviewed_at=task.reviewed_at,
        day_key=compute_day_key(task),
        streak_bound=bool(task.streak_bound),
    )


def check_active_limit(db: Session, uid: int, limit: int = 6) -> None:
    active_count = (
        db.query(TaskModel)
        .filter(TaskModel.user_id == uid, TaskModel.completed.is_(False))
        .count()
    )
    if active_count >= limit:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Active task limit reached ({limit}). Complete or remove one to add a new task.",
        )


# ----------------------------
# Service API
# ----------------------------
def create_task(db: Session, user_id: int, payload: TaskCreate) -> TaskRead:
    check_active_limit(db, user_id)

    db_task = TaskModel(
        title=payload.title,
        notes=payload.notes,
        priority=priority_to_int(payload.priority),
        scheduled_for=payload.scheduled_for,
        completed=payload.completed,
        streak_bound=payload.streak_bound,
        completed_at=payload.completed_at,
        user_id=user_id,
        created_at=now_utc(),
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return to_task_read(db_task)


def list_tasks(
    db: Session,
    user_id: int,
    *,
    day: Optional[date] = None,
    completed: Optional[bool] = None,
    limit: int = 50,
    offset: int = 0,
    order: str = "-created_at",
) -> List[TaskRead]:
    q = db.query(TaskModel).filter(TaskModel.user_id == user_id)

    if completed is not None:
        q = q.filter(TaskModel.completed.is_(bool(completed)))

    if day is not None:
        q = q.filter(cast(TaskModel.created_at, Date) == day)

    desc = order.startswith("-")
    field = order.lstrip("-")
    col = getattr(TaskModel, field)
    q = q.order_by(col.desc() if desc else col.asc())

    rows = q.offset(offset).limit(limit).all()
    return [to_task_read(t) for t in rows]


def get_today_tasks(db: Session, user_id: int) -> List[TaskRead]:
    today = date.today()
    rows = (
        db.query(TaskModel)
        .filter(
            TaskModel.user_id == user_id,
            TaskModel.completed.is_(False),
            cast(TaskModel.created_at, Date) <= today,
        )
        .order_by(TaskModel.priority.desc(), TaskModel.created_at.asc())
        .all()
    )
    return [to_task_read(t) for t in rows]


def get_history(
    db: Session,
    user_id: int,
    *,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
) -> List[TaskRead]:
    today = date.today()
    from_date = from_date or (today - timedelta(days=30))
    to_date = to_date or today

    start_dt = datetime.combine(from_date, datetime.min.time(), tzinfo=timezone.utc)
    end_dt = datetime.combine(to_date, datetime.max.time(), tzinfo=timezone.utc)

    rows = (
        db.query(TaskModel)
        .filter(
            TaskModel.user_id == user_id,
            TaskModel.completed.is_(True),
            TaskModel.completed_at >= start_dt,
            TaskModel.completed_at <= end_dt,
        )
        .order_by(TaskModel.completed_at.desc())
        .all()
    )
    return [to_task_read(t) for t in rows]


def patch_task(db: Session, user_id: int, task_id: int, payload: TaskUpdate) -> TaskRead:
    task = (
        db.query(TaskModel)
        .filter(TaskModel.id == task_id, TaskModel.user_id == user_id)
        .first()
    )
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    prev_completed = bool(task.completed)
    data = payload.model_dump(exclude_unset=True)

    if "priority" in data:
        data["priority"] = priority_to_int(data["priority"])

    completed_provided = "completed" in data
    new_completed = data.pop("completed", None)

    for k, v in data.items():
        setattr(task, k, v)

    if completed_provided and new_completed is not None and new_completed != prev_completed:
        if new_completed:
            task.completed = True
            if not task.completed_at:
                task.completed_at = now_utc()
        else:
            task.completed = False
            task.completed_at = None

    db.commit()
    db.refresh(task)
    return to_task_read(task)


def toggle_task_completion(db: Session, user_id: int, task_id: int) -> TaskRead:
    task = (
        db.query(TaskModel)
        .filter(TaskModel.id == task_id, TaskModel.user_id == user_id)
        .first()
    )
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    if task.completed:
        task.completed = False
        task.completed_at = None
    else:
        task.completed = True
        if not task.completed_at:
            task.completed_at = now_utc()

    db.commit()
    db.refresh(task)
    return to_task_read(task)


def delete_task(db: Session, user_id: int, task_id: int) -> None:
    task = (
        db.query(TaskModel)
        .filter(TaskModel.id == task_id, TaskModel.user_id == user_id)
        .first()
    )
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    db.delete(task)
    db.commit()
    return None
