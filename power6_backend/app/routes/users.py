# app/routes/tasks.py
from typing import List, Optional
from datetime import datetime, date, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import cast, Date

from app.database import get_db
from app.models import models
from app.schemas import schemas
from app.routes.auth import get_current_user

router = APIRouter(prefix="/tasks", tags=["Tasks"])

# --- Helpers -----------------------------------------------------------------
def _today_utc() -> date:
    return datetime.now(timezone.utc).date()

# --- Routes ------------------------------------------------------------------
@router.get("/today", response_model=List[schemas.TaskRead])
def get_today_tasks(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Return today's tasks for the current user.
    A task is considered "today" if its scheduled_for date matches today OR
    (as a fallback) it was created today.
    """
    today = _today_utc()
    q = (
        db.query(models.Task)
        .filter(models.Task.user_id == current_user.id)
        .filter(
            (cast(models.Task.scheduled_for, Date) == today)
            | (cast(models.Task.created_at, Date) == today)
        )
        .order_by(models.Task.scheduled_for.asc(), models.Task.created_at.asc())
    )
    return q.all()


@router.patch("/{task_id}", response_model=schemas.TaskRead)
def update_task(
    task_id: int,
    payload: schemas.TaskUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Update a task. Special handling for `completed` to keep `completed_at` correct.

    Rules:
    - When `completed` flips from False -> True: set `completed_at` to now (UTC) if not already set.
    - When `completed` flips from True  -> False: clear `completed_at`.
    - All other fields follow your existing `TaskUpdate` semantics.
    """
    task = (
        db.query(models.Task)
        .filter(models.Task.id == task_id, models.Task.user_id == current_user.id)
        .first()
    )
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")
    prev_completed: Optional[bool] = getattr(task, "completed", None)

    data = payload.model_dump(exclude_unset=True)

    completed_provided = "completed" in data
    new_completed = data.pop("completed", None)

    for key, val in data.items():
        setattr(task, key, val)

    # --- Completed / completed_at ---
    if completed_provided and new_completed is not None and new_completed != prev_completed:
        if new_completed:
            task.completed = True
            if not getattr(task, "completed_at", None):
                task.completed_at = datetime.now(timezone.utc)
        else:
            task.completed = False
            task.completed_at = None

    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.post("/{task_id}/toggle", response_model=schemas.TaskRead)
def toggle_task_completion(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    """Convenience endpoint used by some clients to flip completion state.
    Keeps `completed_at` in sync with the rules above.
    """
    task = (
        db.query(models.Task)
        .filter(models.Task.id == task_id, models.Task.user_id == current_user.id)
        .first()
    )
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    if task.completed:
        task.completed = False
        task.completed_at = None
    else:
        task.completed = True
        if not getattr(task, "completed_at", None):
            task.completed_at = datetime.now(timezone.utc)

    db.add(task)
    db.commit()
    db.refresh(task)
    return task
