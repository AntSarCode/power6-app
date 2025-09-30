from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, CheckConstraint, text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, nullable=False, index=True)

    # Store only hashed password
    hashed_password = Column(String, nullable=False)

    email = Column(String, unique=True, nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    is_admin = Column(Boolean, default=False)
    tier = Column(String, default="Free")
    tasks = relationship("Task", back_populates="user", cascade="all, delete-orphan")
    subscriptions = relationship("Subscription", back_populates="user", cascade="all, delete")
    user_badges = relationship("UserBadge", back_populates="user", cascade="all, delete-orphan")

class Task(Base):
    __tablename__ = "tasks"

    __table_args__ = (
        CheckConstraint("priority IN (0,1,2)", name="ck_tasks_priority_range"),
    )

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    notes = Column(String)
    priority = Column(Integer, nullable=False, server_default="1")
    scheduled_for = Column(DateTime(timezone=True))
    completed = Column(Boolean, nullable=False, server_default=text("false"))
    streak_bound = Column(Boolean, nullable=False, server_default=text("false"))
    completed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    user = relationship("User", back_populates="tasks")

class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    tier = Column(String, nullable=False)
    active = Column(Boolean, default=True)
    started_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    user = relationship("User", back_populates="subscriptions")

