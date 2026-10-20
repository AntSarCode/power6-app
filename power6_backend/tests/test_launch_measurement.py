import asyncio
from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.database import Base, SessionLocal, engine
from app.main import build_app
from app.models.models import AppleIapTransaction, EventReceipt, Subscription, User, UserEvent
from app.routes.auth import create_access_token
from app.services.event_service import record_event
from app.services.launch_report import build_launch_report


@pytest.fixture
def client():
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    with TestClient(build_app()) as client:
        yield client


def user(db, name="member", *, admin=False, created=None):
    row = User(username=name, email=f"{name}@example.com", hashed_password="unused",
               tier="free", is_admin=admin, created_at=created or datetime.now(timezone.utc))
    db.add(row)
    db.flush()
    return row


def headers(name="member"):
    return {"Authorization": f"Bearer {create_access_token({'sub': name})}"}


def test_action_endpoints_record_six_task_milestones_and_limit(client):
    response = client.post("/auth/register", json={
        "username": "member", "email": "member@example.com", "password": "Password123!",
    })
    assert response.status_code == 201
    ids = []
    for i in range(6):
        response = client.post("/tasks/", headers=headers(), json={"title": f"Private {i}"})
        assert response.status_code == 201
        ids.append(response.json()["id"])
    assert client.post("/tasks/", headers=headers(), json={"title": "Seventh"}).status_code == 400
    # Cover every completion entry point, and replay PATCH / undo / redo.
    for i, task_id in enumerate(ids):
        path = f"/tasks/{task_id}"
        response = (client.post(path + "/toggle", headers=headers()) if i == 0 else
                    client.put(path, headers=headers(), json={"completed": True}) if i == 1 else
                    client.patch(path, headers=headers(), json={"completed": True}))
        assert response.status_code == 200
    streak = client.get("/streak/", headers=headers())
    assert streak.status_code == 200
    assert streak.json()["today_count"] == 6
    assert streak.json()["streak_count"] == 1
    assert client.post("/streak/refresh", headers=headers()).json()["today_count"] == 6
    for completed in (True, False, True):
        assert client.patch(f"/tasks/{ids[0]}", headers=headers(), json={"completed": completed}).status_code == 200
    with SessionLocal() as db:
        counts = {name: db.query(UserEvent).filter_by(name=name).count() for name in
                  ["signup_completed", "task_created", "task_completed", "six_tasks_planned", "six_tasks_completed"]}
        assert counts == {"signup_completed": 1, "task_created": 6, "task_completed": 6,
                          "six_tasks_planned": 1, "six_tasks_completed": 1}
        assert all(row.source == "server" and not row.properties for row in db.query(UserEvent))


def test_contract_rejects_spoofed_milestones_and_strips_private_values(client):
    with SessionLocal() as db:
        user(db)
        db.commit()
    for name in ["signup_completed", "task_created", "task_completed"]:
        assert client.post("/events/", headers=headers(), json={"name": name}).status_code == 204
    for name in ["purchase_verified", "six_tasks_planned", "private_event"]:
        assert client.post("/events/", headers=headers(), json={"name": name}).status_code == 422
    response = client.post("/events/", headers=headers(), json={
        "name": "dashboard_viewed", "properties": {
            "title": "private", "source": "private text", "tier": "Pro", "count": True,
            "today_task_count": 6, "plan": {"private": "text"}, "completed_today": -1,
        },
    })
    assert response.json()["properties"] == {"tier": "pro", "today_task_count": 6}
    assert client.post("/events/", headers=headers(), json={
        "name": "dashboard_viewed", "source": "secret@example.com",
    }).status_code == 422
    assert client.post("/events/", json={"name": "dashboard_viewed"}).status_code == 401
    with SessionLocal() as db:
        assert db.query(UserEvent).count() == 1


