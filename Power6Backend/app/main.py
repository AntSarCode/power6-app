from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from Power6Backend.app.routes import (
    auth_router,
    users_router,
    badge_router,
    tasks_router,
    tier_logic_router
)

from Power6Backend.app.models.models import User, Task, Subscription
from Power6Backend.app.models.badge import Badge, UserBadge

_ = [User, Task, Subscription, Badge, UserBadge]  # ensures models are evaluated


from Power6Backend.app.database import Base, engine
Base.metadata.create_all(bind=engine)


app = FastAPI(
    title="Power6 API",
    description="Backend for the Power6 productivity app",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,  # type: ignore
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.mount("/static", StaticFiles(directory="static"), name="static")

# Include API routers
app.include_router(auth_router)
app.include_router(users_router)
app.include_router(badge_router)
app.include_router(tasks_router)
app.include_router(tier_logic_router)

@app.get("/")
def read_root():
    return {"msg": "Welcome to the Power6 API"}

@app.get("/favicon.ico", include_in_schema=False)
def favicon():
    return FileResponse("static/favicon.ico")
