import os

from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.models import Subscription, User
from app.utils.hash import get_password_hash


REVIEW_USERNAME = os.getenv("POWER6_REVIEW_USERNAME", "app_review_expired")
REVIEW_EMAIL = os.getenv("POWER6_REVIEW_EMAIL", "app-review@power6.app")
REVIEW_PASSWORD = os.getenv("POWER6_REVIEW_PASSWORD", "Power6Review!2026")


def seed_review_account() -> None:
    db: Session = SessionLocal()
    try:
        user = db.query(User).filter(User.username == REVIEW_USERNAME).first()
        if user is None:
            user = User(
                username=REVIEW_USERNAME,
                email=REVIEW_EMAIL,
                hashed_password=get_password_hash(REVIEW_PASSWORD),
                is_admin=False,
                tier="Elite",
            )
            db.add(user)
            db.flush()
        else:
            user.email = REVIEW_EMAIL
            user.hashed_password = get_password_hash(REVIEW_PASSWORD)
            user.is_admin = False
            user.tier = "Elite"

        db.query(Subscription).filter(Subscription.user_id == user.id).delete(
            synchronize_session=False,
        )
        db.add(
            Subscription(
                user_id=user.id,
                tier="Expired",
                active=False,
            ),
        )
        db.commit()
        print(f"Review account ready: {REVIEW_USERNAME} / {REVIEW_PASSWORD}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_review_account()
