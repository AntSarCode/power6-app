from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Any, List, Optional, cast

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import Date, and_, or_, cast as sa_cast
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import Task as TaskModel
from app.models.models import User
from app.routes.auth import get_current_user
from app.schemas import TaskCreate, TaskRead, TaskUpdate

router = APIRouter(prefix="/tasks", tags=["Tasks"])

# ----------------------------
# Helpers
# ----------------------------

PRIORITY_MAP = {"low": 0, "normal": 1, "high": 2}
ALLOWED_ORDER_FIELDS = {
    "id",
    "title",
    "priority",
    "completed",
    "scheduled_for",
    "created_at",
    "completed_at",
    "reviewed_at",
    "streak_bound",
}


def _priority_to_db(v: Any) -> int:
    if isinstance(v, int):
        return v if v in (0, 1, 2) else 1
    if isinstance(v, str):
        return PRIORITY_MAP.get(v.strip().lower(), 1)
    return 1


def _now_utc() -> datetime:
    return datetime.now(timezone.utc)


def _coerce_user_id(current_user: User) -> int:
    raw = getattr(current_user, "id", None)
    if raw is None:
        raise HTTPException(status_code=401, detail="Invalid user")
    if isinstance(raw, int):
        return raw
    try:
        return int(raw)
    except (TypeError, ValueError):
        digits = "".join(ch for ch in str(raw) if ch.isdigit())
        if not digits:
            raise HTTPException(status_code=401, detail="Invalid user id")
        return int(digits)


def _compute_day_key(task: TaskModel) -> str:
    dt = task.scheduled_for or task.created_at
    if dt is None:
        return _now_utc().date().isoformat()
    return dt.astimezone(timezone.utc).date().isoformat()


def _to_task_read(task: TaskModel) -> TaskRead:
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
        day_key=_compute_day_key(task),
        streak_bound=bool(task.streak_bound),
    )


def _check_active_limit(db: Session, uid: int) -> None:
    count = (
        db.query(TaskModel)
        .filter(TaskModel.user_id == uid, TaskModel.completed.is_(False))
        .count()
    )
    if count >= 6:
        raise HTTPException(
            status_code=400,
            detail="Active task limit reached (6). Complete or remove one to add a new task.",
        )


def _get_owned_task(db: Session, uid: int, task_id: int) -> TaskModel:
    task = (
        db.query(TaskModel)
        .filter(TaskModel.id == task_id, TaskModel.user_id == uid)
        .first()
    )
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return cast(TaskModel, task)


def _apply_task_update(task: TaskModel, payload_data: dict[str, Any]) -> None:
    prev_completed = bool(getattr(task, "completed", False))

    if "priority" in payload_data:
        payload_data["priority"] = _priority_to_db(payload_data["priority"])

    completed_provided = "completed" in payload_data
    new_completed = payload_data.pop("completed", None)

    # allow reviewed_at to be written directly from review screen
    reviewed_at = payload_data.get("reviewed_at")

    for key, value in payload_data.items():
        setattr(task, key, value)

    if completed_provided and new_completed is not None and new_completed != prev_completed:
        if new_completed:
            task.completed = True
            if not getattr(task, "completed_at", None):
                task.completed_at = _now_utc()
        else:
            task.completed = False
            task.completed_at = None
            # if task is reopened it should no longer count as reviewed
            task.reviewed_at = None

    # if review timestamp explicitly provided, persist it
    if reviewed_at is not None:
        task.reviewed_at = reviewed_at


# ----------------------------
# Routes
# ----------------------------

