from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import date, timedelta

from app.models import models, User  # Removed direct Task import
from app.routes.auth import get_current_user, get_password_hash
from app.schemas import schemas
from app.database import get_db

router = APIRouter(prefix="/users", tags=["Users"])

def get_user_by_username(username: str, db: Session) -> models.User:
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user

@router.get("/streak")
def get_streak(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Calculate the user's current task streak based on streak-bound tasks.
    """
    # Step 1: Query all completed streak-bound tasks
    tasks = (
        db.query(models.Task)
        .filter(
            models.Task.user_id == current_user.id,
            models.Task.streak_bound == True,
            models.Task.completed == True,
        )
        .order_by(models.Task.scheduled_for.desc())  # Most recent first
        .all()
    )

    if not tasks:
        return {"streak": 0}

    # Step 2: Create a set of all completed dates
    completed_dates = set(task.scheduled_for.date() for task in tasks if task.scheduled_for)

    # Step 3: Count consecutive days from today
    streak = 0
    current_day = date.today()

    while current_day in completed_dates:
        streak += 1
        current_day -= timedelta(days=1)

    return {"streak": streak}

@router.get("/{username}", response_model=schemas.UserRead, status_code=status.HTTP_200_OK)
def get_user(username: str, db: Session = Depends(get_db)):
    return get_user_by_username(username, db)

@router.post("/", response_model=schemas.UserRead, status_code=status.HTTP_201_CREATED)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    if db.query(models.User).filter(models.User.username == user.username).first():
        raise HTTPException(status_code=400, detail="Username already exists")
    if db.query(models.User).filter(models.User.email == user.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        username=user.username,
        email=user.email,
        hashed_password=hashed_password,
        tier=user.tier
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.put("/{username}/tier", status_code=status.HTTP_200_OK)
def update_user_tier(username: str, payload: schemas.UserTierUpdate, db: Session = Depends(get_db)):
    user = get_user_by_username(username, db)
    user.tier = payload.tier
    db.commit()
    return {"message": f"Tier updated to '{payload.tier}' for user '{username}'"}
