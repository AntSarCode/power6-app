from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.schemas.badge import UserBadgeRead, BadgeAssignResult
from app.services import badge_service
from app.routes.auth import get_current_user
from app.models.models import User

router = APIRouter(
    prefix="/badges",
    tags=["Badges"]
)

@router.get("/me", response_model=List[UserBadgeRead], status_code=status.HTTP_200_OK)
def get_my_badges(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Return all badges (achieved + locked) for the current user.
    """
    return badge_service.get_user_badges(db, current_user.id)


@router.post("/evaluate", response_model=BadgeAssignResult, status_code=status.HTTP_200_OK)
def evaluate_badges(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Evaluate user progress and assign any newly earned badges.
    """
    new_badges = badge_service.evaluate_and_assign_badges(db, current_user.id)
    return BadgeAssignResult(new_badges=new_badges)
