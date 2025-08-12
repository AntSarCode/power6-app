from __future__ import annotations
from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field, AliasChoices, field_validator, EmailStr

class Tier(str, Enum):
    Free = "Free"
    Pro = "Pro"
    Elite = "Elite"

class LoginRequest(BaseModel):
    """Accept multiple keys for identifier (username/email)."""
    username_or_email: str = Field(
        ..., validation_alias=AliasChoices("username_or_email", "username", "email", "identifier")
    )
    password: str

    model_config = {"from_attributes": True, "populate_by_name": True}

    @field_validator("username_or_email", "password", mode="before")
    def _strip(cls, v):
        return v.strip() if isinstance(v, str) else v

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    refresh_token: Optional[str] = None

class UserCreate(BaseModel):
    username: str
    email: EmailStr
    password: str

    model_config = {"from_attributes": True}

    @field_validator("username", "email", "password", mode="before")
    def _strip_usercreate(cls, v):
        return v.strip() if isinstance(v, str) else v

class UserRead(BaseModel):
    id: int
    username: str
    email: EmailStr
    tier: Tier = Tier.Free
    is_admin: bool = False
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

class UserTierUpdate(BaseModel):
    tier: Tier