from __future__ import annotations

from datetime import datetime
from typing import Optional, Union

from pydantic import BaseModel, EmailStr, Field, AliasChoices, field_validator

# -----------------------------
# User Schemas (Pydantic v2)
# -----------------------------

class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str

class UserRead(BaseModel):
    id: int
    username: str
    email: EmailStr
    tier: Optional[str] = None
    is_admin: bool = False
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}

class UserTierUpdate(BaseModel):
    tier: str

class LoginRequest(BaseModel):
    username_or_email: str = Field(validation_alias=AliasChoices("username_or_email", "username", "email"))
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

# -----------------------------
# Task Schemas
# -----------------------------

class TaskBase(BaseModel):
    title: str
    notes: Optional[str] = None
    # Accept string ("Low"|"Normal"|"High") or int (0,1,2) from older clients
    priority: Union[str, int] = "Normal"
    scheduled_for: Optional[datetime] = None
    streak_bound: bool = False

    @field_validator("priority", mode="before")
    @classmethod
    def normalize_priority(cls, v):
        mapping = {0: "Low", 1: "Normal", 2: "High"}
        if isinstance(v, int):
            return mapping.get(v, "Normal")
        if isinstance(v, str):
            s = v.strip().capitalize()
            if s in ("Low", "Normal", "High"):
                return s
        raise ValueError("Invalid priority; expected 'Low'|'Normal'|'High' or 0|1|2")

class TaskCreate(TaskBase):
    # Ensure backend has the field it expects and default to False
    completed: bool = False
    completed_at: Optional[datetime] = None

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    notes: Optional[str] = None
    priority: Optional[Union[str, int]] = None
    scheduled_for: Optional[datetime] = None
    completed: Optional[bool] = None
    completed_at: Optional[datetime] = None
    streak_bound: Optional[bool] = None

    @field_validator("priority", mode="before")
    @classmethod
    def normalize_priority(cls, v):
        if v is None:
            return v
        mapping = {0: "Low", 1: "Normal", 2: "High"}
        if isinstance(v, int):
            return mapping.get(v, "Normal")
        if isinstance(v, str):
            s = v.strip().capitalize()
            if s in ("Low", "Normal", "High"):
                return s
        raise ValueError("Invalid priority; expected 'Low'|'Normal'|'High' or 0|1|2")

class TaskRead(TaskBase):
    id: int
    user_id: int
    completed: bool = False
    completed_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
