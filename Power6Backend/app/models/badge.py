from sqlalchemy import Column, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from Power6Backend.app.database import Base

class Badge(Base):
    __tablename__ = "badges"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    icon_uri = Column(String, nullable=True)
    achieved = Column(Boolean, default=False)

    user_badges = relationship("UserBadge", back_populates="badge", cascade="all, delete-orphan")


class UserBadge(Base):
    __tablename__ = "user_badges"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    badge_id = Column(Integer, ForeignKey("badges.id", ondelete="CASCADE"), nullable=False)

    user = relationship("User", back_populates="user_badges")
    badge = relationship("Badge", back_populates="user_badges")
