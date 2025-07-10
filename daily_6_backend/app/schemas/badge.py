from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class BadgeBase(BaseModel):
    name: str
    description: str
    icon: str
    unlock_condition: str


class BadgeCreate(BadgeBase):
    pass


class BadgeRead(BadgeBase):
    id: int

    class Config:
        orm_mode = True


class UserBadgeBase(BaseModel):
    user_id: int
    badge_id: int


class UserBadgeCreate(UserBadgeBase):
    pass


class UserBadgeRead(UserBadgeBase):
    id: int
    unlocked_at: datetime
    badge: Optional[BadgeRead] = None

    class Config:
        orm_mode = True

class BadgeUpdate(BaseModel):
    name: Optional[str]
    description: Optional[str]
    icon: Optional[str]
    unlock_condition: Optional[str]


class UserBadgeUpdate(BaseModel):
    unlocked_at: Optional[datetime]
    badge_id: Optional[int]

class BadgeAssignResult(BaseModel):
    new_badges: list[UserBadgeRead] = []
    message: str = "Badges evaluated and assigned successfully."

    class Config:
        orm_mode = True