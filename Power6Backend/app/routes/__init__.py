from .auth import router as auth_router
from .badge import router as badge_router
from .tasks import router as tasks_router
from .tier_logic import router as tier_logic_router
from .users import router as users_router

__all__ = [
    "auth_router",
    "badge_router",
    "tasks_router",
    "tier_logic_router",
    "users_router"
]
