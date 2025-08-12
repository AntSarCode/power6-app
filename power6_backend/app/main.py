from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
import os

from app.routes import api_router, stripe
from app.database import Base, engine

# App metadata from .env
APP_NAME = os.getenv("APP_NAME", "Power6 API")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development").lower()
ALLOWED_ORIGINS_ENV = os.getenv("ALLOWED_ORIGINS", "*")

app = FastAPI(
    title=APP_NAME,
    description="Backend for the Power6 productivity app",
    version="1.0.0",
)

# Recreate database schema
Base.metadata.create_all(bind=engine)

# Build CORS allowlist based on ENVIRONMENT and ALLOWED_ORIGINS
raw_origins = [o.strip() for o in ALLOWED_ORIGINS_ENV.split(",") if o.strip()]

if ENVIRONMENT == "development":
    # In dev, allow '*' unless specific origins are provided
    allow_origins = raw_origins if raw_origins and raw_origins != ["*"] else ["*"]
else:
    # In production, require explicit origins; default to the primary domain if none supplied
    allow_origins = raw_origins or ["https://power6.app"]

app.add_middleware(
    CORSMiddleware,  # type: ignore
    allow_origins=allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Routers
app.include_router(api_router)
app.include_router(stripe.router, prefix="/stripe")  # Registered stripe routes

@app.get("/")
def read_root():
    return {"msg": f"Welcome to the {APP_NAME}"}

@app.get("/favicon.ico", include_in_schema=False)
def favicon():
    return FileResponse("static/favicon.ico")
