import os

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_events.sqlite")
os.environ.setdefault("SECRET_KEY", "test-secret")

from fastapi.testclient import TestClient

from app.database import Base, engine
from app.main import build_app
from app.models.models import User, UserEvent
from app.routes.auth import create_access_token
from app.utils.hash import get_password_hash


def _seed_user(*, username: str = "event_user", is_admin: bool = False) -> tuple[str, int]:
    from app.database import SessionLocal

    db = SessionLocal()
    try:
        user = User(
            username=username,
            email=f"{username}@example.com",
            hashed_password=get_password_hash("Password123!"),
            tier="Pro",
            is_admin=is_admin,
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


def test_admin_event_summary_returns_funnel_counts():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    app = build_app()
    client = TestClient(app)
    admin_username, _ = _seed_user(username="event_admin", is_admin=True)
    user_username, _ = _seed_user(username="event_member")
    admin_token = create_access_token({"sub": admin_username})
    user_token = create_access_token({"sub": user_username})

    for name in ["signup_completed", "dashboard_viewed", "task_created"]:
        response = client.post(
            "/events/",
            headers={"Authorization": f"Bearer {user_token}"},
            json={"name": name, "properties": {}},
        )
        assert response.status_code == 201

    response = client.get(
        "/events/summary?days=30",
        headers={"Authorization": f"Bearer {admin_token}"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["window_days"] == 30
    assert body["total_events"] == 3
    assert body["unique_users"] == 1
    assert body["counts"]["task_created"] == {"events": 1, "users": 1}
    funnel = {item["name"]: item for item in body["funnel"]}
    assert funnel["signup_completed"]["events"] == 1
    assert funnel["checkout_started"]["events"] == 0


def test_event_summary_blocks_non_admins():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    app = build_app()
    client = TestClient(app)
    username, _ = _seed_user(username="event_non_admin")
    token = create_access_token({"sub": username})

    response = client.get(
        "/events/summary",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403
