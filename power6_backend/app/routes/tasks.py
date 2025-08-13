from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import date

from app.models.models import Task as TaskModel
from app.models.models import User
from app.database import get_db
from app.routes.auth import get_current_user
from app.schemas import TaskCreate, TaskRead

router = APIRouter(
    prefix="/tasks",
    tags=["Tasks"]
)

@router.post("/upload", status_code=status.HTTP_201_CREATED)
def upload_tasks(
    tasks: List[TaskCreate],
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    today = date.today().isoformat()

    db.query(TaskModel).filter(
        TaskModel.user_id == current_user.id,
        TaskModel.created_at == today
    ).delete(synchronize_session=False)

    for task in tasks:
        db_task = TaskModel(
            title=task.title,
            notes=task.notes,
            priority=task.priority,
            scheduled_for=task.scheduled_for,
            completed=task.completed,
            streak_bound=task.streak_bound,
            completed_at=task.completed_at,
            user_id=current_user.id,
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
    today = date.today().isoformat()
    return db.query(TaskModel).filter(TaskModel.user_id == current_user.id, TaskModel.created_at == today).all()


@router.post("/", response_model=TaskRead, status_code=status.HTTP_201_CREATED)
def create_task(
    task: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_task = TaskModel(
        title=task.title,
        notes=task.notes,
        priority=task.priority,
        scheduled_for=task.scheduled_for,
        completed=task.completed,
        streak_bound=task.streak_bound,
        completed_at=task.completed_at,
        user_id=current_user.id,
        created_at=date.today().isoformat()
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
    return (
        db.query(TaskModel)
        .filter(TaskModel.user_id == current_user.id)
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
    task = db.query(TaskModel).filter(TaskModel.id == task_id, TaskModel.user_id == current_user.id).first()
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@router.put("/{task_id}", response_model=TaskRead, status_code=status.HTTP_200_OK)
def update_task(
    task_id: int,
    updated_task: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    task = db.query(TaskModel).filter(TaskModel.id == task_id, TaskModel.user_id == current_user.id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    for key, value in updated_task.model_dump().items():
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
    task = db.query(TaskModel).filter(TaskModel.id == task_id, TaskModel.user_id == current_user.id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    db.delete(task)
    db.commit()
