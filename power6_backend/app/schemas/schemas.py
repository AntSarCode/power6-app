from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional, Union

from pydantic import BaseModel, EmailStr, Field, AliasChoices, field_validator

# ---------------------------------
# Helper: UTC + Priority Normalizer
# ---------------------------------

def _now_utc() -> datetime:
    return datetime.now(timezone.utc)

_PRIORITY_LABEL_TO_INT = {"low": 0, "normal": 1, "high": 2}


def _priority_to_int(v: Union[str, int, None], default: int = 1) -> int:
    if v is None:
        return default
    if isinstance(v, int):
        return v if v in (0, 1, 2) else default
    if isinstance(v, str):
        key = v.strip().lower()
        return _PRIORITY_LABEL_TO_INT.get(key, default)
    return default


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
    username_or_email: str = Field(
        validation_alias=AliasChoices("username_or_email", "username", "email")
    )
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TaskBase(BaseModel):
    title: str
    notes: Optional[str] = None
    # Accept str or int inbound, but store as int (0/1/2). Default Normal=1
    priority: int = 1
    scheduled_for: Optional[datetime] = None
    streak_bound: bool = True

    @field_validator("priority", mode="before")
    @classmethod
    def _coerce_priority(cls, v):
        return _priority_to_int(v, default=1)


class TaskCreate(TaskBase):
    completed: bool = False
    # These are client-optional; server may set created_at itself
    created_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    reviewed_at: Optional[datetime] = None


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    notes: Optional[str] = None
    priority: Optional[Union[str, int]] = None
    scheduled_for: Optional[datetime] = None
    completed: Optional[bool] = None
    created_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    reviewed_at: Optional[datetime] = None
    streak_bound: Optional[bool] = None

    @field_validator("priority", mode="before")
    @classmethod
    def _coerce_priority(cls, v):
        if v is None:
            return v
        return _priority_to_int(v, default=1)


class TaskRead(TaskBase):
    id: int
    user_id: int
    completed: bool = False
    created_at: datetime
    completed_at: Optional[datetime] = None
    reviewed_at: Optional[datetime] = None
    # Computed server-side; useful for daily grouping in UI
    day_key: Optional[str] = None

    model_config = {"from_attributes": True}
