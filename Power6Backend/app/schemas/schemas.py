from pydantic import BaseModel
from typing import Literal, Optional
from enum import Enum

class Tier(str, Enum):
    free = "free"
    plus = "plus"
    pro = "pro"
    elite = "elite"
    admin = "admin"

class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None

class TaskCreate(TaskBase):
    pass

class Task(TaskBase):
    id: int
    completed: bool
    created: str

    class Config:
        orm_mode = True

class UserCreate(BaseModel):
    username: str
    email: str
    password: str
    tier: Tier = Tier.free

class UserRead(BaseModel):
    id: int
    username: str
    email: str
    tier: Tier

    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str

class LoginRequest(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    password: str

class UserTierUpdate(BaseModel):
    tier: Tier
