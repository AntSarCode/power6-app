from fastapi import APIRouter, HTTPException, Depends, status, Request
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta, timezone
from typing import Optional
import os
import traceback

from Power6Backend.app.models.models import User
from Power6Backend.app.schemas.schemas import UserCreate, UserRead, Token, LoginRequest
from Power6Backend.app.database import get_db

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)

# === JWT CONFIG ===
SECRET_KEY = os.getenv("SECRET_KEY", "fallback_dev_secret")
REFRESH_SECRET_KEY = os.getenv("REFRESH_SECRET_KEY", "fallback_refresh_secret")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
REFRESH_TOKEN_EXPIRE_DAYS = 7

# === PASSWORD HASHING ===
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

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

def get_user(db: Session, username: str) -> Optional[User]:
    return db.query(User).filter(User.username == username).first()

def authenticate_user(db: Session, username: str, password: str) -> Optional[User]:
    user = get_user(db, username)
    if not user:
        print("User not found")
        return None
    if not verify_password(password, user.hashed_password):
        print("Password mismatch")
        return None
    return user

@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    try:
        if get_user(db, user_data.username):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already registered")

        hashed_password = get_password_hash(user_data.password)
        new_user = User(username=user_data.username, hashed_password=hashed_password, email=user_data.email)
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        access_token = create_access_token(data={"sub": new_user.username})
        refresh_token_value = create_refresh_token(data={"sub": new_user.username})
        return {
            "access_token": access_token,
            "refresh_token": refresh_token_value,
            "token_type": "bearer"
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/login", response_model=Token)
@router.post("/login", response_model=Token)
def login(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
):
    if login_data.username:
        user = authenticate_user(db, login_data.username, login_data.password)
    elif login_data.email:
        user = db.query(User).filter(User.email == login_data.email).first()
        if not user or not verify_password(login_data.password, user.hashed_password):
            user = None
    else:
        raise HTTPException(status_code=400, detail="Username or email required")

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
def refresh_token(request: Request):
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

    new_access_token = create_access_token(data={"sub": username})
    return {"access_token": new_access_token, "refresh_token": token, "token_type": "bearer"}

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
        if not username or not isinstance(username, str):
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = get_user(db, username)
    if not user:
        raise credentials_exception
    return user

@router.get("/me", response_model=UserRead)
def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user
