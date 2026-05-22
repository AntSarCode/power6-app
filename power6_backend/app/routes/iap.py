from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import AppleIapTransaction, Subscription, User
from app.routes.auth import get_current_user
from app.schemas import UserRead
from app.services.apple_iap_service import verify_apple_transaction

router = APIRouter(prefix="/iap", tags=["In-App Purchases"])

APPLE_PRODUCT_TIERS = {
    "power6_plus_monthly": "plus",
    "power6_plus_yearly": "plus",
    "power6_pro_monthly": "pro",
    "power6_pro_yearly": "pro",
    "power6_elite_monthly": "elite",
    "power6_elite_yearly": "elite",
}


class AppleActivateRequest(BaseModel):
    product_id: str = Field(min_length=1)
    transaction_id: str | None = None
    original_transaction_id: str | None = None
    purchase_id: str | None = None
    verification_data: str | None = None
    signed_transaction_info: str | None = None
    source: str = "ios_app_store"


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
    db.commit()
    db.refresh(current_user)

    return UserRead.model_validate(current_user)
