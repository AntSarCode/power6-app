import hashlib
import hmac
import json
import time
from datetime import datetime, timedelta, timezone

import pytest
import stripe
from fastapi.testclient import TestClient

from app.config.settings import settings
from app.database import Base, SessionLocal, engine
from app.main import build_app
from app.models.models import AppleIapTransaction, StripeCheckout, Subscription, User, UserEvent
from app.routes.auth import create_access_token


@pytest.fixture
def setup(monkeypatch):
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    monkeypatch.setattr(settings, "STRIPE_SECRET_KEY", "sk_live_fake")
    monkeypatch.setattr(settings, "STRIPE_WEBHOOK_SECRET", "whsec_fake")
    monkeypatch.setattr(settings, "STRIPE_PRICE_ID_PRO_MONTHLY", "price_pro")
    monkeypatch.setattr(settings, "STRIPE_PRICE_ID_PLUS_YEARLY", "price_plus")
    monkeypatch.setattr(settings, "STRIPE_ENABLE_TEST_ENTITLEMENTS", False)
    with SessionLocal() as db:
        db.add_all([User(username=name, email=f"{name}@example.com", hashed_password="unused", tier="free")
                    for name in ("buyer", "other")])
        db.commit()
        uid = db.query(User).filter_by(username="buyer").one().id
    state = {
        "session": {"id": "cs_fake", "url": "https://checkout.stripe.com/fake", "livemode": True,
                    "client_reference_id": str(uid), "mode": "subscription", "status": "complete",
                    "payment_status": "paid", "subscription": "sub_fake", "customer": "cus_fake",
                    "line_items": {"data": [{"quantity": 1, "price": {"id": "price_pro"}}]}},
        "subscription": {"id": "sub_fake", "customer": "cus_fake", "livemode": True, "status": "active",
                         "items": {"data": [{"quantity": 1, "price": {"id": "price_pro"}}]}},
        "created": [], "retrieved": [],
    }
    def create(**kwargs):
        state["created"].append(kwargs)
        return state["session"]
    def retrieve(session_id, **kwargs):
        state["retrieved"].append(session_id)
        return state["session"]
    monkeypatch.setattr(stripe.checkout.Session, "create", create)
    monkeypatch.setattr(stripe.checkout.Session, "retrieve", retrieve)
    monkeypatch.setattr(stripe.Subscription, "retrieve", lambda *args, **kwargs: state["subscription"])
    with TestClient(build_app()) as client:
        yield client, state, uid


def auth(name="buyer"):
    return {"Authorization": f"Bearer {create_access_token({'sub': name})}"}


def checkout(client, **kwargs):
    return client.post("/stripe/create-checkout-session", headers=auth(),
                       json={"tier": "pro", "interval": "monthly", **kwargs})


def webhook(client, kind="checkout.session.completed", *, mode=True, object_id="cs_fake", event_id="evt_fake", path="/stripe/webhook"):
    body = json.dumps({"id": event_id, "object": "event", "type": kind, "livemode": mode,
                       "data": {"object": {"id": object_id, "metadata": {"user_id": "9999", "tier": "elite"}}}}).encode()
    stamp = str(int(time.time()))
    digest = hmac.new(b"whsec_fake", stamp.encode() + b"." + body, hashlib.sha256).hexdigest()
    return client.post(path, content=body, headers={"stripe-signature": f"t={stamp},v1={digest}"})


def test_checkout_requires_auth_and_owns_account(setup):
    client, state, uid = setup
    assert client.post("/stripe/create-checkout-session", json={"tier": "pro", "interval": "monthly"}).status_code == 401
    assert checkout(client, user_id="9999").status_code == 403
    assert not state["created"]
    assert checkout(client, user_id=str(uid), tier=" PRO ").status_code == 200
    assert state["created"][0]["client_reference_id"] == str(uid)
    assert state["created"][0]["line_items"] == [{"price": "price_pro", "quantity": 1}]
    with SessionLocal() as db:
        assert db.query(StripeCheckout).one().user_id == uid


@pytest.mark.parametrize("change", [{"tier": "free"}, {"tier": "admin"}, {"interval": "daily"}])
def test_invalid_plan_never_calls_stripe(setup, change):
    client, state, _ = setup
    assert checkout(client, **change).status_code == 422
    assert not state["created"]


def test_missing_configuration_fails_closed(setup, monkeypatch):
    client, _, _ = setup
    monkeypatch.setattr(settings, "STRIPE_PRICE_ID_PRO_MONTHLY", None)
    assert checkout(client).status_code == 503
    monkeypatch.setattr(settings, "STRIPE_WEBHOOK_SECRET", None)
    assert webhook(client).status_code == 503


