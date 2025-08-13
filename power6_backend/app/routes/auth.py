from fastapi import APIRouter, HTTPException, Depends, status, Request
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from sqlalchemy import func, or_
from jose import JWTError, jwt
from datetime import datetime, timedelta, timezone
from typing import Optional
import os

from app.models.models import User
from app.schemas import (
    UserCreate,
    UserRead,
    Token,
    LoginRequest,
)
from app.database import get_db
from app.utils.hash import get_password_hash, verify_password

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"],
)

SECRET_KEY = os.getenv("SECRET_KEY", "fallback_dev_secret")
REFRESH_SECRET_KEY = os.getenv("REFRESH_SECRET_KEY", "fallback_refresh_secret")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
REFRESH_TOKEN_EXPIRE_DAYS = 7

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def create_refresh_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, REFRESH_SECRET_KEY, algorithm=ALGORITHM)

def get_user_by_identifier(db: Session, identifier: str) -> Optional[User]:
    ident = identifier.strip().lower()
    return (
        db.query(User)
        .filter(
            or_(
                func.lower(User.username) == ident,
                func.lower(User.email) == ident,
            )
        )
        .first()
    )

def authenticate_user(db: Session, identifier: str, password: str) -> Optional[User]:
    user = get_user_by_identifier(db, identifier)
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user

@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    username_norm = user_data.username.strip()
    email_norm = user_data.email.strip().lower()

    if db.query(User).filter(func.lower(User.username) == username_norm.lower()).first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already registered")
    if db.query(User).filter(func.lower(User.email) == email_norm).first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")

    hashed_password = get_password_hash(user_data.password)
    new_user = User(
        username=username_norm,
        email=email_norm,
        hashed_password=hashed_password,
        tier="Free",
        is_admin=False,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    access_token = create_access_token(data={"sub": new_user.username})
    refresh_token_value = create_refresh_token(data={"sub": new_user.username})
    return {"access_token": access_token, "refresh_token": refresh_token_value, "token_type": "bearer"}

@router.post("/login", response_model=Token)
def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    identifier = login_data.username_or_email.strip().lower()
    user = authenticate_user(db, identifier, login_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username/email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(data={"sub": user.username}, expires_delta=access_token_expires)
    refresh_token_value = create_refresh_token(data={"sub": user.username})
    return {"access_token": access_token, "refresh_token": refresh_token_value, "token_type": "bearer"}

@router.post("/refresh", response_model=Token)
def refresh_token(request: Request, db: Session = Depends(get_db)):
    token = request.headers.get("Authorization")
    if not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token missing")
    try:
        token = token.replace("Bearer ", "")
        payload = jwt.decode(token, REFRESH_SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if not username:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    if not get_user_by_identifier(db, username):
        raise HTTPException(status_code=404, detail="User not found")

    new_access_token = create_access_token(data={"sub": username})
    return {
        "access_token": new_access_token,
        "refresh_token": token,
        "token_type": "bearer"
    }

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if not username:
            raise HTTPException(status_code=401, detail="Invalid token payload")
        user = get_user_by_identifier(db, username)
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        return user
    except JWTError:
        raise HTTPException(status_code=403, detail="Token is invalid or expired")

@router.get("/me", response_model=UserRead)
def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user
