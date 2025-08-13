from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


# -----------------------------
# Badge Schemas (Pydantic v2)
# -----------------------------

class BadgeBase(BaseModel):
    name: str
    description: str
    icon_uri: str
    unlock_condition: str


class BadgeCreate(BadgeBase):
    pass


class BadgeRead(BadgeBase):
    id: int

    # Pydantic v2 replacement for orm_mode=True
    model_config = {"from_attributes": True}


class BadgeUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    icon_uri: Optional[str] = None
    unlock_condition: Optional[str] = None


class UserBadgeBase(BaseModel):
    user_id: int
    badge_id: int


class UserBadgeCreate(UserBadgeBase):
    pass


class UserBadgeRead(UserBadgeBase):
    id: int
    unlocked_at: datetime
    badge: Optional[BadgeRead] = None

    model_config = {"from_attributes": True}


class UserBadgeUpdate(BaseModel):
    unlocked_at: Optional[datetime] = None
    badge_id: Optional[int] = None


class BadgeAssignRequest(BaseModel):
    user_id: int
    badge_id: int
    note: Optional[str] = None


class BadgeAssignResult(BaseModel):
    new_badges: list[UserBadgeRead] = Field(default_factory=list)
    message: str = "Badges evaluated and assigned successfully."

    model_config = {"from_attributes": True}
