import os

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_iap_activate.sqlite")
os.environ.setdefault("SECRET_KEY", "test-secret")

from fastapi.testclient import TestClient
from datetime import datetime, timedelta, timezone

from app.database import Base, engine
from app.main import build_app
from app.models.models import AppleIapTransaction, Subscription, User
from app.routes.auth import create_access_token
from app.services.apple_iap_service import VerifiedAppleTransaction
from app.utils.hash import get_password_hash


def test_apple_iap_activate_records_purchase_and_updates_tier():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    app = build_app()
    client = TestClient(app)

    from app.database import SessionLocal

    db = SessionLocal()
    try:
        user = User(
            username="iap_user",
            email="iap_user@example.com",
            hashed_password=get_password_hash("Password123!"),
            tier="Free",
        )
        db.add(user)
        db.commit()
        user_id = user.id
    finally:
        db.close()

    token = create_access_token({"sub": "iap_user"})
    import app.routes.iap as iap_route

    async def fake_verify_apple_transaction(*, product_id, transaction_id, signed_transaction_info):
        return VerifiedAppleTransaction(
            product_id=product_id,
            transaction_id=transaction_id or "tx_123",
            original_transaction_id="original_tx_123",
            purchase_date=datetime.now(timezone.utc),
            expiration_date=datetime.now(timezone.utc) + timedelta(days=30),
            environment="Sandbox",
            revoked=False,
            revocation_date=None,
            signed_transaction_info=signed_transaction_info or "signed-data",
        )

    iap_route.verify_apple_transaction = fake_verify_apple_transaction

    response = client.post(
        "/iap/apple/activate",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "product_id": "power6_proM",
            "transaction_id": "tx_123",
            "purchase_id": "purchase_123",
            "verification_data": "signed-data",
            "source": "ios_app_store",
        },
    )

    assert response.status_code == 200
    assert response.json()["tier"] == "pro"

    db = SessionLocal()
    try:
        assert db.query(User).filter(User.id == user_id).first().tier == "pro"
        assert db.query(Subscription).filter(Subscription.user_id == user_id).count() == 1
        purchase = db.query(AppleIapTransaction).filter(
            AppleIapTransaction.user_id == user_id,
        ).first()
        assert purchase.product_id == "power6_proM"
        assert purchase.transaction_id == "tx_123"
        assert purchase.original_transaction_id == "original_tx_123"
        assert purchase.expiration_date is not None
        assert purchase.revoked is False
    finally:
        db.close()


def test_apple_iap_activate_accepts_legacy_short_product_id():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    app = build_app()
    client = TestClient(app)

    from app.database import SessionLocal

    db = SessionLocal()
    try:
        user = User(
            username="iap_legacy_user",
            email="iap_legacy_user@example.com",
            hashed_password=get_password_hash("Password123!"),
            tier="Free",
        )
        db.add(user)
        db.commit()
    finally:
        db.close()

    token = create_access_token({"sub": "iap_legacy_user"})
    import app.routes.iap as iap_route

    async def fake_verify_apple_transaction(*, product_id, transaction_id, signed_transaction_info):
        return VerifiedAppleTransaction(
            product_id=product_id,
            transaction_id=transaction_id or "tx_legacy",
            original_transaction_id="original_tx_legacy",
            purchase_date=datetime.now(timezone.utc),
            expiration_date=datetime.now(timezone.utc) + timedelta(days=30),
            environment="Sandbox",
            revoked=False,
            revocation_date=None,
            signed_transaction_info=signed_transaction_info or "signed-data",
        )

    iap_route.verify_apple_transaction = fake_verify_apple_transaction

    response = client.post(
        "/iap/apple/activate",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "product_id": "power6_proM",
            "transaction_id": "tx_legacy",
            "verification_data": "signed-data",
            "source": "ios_app_store",
        },
    )

    assert response.status_code == 200
    assert response.json()["tier"] == "pro"
