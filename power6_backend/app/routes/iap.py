from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from uuid import uuid4
from hashlib import sha256

from app.database import get_db
from app.models.models import AppleAccountToken, AppleIapTransaction, ApplePurchaseClaim, AppleSubscriptionClaim, Subscription, User
from app.routes.auth import get_current_user
from app.schemas import UserRead
from app.services.apple_iap_service import verify_apple_transaction
from app.services.event_service import begin_claim, record_event

router = APIRouter(prefix="/iap", tags=["In-App Purchases"])

APPLE_PRODUCT_TIERS = {
    "power6_plus_monthly": "plus",
    "power6_plus_yearly": "plus",
    "power6_pro_monthly": "pro",
    "power6_pro_yearly": "pro",
    "power6_elite_monthly": "elite",
    "power6_elite_yearly": "elite",
    "power6_plusM": "plus",
    "power6_plusY": "plus",
    "power6_proM": "pro",
    "power6_proY": "pro",
    "power6_eliteM": "elite",
    "power6_eliteY": "elite",
}


class AppleActivateRequest(BaseModel):
    product_id: str = Field(min_length=1, max_length=128)
    transaction_id: str | None = Field(default=None, max_length=128)
    original_transaction_id: str | None = Field(default=None, max_length=128)
    purchase_id: str | None = Field(default=None, max_length=128)
    verification_data: str | None = Field(default=None, max_length=65536)
    signed_transaction_info: str | None = Field(default=None, max_length=65536)
    source: str = Field(default="ios_app_store", max_length=32)


class AppleAccountRead(BaseModel):
    app_account_token: str


@router.post("/apple/account-token", response_model=AppleAccountRead)
def apple_account_token(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    begin_claim(db)
    row = db.get(AppleAccountToken, current_user.id)
    if row is None:
        try:
            with db.begin_nested():
                row = AppleAccountToken(user_id=current_user.id, token=str(uuid4()))
                db.add(row)
                db.flush()
        except IntegrityError:
            row = db.get(AppleAccountToken, current_user.id)
            if row is None:
                raise
    db.commit()
    return AppleAccountRead(app_account_token=row.token)


def _claim(db, model, key, user_id, **fields):
    row = db.get(model, key)
    if row is None:
        try:
            with db.begin_nested():
                row = model(user_id=user_id, **fields)
                db.add(row)
                db.flush()
        except IntegrityError:
            row = db.get(model, key)
    if row is None or row.user_id != user_id:
        raise HTTPException(status_code=409, detail="Purchase belongs to another account.")
    return row


@router.post("/apple/activate", response_model=UserRead)
async def activate_apple_purchase(
    payload: AppleActivateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    tier = APPLE_PRODUCT_TIERS.get(payload.product_id)
    if tier is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Unknown App Store product ID.",
        )

    if payload.source != "ios_app_store":
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Unsupported purchase source.",
        )

    verified = await verify_apple_transaction(
        product_id=payload.product_id,
        transaction_id=payload.transaction_id,
        signed_transaction_info=payload.signed_transaction_info or payload.verification_data,
    )

    # Provider-bound tokens take precedence over legacy first-claim ownership.
    if verified.app_account_token is not None:
        account = db.get(AppleAccountToken, current_user.id)
        if account is None or account.token != verified.app_account_token:
            raise HTTPException(status_code=409, detail="Purchase belongs to another account.")

    original_id = verified.original_transaction_id or verified.transaction_id
    chain_key = f"{verified.environment}:{original_id}"
    begin_claim(db)
    # Serialize callbacks for the same account; unique claims serialize cross-account races.
    current_user = db.query(User).filter_by(id=current_user.id).with_for_update().populate_existing().one()
    historical = db.query(AppleIapTransaction).filter(
        (AppleIapTransaction.transaction_id == verified.transaction_id)
        | ((AppleIapTransaction.original_transaction_id == original_id)
           & (AppleIapTransaction.environment == verified.environment)),
    ).all()
    if any(row.user_id != current_user.id for row in historical):
        raise HTTPException(status_code=409, detail="Purchase belongs to another account.")
    new_chain = db.get(AppleSubscriptionClaim, chain_key) is None and not historical
    chain = _claim(db, AppleSubscriptionClaim, chain_key, current_user.id, chain_key=chain_key)
    _claim(db, ApplePurchaseClaim, verified.transaction_id, current_user.id,
           transaction_id=verified.transaction_id)
    transaction = next((row for row in historical if row.transaction_id == verified.transaction_id), None)
    if transaction is None:
        transaction = AppleIapTransaction(
            user_id=current_user.id,
            transaction_id=verified.transaction_id,
        )
        db.add(transaction)
    # Never copy client original IDs, purchase IDs or receipt contents into verified evidence.
    transaction.product_id = verified.product_id
    transaction.original_transaction_id = original_id
    transaction.purchase_date = verified.purchase_date
    transaction.expiration_date = verified.expiration_date
    transaction.environment = verified.environment
    transaction.revoked = verified.revoked
    transaction.revocation_date = verified.revocation_date
    transaction.raw_verification_data = verified.signed_transaction_info
    transaction.source = "ios_app_store"

    projection = db.get(Subscription, chain.subscription_row_id) if chain.subscription_row_id else None
    if projection is None:
        # Adopt a matching historical projection without claiming unrelated subscriptions.
        if historical:
            projection = db.query(Subscription).filter_by(user_id=current_user.id, tier=tier).first()
        if projection is None:
            projection = Subscription(user_id=current_user.id, tier=tier, active=True)
            db.add(projection)
            db.flush()
        chain.subscription_row_id = projection.id
    projection.tier = tier
    projection.active = True
    # Activation never removes a higher existing entitlement or administrator access.
    rank = {"free": 0, "expired": 0, "plus": 1, "pro": 2, "elite": 3, "admin": 4}
    if not current_user.is_admin and rank.get(str(current_user.tier).lower(), 0) <= rank[tier]:
        current_user.tier = tier
    db.add(current_user)
    if new_chain:
        record_event(db, current_user, "purchase_verified", properties={
            "plan": tier, "platform": "ios", "environment": verified.environment or "",
        }, once_key="apple-chain:" + sha256(chain_key.encode()).hexdigest())
    db.commit()
    db.refresh(current_user)

    return UserRead.model_validate(current_user)
