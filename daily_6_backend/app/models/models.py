from sqlalchemy import Column, Integer, String, Text, DateTime, Enum, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
import enum

from app.database import Base

class TaskStatus(str, enum.Enum):
    pending = "pending"
    in_progress = "in_progress"
    completed = "completed"

class UserTier(str, enum.Enum):
    free = "free"
    premium = "premium"

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)

    # Rename & align with frontend
    text = Column(String, nullable=False)
    rank = Column(Integer, nullable=False)
    completed = Column(Integer, default=0)  # 0 = False, 1 = True

    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    user = relationship("User", back_populates="tasks")

    created = Column(String, nullable=False)  # store date string like '2025-07-11'


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    password = Column(Text, nullable=False)  # Store hashed password
    tier = Column(Enum(UserTier), default=UserTier.free)

    tasks = relationship("Task", back_populates="user")

    created_at = Column(DateTime, default=datetime.utcnow)