@router.get("/", response_model=List[TaskRead])
def list_tasks(
    day: Optional[date] = Query(None, description="Filter by created_at date (UTC)"),
    completed: Optional[bool] = Query(None, description="Filter by completion state"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    order: str = Query("-created_at"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    uid = _coerce_user_id(current_user)
    q = db.query(TaskModel).filter(TaskModel.user_id == uid)

    if completed is not None:
        q = q.filter(TaskModel.completed.is_(bool(completed)))

    if day is not None:
        q = q.filter(sa_cast(TaskModel.created_at, Date) == day)

    desc = order.startswith("-")
    field = order.lstrip("-")
    if field not in ALLOWED_ORDER_FIELDS:
        raise HTTPException(status_code=400, detail=f"Invalid order field: {field}")

    col = getattr(TaskModel, field)
    q = q.order_by(col.desc() if desc else col.asc())

    tasks = q.offset(offset).limit(limit).all()
    return [_to_task_read(t) for t in tasks]


def _utc_day_bounds(target_day: Optional[date] = None) -> tuple[datetime, datetime]:
    day = target_day or _now_utc().date()
    start = datetime.combine(day, datetime.min.time(), tzinfo=timezone.utc)
    end = datetime.combine(day, datetime.max.time(), tzinfo=timezone.utc)
    return start, end


@router.get("/active", response_model=List[TaskRead])
def get_active_tasks(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Return the user's current working task set for the app.

    This intentionally includes:
    - all incomplete tasks, and
    - tasks completed today (UTC)

    The frontend review/dashboard flows need both sets present after a sync so
    completed-today items do not disappear immediately after PATCH/toggle.
    """
    uid = _coerce_user_id(current_user)
    day_start, day_end = _utc_day_bounds()

    tasks = (
        db.query(TaskModel)
        .filter(
            TaskModel.user_id == uid,
            or_(
                TaskModel.completed.is_(False),
                and_(
                    TaskModel.completed.is_(True),
                    TaskModel.completed_at.is_not(None),
                    TaskModel.completed_at >= day_start,
                    TaskModel.completed_at <= day_end,
                ),
            ),
        )
        .order_by(
            TaskModel.completed.asc(),
            TaskModel.priority.desc(),
            TaskModel.created_at.asc(),
        )
        .all()
    )
    return [_to_task_read(t) for t in tasks]


@router.get("/history", response_model=List[TaskRead])
def get_history(
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    uid = _coerce_user_id(current_user)
    today = date.today()
    from_date = from_date or (today - timedelta(days=30))
    to_date = to_date or today

    tasks = (
        db.query(TaskModel)
        .filter(
            TaskModel.user_id == uid,
            TaskModel.completed.is_(True),
            TaskModel.completed_at >= datetime.combine(
                from_date, datetime.min.time(), tzinfo=timezone.utc
            ),
            TaskModel.completed_at <= datetime.combine(
                to_date, datetime.max.time(), tzinfo=timezone.utc
            ),
        )
        .order_by(TaskModel.completed_at.desc())
        .all()
    )
    return [_to_task_read(t) for t in tasks]


@router.post("/", response_model=TaskRead, status_code=status.HTTP_201_CREATED)
def create_task(
    task: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    uid = _coerce_user_id(current_user)
    _check_active_limit(db, uid)

    completed_at = task.completed_at
    if task.completed and completed_at is None:
        completed_at = _now_utc()

    db_task = TaskModel(
        title=task.title,
        notes=task.notes,
        priority=_priority_to_db(task.priority),
        scheduled_for=task.scheduled_for,
        completed=task.completed,
        streak_bound=task.streak_bound,
        completed_at=completed_at,
        user_id=uid,
        created_at=_now_utc(),
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return _to_task_read(db_task)


@router.patch("/{task_id}", response_model=TaskRead)
def patch_task(
    task_id: int,
    payload: TaskUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    uid = _coerce_user_id(current_user)
    task = _get_owned_task(db, uid, task_id)
    data = payload.model_dump(exclude_unset=True)

    _apply_task_update(task, data)

    db.commit()
    db.refresh(task)
    return _to_task_read(task)


@router.post("/{task_id}/toggle", response_model=TaskRead)
def toggle_task_completion(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    uid = _coerce_user_id(current_user)
    task = _get_owned_task(db, uid, task_id)

    if task.completed:
        task.completed = False
        task.completed_at = None
    else:
        task.completed = True
        if not getattr(task, "completed_at", None):
            task.completed_at = _now_utc()

    db.commit()
    db.refresh(task)
    return _to_task_read(task)


@router.put("/{task_id}", response_model=TaskRead)
def update_task(
    task_id: int,
    updated_task: TaskUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    uid = _coerce_user_id(current_user)
    task = _get_owned_task(db, uid, task_id)
    update_data = updated_task.model_dump(exclude_unset=True)

    _apply_task_update(task, update_data)

    db.commit()
    db.refresh(task)
    return _to_task_read(task)


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    uid = _coerce_user_id(current_user)
    task = _get_owned_task(db, uid, task_id)

    db.delete(task)
    db.commit()
    return None

