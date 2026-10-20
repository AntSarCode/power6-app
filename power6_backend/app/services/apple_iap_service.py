from __future__ import annotations

import base64
import json
import re
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import uuid4

import httpx
from fastapi import HTTPException, status
from jose import jwt

from app.config.settings import settings


PRODUCTION_ENDPOINT = "https://api.storekit.itunes.apple.com"
SANDBOX_ENDPOINT = "https://api.storekit-sandbox.itunes.apple.com"


@dataclass(frozen=True)
class VerifiedAppleTransaction:
    product_id: str
    transaction_id: str
    original_transaction_id: str | None
    purchase_date: datetime | None
    expiration_date: datetime | None
    environment: str | None
    revoked: bool
    revocation_date: datetime | None
    signed_transaction_info: str


def _apple_private_key() -> str:
    raw = settings.APPLE_IAP_PRIVATE_KEY
    if not raw:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Apple IAP verification is not configured.",
        )
    return raw.replace("\\n", "\n")


def _app_store_jwt() -> str:
    if (
        not settings.APPLE_IAP_ISSUER_ID
        or not settings.APPLE_IAP_KEY_ID
        or not settings.APPLE_IAP_BUNDLE_ID
    ):
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Apple IAP verification is not configured.",
        )

    now = datetime.now(timezone.utc)
    payload = {
        "iss": settings.APPLE_IAP_ISSUER_ID,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=20)).timestamp()),
        "aud": "appstoreconnect-v1",
        "bid": settings.APPLE_IAP_BUNDLE_ID,
        "nonce": str(uuid4()),
    }
    headers = {
        "alg": "ES256",
        "kid": settings.APPLE_IAP_KEY_ID,
        "typ": "JWT",
    }
    return jwt.encode(payload, _apple_private_key(), algorithm="ES256", headers=headers)


def _decode_jws_payload(jws: str) -> dict[str, Any]:
    try:
        payload = jws.split(".")[1]
        payload += "=" * (-len(payload) % 4)
        data = json.loads(base64.urlsafe_b64decode(payload.encode("utf-8")))
        if not isinstance(data, dict):
            raise ValueError("Expected object")
        return data
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Apple transaction payload could not be decoded.",
        )


def _looks_like_jws(value: str | None) -> bool:
    return bool(value and len(value.split(".")) == 3)


def _ms_to_datetime(value: Any) -> datetime | None:
    if value in (None, ""):
        return None
    try:
        return datetime.fromtimestamp(int(value) / 1000, tz=timezone.utc)
    except (TypeError, ValueError, OverflowError):
        return None


async def _fetch_transaction(transaction_id: str, endpoint: str, token: str) -> str:
    url = f"{endpoint}/inApps/v1/transactions/{transaction_id}"
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.get(url, headers={"Authorization": f"Bearer {token}"})
    except httpx.RequestError:
        raise HTTPException(status_code=502, detail="Apple verification is temporarily unavailable.")
    if response.status_code == 404:
        raise KeyError("transaction not found")
    if response.status_code >= 400:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Apple transaction verification failed.",
        )
    body = response.json()
    signed = body.get("signedTransactionInfo")
    if not signed:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Apple did not return signed transaction information.",
        )
    return signed


def _verified_from_signed_transaction(
    *,
    product_id: str,
    signed_transaction_info: str,
) -> VerifiedAppleTransaction:
    data = _decode_jws_payload(signed_transaction_info)

    bundle_id = data.get("bundleId")
    if settings.APPLE_IAP_BUNDLE_ID and bundle_id != settings.APPLE_IAP_BUNDLE_ID:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Apple transaction bundle ID does not match this app.",
        )

    if data.get("productId") != product_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Apple transaction product ID does not match the requested product.",
        )

    revocation_date = _ms_to_datetime(data.get("revocationDate"))
    expiration_date = _ms_to_datetime(data.get("expiresDate"))
    if revocation_date is not None:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Apple subscription has been revoked or refunded.",
        )
    if expiration_date is None or expiration_date <= datetime.now(timezone.utc):
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Apple subscription is expired.",
        )

    verified_transaction_id = str(data.get("transactionId") or "")
    if not verified_transaction_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Apple transaction is missing a transaction ID.",
        )

    return VerifiedAppleTransaction(
        product_id=product_id,
        transaction_id=verified_transaction_id,
        original_transaction_id=(
            str(data["originalTransactionId"])
            if data.get("originalTransactionId") is not None
            else None
        ),
        purchase_date=_ms_to_datetime(data.get("purchaseDate")),
        expiration_date=expiration_date,
        environment=data.get("environment"),
        revoked=revocation_date is not None,
        revocation_date=revocation_date,
        signed_transaction_info=signed_transaction_info,
    )


async def verify_apple_transaction(
    *,
    product_id: str,
    transaction_id: str | None,
    signed_transaction_info: str | None,
) -> VerifiedAppleTransaction:
    if not transaction_id and not signed_transaction_info:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Transaction ID or signed transaction information is required.",
        )

    verified_transaction_id = transaction_id
    if not verified_transaction_id and _looks_like_jws(signed_transaction_info):
        client_payload = _decode_jws_payload(signed_transaction_info)
        raw_transaction_id = client_payload.get("transactionId")
        if raw_transaction_id:
            verified_transaction_id = str(raw_transaction_id)

    if not verified_transaction_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Apple transaction ID is required for server verification.",
        )

    if not re.fullmatch(r"[0-9]{1,128}", verified_transaction_id):
        raise HTTPException(status_code=422, detail="Invalid Apple transaction ID.")

    token = _app_store_jwt()
    endpoints = (
        [SANDBOX_ENDPOINT]
        if settings.APPLE_IAP_ENVIRONMENT.lower() == "sandbox"
        else [PRODUCTION_ENDPOINT, SANDBOX_ENDPOINT]
    )
    signed = None
    last_not_found = False
    for endpoint in endpoints:
        try:
            signed = await _fetch_transaction(verified_transaction_id, endpoint, token)
            break
        except KeyError:
            last_not_found = True
            continue
    if not signed and last_not_found:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Apple transaction was not found.",
        )

    # Only decode information obtained directly from Apple's authenticated HTTPS API.
    # Client JWS data above is used solely to locate the transaction, never to grant access.
    verified = _verified_from_signed_transaction(
        product_id=product_id, signed_transaction_info=signed or "",
    )
    if verified.transaction_id != verified_transaction_id:
        raise HTTPException(status_code=422, detail="Apple transaction ID does not match.")
    if verified.environment not in {"Production", "Sandbox"}:
        raise HTTPException(status_code=422, detail="Unknown Apple transaction environment.")
    return verified
