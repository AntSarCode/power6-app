from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import User
from app.routes.auth import get_current_user
from app.schemas import UserRead, UserTierUpdate  # Pydantic v2

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserRead, summary="Get the current user's profile")
def get_me(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return UserRead.model_validate(current_user)


@router.patch(
    "/me/tier",
    response_model=UserRead,
    summary="Update the current user's subscription tier",
)
def update_my_tier(
    payload: UserTierUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    new_tier = payload.tier.strip().lower()
    if not new_tier:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Tier value is required.",
        )
    current_user.tier = new_tier

    db.add(current_user)
    db.commit()
    db.refresh(current_user)

    return UserRead.model_validate(current_user)
