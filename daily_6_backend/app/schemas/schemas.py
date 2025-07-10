from pydantic import BaseModel, EmailStr
from typing import Literal, Optional
from enum import Enum

class Tier(str, Enum):
    free = "free"
    premium = "premium"
    admin = "admin"

class TaskBase(BaseModel):
    title: str
    description: str | None = None

class TaskCreate(TaskBase):
    pass

class Task(TaskBase):
    id: int
    class Config:
        orm_mode = True

class UserCreate(BaseModel):
    username: str
    password: str
    tier: Tier = Tier.free

class UserRead(BaseModel):
    id: int
    username: str
    tier: Tier

    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

class UserTierUpdate(BaseModel):
    tier: Tier