from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import cast, Date
from typing import List, Optional
from datetime import date, datetime, timedelta
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
        return PRIORITY_MAP.get(s, 1)
    return 1

router = APIRouter(prefix="/tasks", tags=["Tasks"])

def _coerce_user_id(current_user: User) -> int:
    raw = getattr(current_user, "id", None)
    if raw is None:
        raise HTTPException(status_code=401, detail="Invalid user")
    if isinstance(raw, int):
        return raw
    m = re.search(r"\d+", str(raw))
    if not m:
        raise HTTPException(status_code=401, detail="Invalid user id")
    return int(m.group(0))

# Enforce maximum of 6 active tasks
def _check_active_limit(db: Session, uid: int):
    count = db.query(TaskModel).filter(TaskModel.user_id == uid, TaskModel.completed == False).count()
    if count >= 6:
        raise HTTPException(status_code=400, detail="Active task limit reached (6). Complete or remove one to add a new task.")

@router.get("/today", response_model=List[TaskRead])
def get_today_tasks(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    uid = _coerce_user_id(current_user)
    today = date.today()
    tasks = (
        db.query(TaskModel)
        .filter(
            TaskModel.user_id == uid,
            ((TaskModel.completed == False) & (cast(TaskModel.created_at, Date) <= today))
        )
        .order_by(TaskModel.priority.desc())
        .all()
    )
    return tasks

@router.get("/history", response_model=List[TaskRead])
def get_history(
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    uid = _coerce_user_id(current_user)
    today = date.today()
    from_date = from_date or (today - timedelta(days=30))
    to_date = to_date or today

    return (
        db.query(TaskModel)
        .filter(
            TaskModel.user_id == uid,
            TaskModel.completed == True,
            TaskModel.completed_at >= datetime.combine(from_date, datetime.min.time()),
            TaskModel.completed_at <= datetime.combine(to_date, datetime.max.time())
        )
        .order_by(TaskModel.completed_at.desc())
        .all()
    )

@router.post("/", response_model=TaskRead, status_code=status.HTTP_201_CREATED)
def create_task(
    task: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    uid = _coerce_user_id(current_user)
    _check_active_limit(db, uid)

    db_task = TaskModel(
        title=task.title,
        notes=task.notes,
        priority=_priority_to_db(task.priority),
        scheduled_for=task.scheduled_for,
        completed=task.completed,
        streak_bound=task.streak_bound,
        completed_at=task.completed_at,
        user_id=uid,
        created_at=datetime.now(),
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

@router.put("/{task_id}", response_model=TaskRead)
def update_task(task_id: int, updated_task: TaskUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    uid = _coerce_user_id(current_user)
    task = db.query(TaskModel).filter(TaskModel.id == task_id, TaskModel.user_id == uid).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    update_data = updated_task.model_dump(exclude_unset=True)
    if "priority" in update_data:
        update_data["priority"] = _priority_to_db(update_data["priority"])

    # Update fields and auto-set completed_at
    for key, value in update_data.items():
        setattr(task, key, value)
    if task.completed and not task.completed_at:
        task.completed_at = datetime.now()

    db.commit()
    db.refresh(task)
    return task