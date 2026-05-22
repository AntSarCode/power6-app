from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.badge import BadgeAssignRequest, UserBadge
from app.models.models import AdminMessage, Subscription, Task, User
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
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tier updates require administrator privileges.",
        )

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


@router.delete(
    "/me",
    status_code=status.HTTP_200_OK,
    summary="Delete the current user's account and related data",
)
def delete_me(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user_id = current_user.id

    try:
        db.query(AdminMessage).filter(AdminMessage.sender_id == user_id).update(
            {AdminMessage.sender_id: None},
            synchronize_session=False,
        )
        db.query(BadgeAssignRequest).filter(
            BadgeAssignRequest.user_id == user_id,
        ).delete(synchronize_session=False)
        db.query(UserBadge).filter(UserBadge.user_id == user_id).delete(
            synchronize_session=False,
        )
        db.query(Task).filter(Task.user_id == user_id).delete(
            synchronize_session=False,
        )
        db.query(Subscription).filter(Subscription.user_id == user_id).delete(
            synchronize_session=False,
        )
        db.delete(current_user)
        db.commit()
    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Account deletion failed.",
        )

    return {"ok": True, "message": "Account deleted."}
