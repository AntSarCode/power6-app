from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, field_validator

# -----------------------------
# User Schemas
# -----------------------------

class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str

    # normalize & trim inputs
    @field_validator("username")
    @classmethod
    def normalize_username(cls, v: str) -> str:
        return v.strip()

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: EmailStr) -> EmailStr:
        # EmailStr already validates; ensure lowercase + trim
        return EmailStr(str(v).strip().lower())

class UserRead(BaseModel):
    id: int
    username: str
    email: EmailStr
    tier: str
    is_admin: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    # Pydantic v2 replacement for orm_mode=True
    model_config = {"from_attributes": True}

class UserTierUpdate(BaseModel):
    tier: str

class LoginRequest(BaseModel):
    username_or_email: str
    password: str

    @field_validator("username_or_email")
    @classmethod
    def normalize_login_key(cls, v: str) -> str:
        return v.strip().lower()

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


# -----------------------------
# Task Schemas
# -----------------------------

class TaskBase(BaseModel):
    title: str
    notes: Optional[str] = None
    priority: int = 0
    scheduled_for: datetime
    streak_bound: bool = False

    @field_validator("title")
    @classmethod
    def title_not_empty(cls, v: str) -> str:
        v2 = v.strip()
        if not v2:
            raise ValueError("title cannot be empty")
        return v2

class TaskCreate(TaskBase):
    pass

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    notes: Optional[str] = None
    priority: Optional[int] = None
    scheduled_for: Optional[datetime] = None
    completed: Optional[bool] = None
    completed_at: Optional[datetime] = None
    streak_bound: Optional[bool] = None

class TaskRead(TaskBase):
    id: int
    user_id: int
    completed: bool = False
    completed_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
