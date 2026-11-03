from dataclasses import replace
from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4

import pytest
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.models import (
    AppleAccountToken, AppleIapTransaction, ApplePurchaseClaim,
    AppleSubscriptionClaim, EventReceipt, Subscription, User, UserEvent,
)
from app.services.apple_iap_service import VerifiedAppleTransaction
from test_launch_measurement import client, headers, user


@pytest.fixture
def purchase(client, monkeypatch):
    import app.routes.iap as route
    with SessionLocal() as db:
        user(db)
        user(db, "other")
        db.commit()
    state = {"verified": VerifiedAppleTransaction(
        "power6_proM", "1001", "1000", datetime.now(timezone.utc),
        datetime.now(timezone.utc) + timedelta(days=30), "Production", False, None, "provider-only",
    )}

    async def verify(**kwargs):
        return state["verified"]

    monkeypatch.setattr(route, "verify_apple_transaction", verify)
    return state


def activate(client, name="member", **fields):
    return client.post("/iap/apple/activate", headers=headers(name), json={
        "product_id": "power6_proM", "transaction_id": "1001", **fields,
    })


def test_account_token_requires_auth_is_stable_and_is_account_specific(client, purchase):
    assert client.post("/iap/apple/account-token").status_code == 401
    first = client.post("/iap/apple/account-token", headers=headers()).json()
    assert str(UUID(first["app_account_token"])) == first["app_account_token"]
    assert client.post("/api/iap/apple/account-token", headers=headers()).json() == first
    other = client.post("/iap/apple/account-token", headers=headers("other")).json()
    assert other != first
    assert set(first) == {"app_account_token"}
    assert "app_account_token" not in client.get("/users/me", headers=headers()).text


def test_provider_token_is_enforced_even_before_any_transaction_claim(client, purchase):
    token = client.post("/iap/apple/account-token", headers=headers()).json()["app_account_token"]
    purchase["verified"] = replace(purchase["verified"], app_account_token=token)
    assert activate(client, "other").status_code == 409
    with SessionLocal() as db:
        assert db.query(ApplePurchaseClaim).count() == 0
        assert db.query(AppleSubscriptionClaim).count() == 0
        assert db.query(Subscription).count() == 0
    assert activate(client).status_code == 200
    purchase["verified"] = replace(purchase["verified"], transaction_id="1002")
    assert activate(client, "other", transaction_id="1002").status_code == 409


def test_unknown_provider_token_is_never_adopted(client, purchase):
    purchase["verified"] = replace(purchase["verified"], app_account_token=str(uuid4()))
    assert activate(client).status_code == 409
    with SessionLocal() as db:
        assert db.query(AppleAccountToken).count() == 0


def test_legacy_renewals_share_ownership_projection_and_initial_measurement(client, purchase):
    for tx in ("1001", "1001", "1002", "1003"):
        purchase["verified"] = replace(purchase["verified"], transaction_id=tx)
        assert activate(client, transaction_id=tx).status_code == 200
    assert activate(client, "other", transaction_id="1003").status_code == 409
    # Even a never-seen renewal cannot move an already-owned subscription.
    purchase["verified"] = replace(purchase["verified"], transaction_id="1004")
    assert activate(client, "other", transaction_id="1004").status_code == 409
    with SessionLocal() as db:
        assert db.query(AppleIapTransaction).count() == 3
        assert db.query(ApplePurchaseClaim).count() == 3
        assert db.query(AppleSubscriptionClaim).count() == 1
        assert db.query(Subscription).count() == 1
        assert db.query(UserEvent).filter_by(name="purchase_verified").count() == 1


def test_historical_chain_cannot_be_claimed_by_another_account(client, purchase):
    with SessionLocal() as db:
        other = db.query(User).filter_by(username="other").one()
        db.add(AppleIapTransaction(user_id=other.id, product_id="power6_proM",
                                  transaction_id="999", original_transaction_id="1000",
                                  environment="Production"))
        db.commit()
    assert activate(client).status_code == 409
    with SessionLocal() as db:
        assert db.query(AppleSubscriptionClaim).count() == 0


def test_restore_refreshes_only_provider_evidence_and_preserves_higher_access(client, purchase):
    with SessionLocal() as db:
        db.query(User).filter_by(username="member").update({"tier": "elite"})
        db.commit()
    response = activate(client, original_transaction_id="spoofed", purchase_id="private", verification_data="client-blob")
    assert response.json()["tier"] == "elite"
    expiry = datetime.now(timezone.utc) + timedelta(days=80)
    purchase["verified"] = replace(purchase["verified"], expiration_date=expiry, signed_transaction_info="fresh-provider")
    assert activate(client).status_code == 200
    with SessionLocal() as db:
        row = db.query(AppleIapTransaction).one()
        assert row.original_transaction_id == "1000"
        assert row.purchase_id is None
        assert row.raw_verification_data == "fresh-provider"
        assert row.expiration_date.replace(tzinfo=timezone.utc) == expiry


def test_historical_restore_does_not_invent_new_conversion(client, purchase):
    with SessionLocal() as db:
        member = db.query(User).filter_by(username="member").one()
        db.add(AppleIapTransaction(user_id=member.id, product_id="power6_proM",
                                  transaction_id="1001", original_transaction_id="1000",
                                  environment="Production"))
        db.add(Subscription(user_id=member.id, tier="pro", active=True))
        db.commit()
    assert activate(client).status_code == 200
    with SessionLocal() as db:
        assert db.query(Subscription).count() == 1
        assert db.query(UserEvent).filter_by(name="purchase_verified").count() == 0


def test_commit_failure_rolls_back_chain_transaction_and_entitlement(client, purchase, monkeypatch):
    real_commit = Session.commit

    def fail_commit(self):
        raise RuntimeError("simulated database failure")

    monkeypatch.setattr(Session, "commit", fail_commit)
    with pytest.raises(RuntimeError):
        activate(client)
    monkeypatch.setattr(Session, "commit", real_commit)
    with SessionLocal() as db:
        for model in (ApplePurchaseClaim, AppleSubscriptionClaim, AppleIapTransaction, Subscription, UserEvent, EventReceipt):
            assert db.query(model).count() == 0
        assert db.query(User).filter_by(username="member").one().tier == "free"
    assert activate(client).status_code == 200


def test_account_deletion_removes_binding_and_chain(client, purchase):
    token = client.post("/iap/apple/account-token", headers=headers()).json()["app_account_token"]
    purchase["verified"] = replace(purchase["verified"], app_account_token=token)
    assert activate(client).status_code == 200
    assert client.delete("/users/me", headers=headers()).status_code == 200
    with SessionLocal() as db:
        for model in (AppleAccountToken, ApplePurchaseClaim, AppleSubscriptionClaim, AppleIapTransaction, Subscription):
            assert db.query(model).count() == 0
    # A new account cannot take over a provider token orphaned by deletion.
    assert activate(client, "other").status_code == 409


def test_input_bounds_reject_oversized_receipts_before_provider_call(client, purchase):
    assert activate(client, signed_transaction_info="x" * 65537).status_code == 422
    assert activate(client, product_id="x" * 129).status_code == 422
