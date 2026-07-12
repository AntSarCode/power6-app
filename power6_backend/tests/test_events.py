import os

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_events.sqlite")
os.environ.setdefault("SECRET_KEY", "test-secret")

from fastapi.testclient import TestClient

from app.database import Base, engine
from app.main import build_app
from app.models.models import User, UserEvent
from app.routes.auth import create_access_token
from app.utils.hash import get_password_hash


def _seed_user() -> tuple[str, int]:
    from app.database import SessionLocal

    db = SessionLocal()
    try:
        user = User(
            username="event_user",
            email="event_user@example.com",
            hashed_password=get_password_hash("Password123!"),
            tier="Pro",
        )
        db.add(user)
        db.commit()
        return user.username, user.id
    finally:
        db.close()


def test_create_event_filters_properties_and_sets_tier():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    app = build_app()
    client = TestClient(app)
    username, user_id = _seed_user()
    token = create_access_token({"sub": username})

    response = client.post(
        "/events/",
        headers={"Authorization": f"Bearer {token}", "User-Agent": "Power6Test"},
        json={
            "name": "task_created",
            "source": "mobile",
            "properties": {
                "count": 1,
                "title": "private task text",
                "completed_today": 2,
            },
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["name"] == "task_created"
    assert body["tier"] == "pro"
    assert body["properties"] == {"count": 1, "completed_today": 2}

    from app.database import SessionLocal

    db = SessionLocal()
    try:
        event = db.query(UserEvent).filter(UserEvent.user_id == user_id).one()
        assert event.user_agent == "Power6Test"
    finally:
        db.close()


def test_unknown_event_name_is_normalized():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    app = build_app()
    client = TestClient(app)
    username, _ = _seed_user()
    token = create_access_token({"sub": username})

    response = client.post(
        "/events/",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "raw_private_event_name", "properties": {}},
    )

    assert response.status_code == 201
    assert response.json()["name"] == "dashboard_viewed"