def test_launch_cohort_retention_excludes_immature_days_admins_and_sandbox(client):
    now = datetime(2026, 10, 20, 15, tzinfo=timezone.utc)
    with SessionLocal() as db:
        mature = user(db, "mature", created=now - timedelta(days=5))
        fresh = user(db, "fresh", created=now - timedelta(days=3))
        inactive = user(db, "inactive", created=now - timedelta(days=6))
        admin = user(db, "admin", admin=True, created=now - timedelta(days=5))
        review = user(db, "app_review_expired", created=now - timedelta(days=5))
        for row in [mature, admin, review]:
            record_event(db, row, "task_created", now=now - timedelta(days=5) + timedelta(minutes=1))
            # Multiple events/users on day 3 still count as one retained user.
            for _ in range(2):
                record_event(db, row, "dashboard_viewed", now=now - timedelta(days=2))
        for env in ["sandbox", "production"]:
            record_event(db, mature, "purchase_verified", properties={"environment": env}, now=now)
        record_event(db, fresh, "dashboard_viewed", now=now)
        record_event(db, inactive, "dashboard_viewed", now=now + timedelta(days=1))
        db.commit()
        report = build_launch_report(db, now=now)
        cohort = report["signup_cohort"]
        assert cohort["users"] == 3
        assert cohort["first_task"] == {"users": 1, "eligible_users": 3, "percent": 33.3}
        assert cohort["day_3_retention"] == {"users": 1, "eligible_users": 2, "percent": 50.0}
        purchase = next(row for row in report["stages"] if row["name"] == "purchase_verified")
        assert purchase == {"name": "purchase_verified", "events": 1, "users": 1}
        assert "@" not in str(report)


def test_launch_report_access_bounds_and_empty_denominators(client):
    with SessionLocal() as db:
        user(db)
        user(db, "admin", admin=True)
        db.commit()
    assert client.get("/events/launch").status_code == 401
    assert client.get("/events/launch", headers=headers()).status_code == 403
    assert client.get("/events/launch?days=121", headers=headers("admin")).status_code == 422
    response = client.get("/api/events/launch?days=1", headers=headers("admin"))
    assert response.status_code == 200
    assert response.json()["signup_cohort"]["day_3_retention"]["percent"] is None


def test_apple_activation_is_idempotent_and_owned(client, monkeypatch):
    from app.services.apple_iap_service import VerifiedAppleTransaction
    import app.routes.iap as route

    async def verify(**kwargs):
        return VerifiedAppleTransaction(
            "power6_proM", "1234", "1234", datetime.now(timezone.utc),
            datetime.now(timezone.utc) + timedelta(days=30), "Production", False, None, "server-data",
        )
    monkeypatch.setattr(route, "verify_apple_transaction", verify)
    with SessionLocal() as db:
        user(db)
        user(db, "other")
        db.commit()
    payload = {"product_id": "power6_proM", "transaction_id": "1234"}
    for _ in range(3):
        with SessionLocal() as db:
            db.query(User).filter_by(username="member").update({"tier": "expired"})
            db.commit()
        assert client.post("/iap/apple/activate", headers=headers(), json=payload).status_code == 200
    with SessionLocal() as db:
        assert db.query(User).filter_by(username="member").one().tier == "pro"
    assert client.post("/iap/apple/activate", headers=headers("other"), json=payload).status_code == 409
    with SessionLocal() as db:
        assert db.query(AppleIapTransaction).count() == 1
        assert db.query(Subscription).count() == 1
        assert db.query(UserEvent).filter_by(name="purchase_verified").count() == 1
    assert client.delete("/users/me", headers=headers()).status_code == 200
    with SessionLocal() as db:
        assert db.query(EventReceipt).count() == 0
        assert db.query(UserEvent).count() == 0


def test_client_jws_cannot_bypass_apple_configuration(monkeypatch):
    from app.services import apple_iap_service as service
    from test_iap_activate import _unsigned_jws
    monkeypatch.setattr(service.settings, "APPLE_IAP_ISSUER_ID", None)
    with pytest.raises(HTTPException) as error:
        asyncio.run(service.verify_apple_transaction(
            product_id="power6_proM", transaction_id=None,
            signed_transaction_info=_unsigned_jws({"transactionId": "1234"}),
        ))
    assert error.value.status_code == 503


def test_event_receipt_rolls_back_with_outer_action(client):
    with SessionLocal() as db:
        row = user(db)
        db.commit()
        record_event(db, row, "six_tasks_planned", once_key="rollback-test")
        db.rollback()
        assert db.query(EventReceipt).count() == 0
        assert db.query(UserEvent).count() == 0
        assert record_event(db, row, "six_tasks_planned", once_key="rollback-test")
        assert not record_event(db, row, "six_tasks_planned", once_key="rollback-test")
        db.commit()
        assert db.query(UserEvent).count() == 1
