from fastapi import APIRouter

api_router = APIRouter()

def include_all_routes():
    from .auth import router as auth_router
    from .badge import router as badge_router
    from .tasks import router as tasks_router
    from .tier_logic import router as tier_logic_router
    from .users import router as users_router

    api_router.include_router(auth_router)
    api_router.include_router(badge_router)
    api_router.include_router(tasks_router)
    api_router.include_router(tier_logic_router)
    api_router.include_router(users_router)

include_all_routes()
