from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.models import models
from app.schemas import schemas
from app.database import SessionLocal

router = APIRouter(prefix="/users", tags=["Users"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_user_by_username(username: str, db: Session) -> models.User:
    user = db.query(models.User).filter(models.User.username == username).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user

@router.get("/{username}", response_model=schemas.UserRead)
def get_user(username: str, db: Session = Depends(get_db)):
    return get_user_by_username(username, db)

@router.post("/", response_model=schemas.UserRead, status_code=status.HTTP_201_CREATED)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = models.User(**user.dict())
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
