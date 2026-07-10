import os
from datetime import datetime, timedelta, timezone

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_task_analytics_export.sqlite")
os.environ.setdefault("SECRET_KEY", "test-secret")

from fastapi.testclient import TestClient

from app.database import Base, engine
from app.main import build_app
from app.models.models import Task, User
from app.routes.auth import create_access_token
from app.utils.hash import get_password_hash


def _seed_user_with_tasks(tier: str = "pro") -> str:
    from app.database import SessionLocal

    db = SessionLocal()
    try:
        user = User(
            username=f"{tier}_analytics_user",
            email=f"{tier}_analytics_user@example.com",
            hashed_password=get_password_hash("Password123!"),
            tier=tier,
        )
        db.add(user)
        db.flush()

        now = datetime.now(timezone.utc)
        db.add_all(
            [
                Task(
                    user_id=user.id,
                    title="Close priority proposal",
                    notes="For Monday pipeline",
                    priority=2,
                    completed=True,
                    streak_bound=True,
                    created_at=now - timedelta(days=1, hours=2),
                    completed_at=now - timedelta(days=1),
                ),
                Task(
                    user_id=user.id,
                    title="Inbox zero",
                    priority=1,
                    completed=True,
                    streak_bound=False,
                    created_at=now - timedelta(days=1, hours=1),
                    completed_at=now - timedelta(days=1, minutes=20),
                ),
            ]
        )
        db.commit()
        return user.username
    finally:
        db.close()


def test_pro_task_analytics_returns_summary():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    app = build_app()
    client = TestClient(app)
    username = _seed_user_with_tasks("pro")
    token = create_access_token({"sub": username})

    response = client.get(
        "/tasks/analytics",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["completed_tasks"] == 2
    assert data["streak_bound_completed"] == 1
    assert data["completion_rate"] > 0
    assert data["best_day"]["completed"] == 2


def test_task_csv_export_requires_pro_and_returns_rows():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    app = build_app()
    client = TestClient(app)
    username = _seed_user_with_tasks("pro")
    token = create_access_token({"sub": username})

    response = client.get(
        "/tasks/export.csv",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/csv")
    assert "title,notes,priority" in response.text
    assert "Close priority proposal" in response.text


def test_task_analytics_blocks_free_users():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    app = build_app()
    client = TestClient(app)
    username = _seed_user_with_tasks("free")
    token = create_access_token({"sub": username})

    response = client.get(
        "/tasks/analytics",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403
