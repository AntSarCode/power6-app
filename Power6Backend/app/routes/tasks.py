from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import date

from Power6Backend.app.models.models import Task as TaskModel, User
from Power6Backend.app.database import get_db
from Power6Backend.app.routes.auth import get_current_user
from Power6Backend.app.schemas.schemas import TaskCreate, Task

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
        TaskModel.created == today
    ).delete(synchronize_session=False)

    for task in tasks:
        db_task = TaskModel(**task.model_dump(), user_id=current_user.id, created=today)
        db.add(db_task)
    db.commit()

    return {"status": "success", "count": len(tasks)}


@router.get("/today", response_model=List[Task], status_code=status.HTTP_200_OK)
def get_today_tasks(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    today = date.today().isoformat()
    return db.query(TaskModel).filter(TaskModel.user_id == current_user.id, TaskModel.created == today).all()


@router.post("/", response_model=Task, status_code=status.HTTP_201_CREATED)
def create_task(
    task: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_task = TaskModel(**task.model_dump(), user_id=current_user.id)
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task


@router.get("/", response_model=List[Task], status_code=status.HTTP_200_OK)
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


@router.get("/{task_id}", response_model=Task, status_code=status.HTTP_200_OK)
def read_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    task = db.query(TaskModel).filter(TaskModel.id == task_id, TaskModel.user_id == current_user.id).first()
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@router.put("/{task_id}", response_model=Task, status_code=status.HTTP_200_OK)
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
