# Package export hub for app.schemas
# Prefer: from app.schemas import <Name>

from .schemas import (
    UserCreate,
    UserRead,
    UserTierUpdate,
    LoginRequest,
    Token,
    TaskBase,
    TaskCreate,
    TaskUpdate,
    TaskRead,
)

try:
    from .badge import (
        BadgeCreate,
        BadgeRead,
        UserBadgeCreate,
        UserBadgeRead,
        UserBadgeUpdate,
        BadgeAssignRequest,
        BadgeAssignResult,
    )
    _BADGE_EXPORTS = [
        "BadgeCreate",
        "BadgeRead",
        "UserBadgeCreate",
        "UserBadgeRead",
        "UserBadgeUpdate",
        "BadgeAssignRequest",
        "BadgeAssignResult",
    ]
except (ImportError, ModuleNotFoundError):
    _BADGE_EXPORTS = []

__all__ = [
    "UserCreate",
    "UserRead",
    "UserTierUpdate",
    "LoginRequest",
    "Token",
    "TaskBase",
    "TaskCreate",
    "TaskUpdate",
    "TaskRead",
    *_BADGE_EXPORTS,
]