def test_signature_and_payload_integrity(setup):
    client, _, _ = setup
    assert checkout(client).status_code == 200
    assert client.post("/stripe/webhook", json={"type": "checkout.session.completed"}).status_code == 400
    assert client.post("/stripe/webhook", content=b"{}", headers={"stripe-signature": "t=1,v1=invalid"}).status_code == 400
    with SessionLocal() as db:
        assert db.query(UserEvent).filter_by(name="purchase_verified").count() == 0


def test_fulfillment_is_owned_paid_and_idempotent(setup):
    client, state, uid = setup
    assert checkout(client).status_code == 200
    for event_id in ("evt_1", "evt_1", "evt_2"):
        assert webhook(client, event_id=event_id).status_code == 200
    assert state["retrieved"] == ["cs_fake"] * 3
    with SessionLocal() as db:
        assert db.get(User, uid).tier == "pro"
        assert db.query(User).filter_by(username="other").one().tier == "free"
        assert db.query(Subscription).count() == 1
        assert db.query(UserEvent).count() == 1
        assert db.query(UserEvent).one().properties == {"plan": "pro", "interval": "monthly", "platform": "web", "environment": "production"}


@pytest.mark.parametrize("target,change,expected", [
    ("session", {"payment_status": "unpaid"}, 200),
    ("session", {"status": "open"}, 200),
    ("session", {"client_reference_id": "9999"}, 422),
    ("session", {"livemode": False}, 422),
    ("session", {"line_items": {"data": [{"quantity": 1, "price": {"id": "other"}}]}}, 422),
    ("subscription", {"customer": "cus_other"}, 422),
    ("subscription", {"status": "canceled"}, 200),
    ("subscription", {"items": {"data": []}}, 422),
])
def test_unverified_or_unpaid_never_grants(setup, target, change, expected):
    client, state, uid = setup
    assert checkout(client).status_code == 200
    state[target].update(change)
    assert webhook(client).status_code == expected
    with SessionLocal() as db:
        assert db.get(User, uid).tier == "free"
        assert db.query(UserEvent).count() == 0
        assert db.query(Subscription).count() == 0


def test_upstream_failure_retries_without_partial_grant(setup, monkeypatch):
    client, state, uid = setup
    assert checkout(client).status_code == 200
    def fail(*args, **kwargs):
        raise stripe.APIConnectionError("secret and customer data must not leak")
    monkeypatch.setattr(stripe.Subscription, "retrieve", fail)
    response = webhook(client)
    assert response.status_code == 502
    assert "secret and" not in response.text
    with SessionLocal() as db:
        assert not db.query(StripeCheckout).one().fulfilled
        assert db.get(User, uid).tier == "free"


def test_test_mode_cannot_grant_production_entitlements(setup, monkeypatch):
    client, state, uid = setup
    monkeypatch.setattr(settings, "STRIPE_SECRET_KEY", "sk_test_fake")
    state["session"]["livemode"] = state["subscription"]["livemode"] = False
    assert checkout(client).status_code == 200
    assert webhook(client, mode=True).status_code == 400
    assert webhook(client, mode=False).json()["status"] == "test_mode_ignored"
    with SessionLocal() as db:
        assert db.get(User, uid).tier == "free"
    monkeypatch.setattr(settings, "STRIPE_ENABLE_TEST_ENTITLEMENTS", True)
    assert webhook(client, mode=False).json()["status"] == "success"
    with SessionLocal() as db:
        assert db.query(UserEvent).one().properties["environment"] == "sandbox"


def test_lifecycle_uses_latest_state_not_event_order(setup):
    client, state, uid = setup
    assert checkout(client).status_code == 200
    assert webhook(client).status_code == 200
    state["subscription"]["status"] = "canceled"
    assert webhook(client, "customer.subscription.deleted", object_id="sub_fake").status_code == 200
    # A delayed old checkout completion must not revive a cancelled subscription.
    assert webhook(client).status_code == 200
    with SessionLocal() as db:
        assert db.get(User, uid).tier == "free"
        assert not db.query(Subscription).one().active
        assert db.query(UserEvent).count() == 1
    state["subscription"]["status"] = "active"
    state["subscription"]["items"]["data"][0]["price"]["id"] = "price_plus"
    assert webhook(client, "customer.subscription.updated", object_id="sub_fake").status_code == 200
    with SessionLocal() as db:
        assert db.get(User, uid).tier == "plus"
        assert db.query(UserEvent).count() == 1
    assert webhook(client).status_code == 200
    with SessionLocal() as db:
        assert db.get(User, uid).tier == "plus"


