import os

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_review_login.sqlite")
os.environ.setdefault("SECRET_KEY", "test-secret")

from fastapi.testclient import TestClient

from app.database import Base, engine
from app.main import build_app
from app.models.models import Subscription, User
from app.utils.hash import get_password_hash


def test_review_login_creates_full_access_expired_account():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    app = build_app()
    client = TestClient(app)

    response = client.post(
        "/auth/login",
        json={
            "username_or_email": "app_review_expired",
            "password": "Power6Review!2026",
        },
    )

    assert response.status_code == 200
    assert response.json()["access_token"]

    from app.database import SessionLocal

    db = SessionLocal()
    try:
        user = db.query(User).filter(User.username == "app_review_expired").one()
        assert user.email == "app-review@power6.app"
        assert user.tier == "Elite"
        subscriptions = db.query(Subscription).filter(
            Subscription.user_id == user.id,
        ).all()
        assert len(subscriptions) == 1
        assert subscriptions[0].tier == "Expired"
        assert subscriptions[0].active is False
    finally:
        db.close()


def test_review_login_repairs_stale_password_and_tier():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    from app.database import SessionLocal

    db = SessionLocal()
    try:
        db.add(
            User(
                username="app_review_expired",
                email="app-review@power6.app",
                hashed_password=get_password_hash("old-password"),
                tier="Free",
                is_admin=True,
            ),
        )
        db.commit()
    finally:
        db.close()

    app = build_app()
    client = TestClient(app)

    response = client.post(
        "/auth/login",
        json={
            "username_or_email": "app_review_expired",
            "password": "Power6Review!2026",
        },
    )

    assert response.status_code == 200

    db = SessionLocal()
    try:
        user = db.query(User).filter(User.username == "app_review_expired").one()
        assert user.tier == "Elite"
        assert user.is_admin is False
    finally:
        db.close()
