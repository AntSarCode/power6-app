from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from Power6Backend.app.models import models
from Power6Backend.app.schemas import schemas
from Power6Backend.app.database import get_db
from Power6Backend.app.routes.auth import get_password_hash

router = APIRouter(prefix="/users", tags=["Users"])

def get_user_by_username(username: str, db: Session) -> models.User:
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user

@router.get("/{username}", response_model=schemas.UserRead, status_code=status.HTTP_200_OK)
def get_user(username: str, db: Session = Depends(get_db)):
    return get_user_by_username(username, db)

@router.post("/", response_model=schemas.UserRead, status_code=status.HTTP_201_CREATED)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    if db.query(models.User).filter(models.User.username == user.username).first():
        raise HTTPException(status_code=400, detail="Username already exists")
    if db.query(models.User).filter(models.User.email == user.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        username=user.username,
        email=user.email,
        hashed_password=hashed_password,
        tier=user.tier
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@router.put("/{username}/tier", status_code=status.HTTP_200_OK)
def update_user_tier(username: str, payload: schemas.UserTierUpdate, db: Session = Depends(get_db)):
    user = get_user_by_username(username, db)
    user.tier = payload.tier
    db.commit()
    return {"message": f"Tier updated to '{payload.tier}' for user '{username}'"}
