from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.database import get_db
from app.models.models import AppleIapTransaction, ApplePurchaseClaim, Subscription, User
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
    product_id: str = Field(min_length=1)
    transaction_id: str | None = None
    original_transaction_id: str | None = None
    purchase_id: str | None = None
    verification_data: str | None = None
    signed_transaction_info: str | None = None
    source: str = "ios_app_store"


def _restore_entitlement(db, current_user, tier):
    current_user.tier = tier
    existing = db.query(Subscription).filter_by(user_id=current_user.id, tier=tier).first()
    if existing is None:
        db.add(Subscription(user_id=current_user.id, tier=tier, active=True))
    else:
        existing.active = True
    db.commit()
    db.refresh(current_user)
    return UserRead.model_validate(current_user)


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

    # Lock ownership with a unique row, including simultaneous restore callbacks.
    # Check historical rows too; older deployments did not create claim records.
    historical = db.query(AppleIapTransaction).filter(
        AppleIapTransaction.transaction_id == verified.transaction_id,
    ).all()
    if any(row.user_id != current_user.id for row in historical):
        raise HTTPException(status_code=409, detail="Purchase belongs to another account.")
    begin_claim(db)
    try:
        with db.begin_nested():
            db.add(ApplePurchaseClaim(transaction_id=verified.transaction_id, user_id=current_user.id))
            db.flush()
    except IntegrityError:
        owner = db.get(ApplePurchaseClaim, verified.transaction_id)
        if owner is None or owner.user_id != current_user.id:
            raise HTTPException(status_code=409, detail="Purchase belongs to another account.")
        return _restore_entitlement(db, current_user, tier)
    if historical:
        return _restore_entitlement(db, current_user, tier)

    current_user.tier = tier
    db.add(
        AppleIapTransaction(
            user_id=current_user.id,
            product_id=verified.product_id,
            transaction_id=verified.transaction_id,
            original_transaction_id=verified.original_transaction_id
            or payload.original_transaction_id,
            purchase_id=payload.purchase_id,
            purchase_date=verified.purchase_date,
            expiration_date=verified.expiration_date,
            environment=verified.environment,
            revoked=verified.revoked,
            revocation_date=verified.revocation_date,
            raw_verification_data=verified.signed_transaction_info,
            source=payload.source,
        ),
    )
    db.add(
        Subscription(
            user_id=current_user.id,
            tier=tier,
            active=True,
        ),
    )
    db.add(current_user)
    record_event(db, current_user, "purchase_verified", properties={
        "plan": tier, "platform": "ios", "environment": verified.environment or "",
    }, once_key=f"purchase:{verified.transaction_id}")
    db.commit()
    db.refresh(current_user)

    return UserRead.model_validate(current_user)
