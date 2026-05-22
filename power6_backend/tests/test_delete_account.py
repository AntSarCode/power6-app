import os

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_delete_account.sqlite")
os.environ.setdefault("SECRET_KEY", "test-secret")

from fastapi.testclient import TestClient

from app.database import Base, engine
from app.main import build_app
from app.models.badge import Badge, BadgeAssignRequest, UserBadge
from app.models.models import AdminMessage, Subscription, Task, User
from app.routes.auth import create_access_token
from app.utils.hash import get_password_hash


def test_delete_me_removes_related_data_and_nulls_feedback_sender():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    app = build_app()
    client = TestClient(app)

    from app.database import SessionLocal

    db = SessionLocal()
    try:
        user = User(
            username="delete_me",
            email="delete_me@example.com",
            hashed_password=get_password_hash("Password123!"),
            tier="Plus",
        )
        badge = Badge(title="Starter", description="Started", icon_uri=None)
        db.add_all([user, badge])
        db.flush()
        db.add_all(
            [
                Task(title="Task", user_id=user.id),
                Subscription(user_id=user.id, tier="Plus", active=True),
                UserBadge(user_id=user.id, badge_id=badge.id),
                BadgeAssignRequest(user_id=user.id, badge_id=badge.id),
                AdminMessage(subject="Help", body="Please", sender_id=user.id),
            ],
        )
        db.commit()
        user_id = user.id
    finally:
        db.close()

    token = create_access_token({"sub": "delete_me"})
    response = client.delete(
        "/users/me",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json() == {"ok": True, "message": "Account deleted."}

    db = SessionLocal()
    try:
        assert db.query(User).filter(User.id == user_id).first() is None
        assert db.query(Task).filter(Task.user_id == user_id).count() == 0
        assert db.query(Subscription).filter(Subscription.user_id == user_id).count() == 0
        assert db.query(UserBadge).filter(UserBadge.user_id == user_id).count() == 0
        assert db.query(BadgeAssignRequest).filter(BadgeAssignRequest.user_id == user_id).count() == 0
        assert db.query(AdminMessage).first().sender_id is None
    finally:
        db.close()