def test_cancellation_preserves_other_provider_and_account_deletion_cleans_ledger(setup):
    client, state, uid = setup
    assert checkout(client).status_code == 200
    assert webhook(client).status_code == 200
    with SessionLocal() as db:
        db.add(AppleIapTransaction(user_id=uid, product_id="power6_eliteM", revoked=False,
                                  expiration_date=datetime.now(timezone.utc) + timedelta(days=1)))
        db.commit()
    state["subscription"]["status"] = "canceled"
    assert webhook(client, "customer.subscription.updated", object_id="sub_fake").status_code == 200
    with SessionLocal() as db:
        assert db.get(User, uid).tier == "elite"
    assert client.delete("/users/me", headers=auth()).status_code == 200
    with SessionLocal() as db:
        assert db.query(StripeCheckout).count() == 0
        assert db.query(UserEvent).count() == 0


def test_unknown_sessions_and_event_types_are_not_fulfilled(setup):
    client, _, _ = setup
    assert webhook(client).json()["status"] == "untracked"
    assert webhook(client, "customer.created").json()["status"] == "ignored"


def test_failed_commit_rolls_back_grant_and_allows_retry(setup, monkeypatch):
    from sqlalchemy.orm import Session
    client, _, uid = setup
    assert checkout(client).status_code == 200
    original = Session.commit
    def fail_commit(self):
        raise RuntimeError("simulated commit failure")
    monkeypatch.setattr(Session, "commit", fail_commit)
    with pytest.raises(RuntimeError, match="simulated commit failure"):
        webhook(client)
    with SessionLocal() as db:
        assert not db.query(StripeCheckout).one().fulfilled
        assert db.get(User, uid).tier == "free"
        assert db.query(Subscription).count() == 0
        assert db.query(UserEvent).count() == 0
    monkeypatch.setattr(Session, "commit", original)
    assert webhook(client).status_code == 200


def test_production_report_splits_providers_and_excludes_sandbox(setup):
    from app.services.event_service import record_event
    from app.services.launch_report import build_launch_report
    client, _, uid = setup
    assert checkout(client).status_code == 200
    assert webhook(client, path="/api/stripe/webhook").status_code == 200
    with SessionLocal() as db:
        row = db.get(User, uid)
        record_event(db, row, "purchase_verified", properties={"platform": "ios", "environment": "production"})
        record_event(db, row, "purchase_verified", properties={"platform": "web", "environment": "sandbox"})
        db.commit()
        report = build_launch_report(db)
        providers = {row["provider"]: row for row in report["verified_purchases_by_provider"]}
        assert providers["stripe"] == {"provider": "stripe", "events": 1, "users": 1}
        assert providers["apple"] == {"provider": "apple", "events": 1, "users": 1}
        assert "cs_fake" not in str(report)


def test_baseline_access_is_not_downgraded(setup):
    client, state, uid = setup
    with SessionLocal() as db:
        db.get(User, uid).tier = "elite"
        db.commit()
    assert checkout(client).status_code == 200
    assert webhook(client).status_code == 200
    state["subscription"]["status"] = "canceled"
    assert webhook(client, "customer.subscription.deleted", object_id="sub_fake").status_code == 200
    with SessionLocal() as db:
        assert db.get(User, uid).tier == "elite"


def test_cancelling_one_subscription_preserves_another(setup, monkeypatch):
    from copy import deepcopy
    client, state, uid = setup
    assert checkout(client).status_code == 200
    assert webhook(client).status_code == 200
    first = deepcopy(state["subscription"])
    monkeypatch.setattr(settings, "STRIPE_PRICE_ID_ELITE_MONTHLY", "price_elite")
    state["session"].update(id="cs_second", subscription="sub_second")
    state["session"]["line_items"]["data"][0]["price"]["id"] = "price_elite"
    state["subscription"].update(id="sub_second")
    state["subscription"]["items"]["data"][0]["price"]["id"] = "price_elite"
    assert checkout(client, tier="elite").status_code == 200
    assert webhook(client, object_id="cs_second").status_code == 200
    second = deepcopy(state["subscription"])
    state["subscription"] = {**first, "status": "canceled"}
    assert webhook(client, "customer.subscription.deleted", object_id="sub_fake").status_code == 200
    with SessionLocal() as db:
        assert db.get(User, uid).tier == "elite"
    state["subscription"] = {**second, "status": "canceled"}
    assert webhook(client, "customer.subscription.deleted", object_id="sub_second").status_code == 200
    with SessionLocal() as db:
        assert db.get(User, uid).tier == "free"
