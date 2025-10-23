from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
    ForeignKey,
    Boolean,
    CheckConstraint,
    text,
    Index,
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

# NOTE: We prefer database-side timestamps (func.now()) so values are timezone-aware
# and consistent with the DB server. Avoid datetime.utcnow() defaults here.


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, nullable=False, index=True)

    # Store only hashed password
    hashed_password = Column(String, nullable=False)

    email = Column(String, unique=True, nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    is_admin = Column(Boolean, nullable=False, server_default=text("false"))
    tier = Column(String, nullable=False, server_default="Free")

    tasks = relationship("Task", back_populates="user", cascade="all, delete-orphan")
    subscriptions = relationship("Subscription", back_populates="user", cascade="all, delete")
    user_badges = relationship("UserBadge", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<User id={self.id} username={self.username!r}>"


class Task(Base):
    __tablename__ = "tasks"

    __table_args__ = (
        CheckConstraint("priority IN (0,1,2)", name="ck_tasks_priority_range"),
        # Helpful composite indexes for common filters/queries
        Index("ix_tasks_user_completed", "user_id", "completed"),
        Index("ix_tasks_user_streak", "user_id", "streak_bound", "completed"),
        Index("ix_tasks_user_completed_at", "user_id", "completed_at"),
        Index("ix_tasks_scheduled_for", "scheduled_for"),
    )

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    notes = Column(String)
    priority = Column(Integer, nullable=False, server_default="1")

    # Scheduling and completion fields
    scheduled_for = Column(DateTime(timezone=True))
    completed = Column(Boolean, nullable=False, server_default=text("false"))
    streak_bound = Column(Boolean, nullable=False, server_default=text("false"))
    completed_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    user = relationship("User", back_populates="tasks")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<Task id={self.id} title={self.title!r} user_id={self.user_id}>"


class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    tier = Column(String, nullable=False)
    active = Column(Boolean, nullable=False, server_default=text("true"))
    started_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    user = relationship("User", back_populates="subscriptions")

    def __repr__(self) -> str:  # pragma: no cover
        return f"<Subscription id={self.id} tier={self.tier!r} active={self.active}>"


# If you have badge models referenced elsewhere, ensure they remain defined in their files
# or add them here consistently with relationships to User as needed.