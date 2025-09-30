from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import date
import re

from app.models.models import Task as TaskModel
from app.models.models import User
from app.database import get_db
from app.routes.auth import get_current_user
from app.schemas import TaskCreate, TaskRead, TaskUpdate

PRIORITY_MAP = {"Low": 0, "Normal": 1, "High": 2}

def _priority_to_db(v) -> int:
    if isinstance(v, int):
        return v
    if isinstance(v, str):
        s = v.strip().capitalize()
        return PRIORITY_MAP.get(s, 1)  # default to Normal
    return 1


router = APIRouter(
    prefix="/tasks",
    tags=["Tasks"]
)


def _coerce_user_id(current_user: User) -> int:
    """
    Ensure we always use a plain integer user_id.
    Some auth layers may surface ids like "5" or "5:extra"; extract the first number.
    """
    raw = getattr(current_user, "id", None)
    if raw is None:
        raise HTTPException(status_code=401, detail="Invalid user")
    if isinstance(raw, int):
        return raw
    m = re.search(r"\d+", str(raw))
    if not m:
        raise HTTPException(status_code=401, detail="Invalid user id")
    return int(m.group(0))


@router.post("/upload", status_code=status.HTTP_201_CREATED)
def upload_tasks(
    tasks: List[TaskCreate],
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    today = date.today()
    uid = _coerce_user_id(current_user)

    # Remove any existing tasks for this user for "today" before bulk insert
    db.query(TaskModel).filter(
        TaskModel.user_id == uid,
        TaskModel.created_at == today
    ).delete(synchronize_session=False)

    for task in tasks:
        db_task = TaskModel(
            title=task.title,
            notes=task.notes,
            priority=_priority_to_db(task.priority),
            scheduled_for=task.scheduled_for,
            completed=task.completed,
            streak_bound=task.streak_bound,
            completed_at=task.completed_at,
            user_id=uid,
            created_at=today,
        )
        db.add(db_task)

    db.commit()
    return {"status": "success", "count": len(tasks)}


@router.get("/today", response_model=List[TaskRead], status_code=status.HTTP_200_OK)
def get_today_tasks(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    today = date.today()
    uid = _coerce_user_id(current_user)
    return (
        db.query(TaskModel)
        .filter(TaskModel.user_id == uid, TaskModel.created_at == today)
        .all()
    )


@router.post("/", response_model=TaskRead, status_code=status.HTTP_201_CREATED)
def create_task(
    task: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    uid = _coerce_user_id(current_user)
    db_task = TaskModel(
        title=task.title,
        notes=task.notes,
        priority=_priority_to_db(task.priority),
        scheduled_for=task.scheduled_for,
        completed=task.completed,
        streak_bound=task.streak_bound,
        completed_at=task.completed_at,
        user_id=uid,
        created_at=date.today(),
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task


@router.get("/", response_model=List[TaskRead], status_code=status.HTTP_200_OK)
def read_tasks(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    uid = _coerce_user_id(current_user)
    return (
        db.query(TaskModel)
        .filter(TaskModel.user_id == uid)
        .offset(skip)
        .limit(limit)
        .all()
    )


@router.get("/{task_id}", response_model=TaskRead, status_code=status.HTTP_200_OK)
def read_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    uid = _coerce_user_id(current_user)
    task = db.query(TaskModel).filter(
        TaskModel.id == task_id,
        TaskModel.user_id == uid
    ).first()
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@router.put("/{task_id}", response_model=TaskRead, status_code=status.HTTP_200_OK)
def update_task(
    task_id: int,
    updated_task: TaskUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    uid = _coerce_user_id(current_user)
    task = db.query(TaskModel).filter(
        TaskModel.id == task_id,
        TaskModel.user_id == uid
    ).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    update_data = updated_task.model_dump(exclude_unset=True)
    if "priority" in update_data:
        update_data["priority"] = _priority_to_db(update_data["priority"])
    for key, value in update_data.items():
        setattr(task, key, value)

    db.commit()
    db.refresh(task)
    return task


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    uid = _coerce_user_id(current_user)
    task = db.query(TaskModel).filter(
        TaskModel.id == task_id,
        TaskModel.user_id == uid
    ).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    db.delete(task)
    db.commit()
