from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum

class Tier(str, Enum):
    free = "free"
    plus = "plus"
    pro = "pro"
    elite = "elite"
    admin = "admin"

class TaskBase(BaseModel):
    title: str
    notes: Optional[str] = None
    priority: int
    scheduled_for: datetime
    completed: bool = False
    streak_bound: bool = False
    completed_at: Optional[datetime] = None

class TaskCreate(TaskBase):
    pass

class TaskUpdate(TaskBase):
    pass

class TaskRead(TaskBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        orm_mode = True
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class UserCreate(BaseModel):
    username: str
    email: str
    password: str
    tier: Tier = Tier.free

class UserRead(BaseModel):
    id: int
    username: str
    email: str
    is_admin: bool
    created_at: datetime
    updated_at: datetime
    tier: Tier  # <- Prefer using Enum instead of str

    class Config:
        orm_mode = True
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str
    user: str

class LoginRequest(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    password: str

class UserTierUpdate(BaseModel):
    tier: Tier
