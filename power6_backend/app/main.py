from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
import os

from app.routes import api_router, stripe
from app.database import Base, engine

app = FastAPI(
    title="Power6 API",
    description="Backend for the Power6 productivity app",
    version="1.0.0"
)

# Recreate database schema
Base.metadata.create_all(bind=engine)

# Allow CORS based on environment variable or default to dev mode
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")

if ENVIRONMENT == "development" and ALLOWED_ORIGINS == ["*"]:
    allow_origins = ["*"]
else:
    allow_origins = [origin.strip() for origin in ALLOWED_ORIGINS if origin.strip()]

app.add_middleware(
    CORSMiddleware,  # type: ignore
    allow_origins=allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="static"), name="static")

app.include_router(api_router)
app.include_router(stripe.router, prefix="/stripe")  # Registered stripe routes

@app.get("/")
def read_root():
    return {"msg": "Welcome to the Power6 API"}

@app.get("/favicon.ico", include_in_schema=False)
def favicon():
    return FileResponse("static/favicon.ico")
