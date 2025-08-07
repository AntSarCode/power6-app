from fastapi import APIRouter, Depends, HTTPException, status
from typing import Literal, Callable

from app.routes.auth import get_current_user
from app.models.models import User

router = APIRouter(
    prefix="/features",
    tags=["TierAccess"]
)

TierLevel = Literal["free", "plus", "pro", "elite", "admin"]

# Define priority order for tier levels
TIER_PRIORITY = {
    "free": 1,
    "plus": 2,
    "pro": 3,
    "elite": 4,
    "admin": 5
}

def require_tier(required: TierLevel) -> Callable:
    def tier_guard(current_user: User = Depends(get_current_user)):
        user_tier = current_user.tier
        user_level = TIER_PRIORITY.get(user_tier, 0)
        required_level = TIER_PRIORITY[required]

        if user_level < required_level:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    f"Access denied: '{user_tier}' tier insufficient for '{required}'-level content."
                ),
            )
        return current_user
    return tier_guard

@router.get("/advanced-report", status_code=status.HTTP_200_OK)
def advanced_feature(current_user: User = Depends(require_tier("pro"))):
    """
    Access only for users with Pro tier or higher.
    """
    return {"msg": f"Welcome, {current_user.username}. You have access to advanced reports."}


@router.get("/elite-dashboard", status_code=status.HTTP_200_OK)
def elite_feature(current_user: User = Depends(require_tier("elite"))):
    """
    Access only for users with Elite tier.
    """
    return {"msg": f"Hello {current_user.username}, enjoy your Elite Dashboard!"}
