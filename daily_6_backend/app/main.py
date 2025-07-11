from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import auth, users, badge, tasks, tier_logic

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(badge.router)
app.include_router(tasks.router)
app.include_router(tier_logic.router)

@app.get("/")
def read_root():
    return {"msg": "Welcome to the Daily6 API"}
