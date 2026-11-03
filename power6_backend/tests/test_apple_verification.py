import asyncio
from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException

from app.services import apple_iap_service as service
from test_iap_activate import _unsigned_jws


@pytest.fixture
def apple(monkeypatch):
    monkeypatch.setattr(service.settings, "APPLE_IAP_BUNDLE_ID", "app.power6.mobile")
    monkeypatch.setattr(service.settings, "APPLE_IAP_ENVIRONMENT", "Production")
    monkeypatch.setattr(service, "_app_store_jwt", lambda: "server-token")
    return {
        "bundleId": "app.power6.mobile", "productId": "power6_proM", "transactionId": "1234",
        "expiresDate": int((datetime.now(timezone.utc) + timedelta(days=30)).timestamp() * 1000),
        "environment": "Production",
    }


def verify(payload):
    return asyncio.run(service.verify_apple_transaction(
        product_id="power6_proM", transaction_id="1234", signed_transaction_info=_unsigned_jws(payload),
    ))


def test_server_lookup_overrides_forged_client_payload(apple, monkeypatch):
    async def fetch(transaction_id, endpoint, token):
        assert transaction_id == "1234" and token == "server-token"
        return _unsigned_jws({**apple, "productId": "power6_plusM"})
    monkeypatch.setattr(service, "_fetch_transaction", fetch)
    with pytest.raises(HTTPException) as error:
        verify(apple)
    assert error.value.status_code == 422


@pytest.mark.parametrize("change,code", [
    ({"bundleId": "wrong.app"}, 422), ({"transactionId": "9999"}, 422),
    ({"expiresDate": 1}, 402), ({"expiresDate": None}, 402),
    ({"revocationDate": 1}, 402), ({"environment": "unknown"}, 422),
    ({"revocationDate": "invalid"}, 422), ({"appAccountToken": "wrong"}, 422),
    ({"originalTransactionId": "../path"}, 422),
    ({"isUpgraded": True}, 402),
])
def test_invalid_server_entitlements_are_rejected(apple, monkeypatch, change, code):
    async def fetch(*args):
        return _unsigned_jws({**apple, **change})
    monkeypatch.setattr(service, "_fetch_transaction", fetch)
    with pytest.raises(HTTPException) as error:
        verify(apple)
    assert error.value.status_code == code


def test_production_not_found_falls_back_to_sandbox(apple, monkeypatch):
    endpoints = []
    async def fetch(transaction_id, endpoint, token):
        endpoints.append(endpoint)
        if endpoint == service.PRODUCTION_ENDPOINT:
            raise KeyError("not found")
        return _unsigned_jws({**apple, "environment": "Sandbox"})
    monkeypatch.setattr(service, "_fetch_transaction", fetch)
    assert verify(apple).environment == "Sandbox"
    assert endpoints == [service.PRODUCTION_ENDPOINT, service.SANDBOX_ENDPOINT]


def test_missing_transaction_is_not_activated(apple, monkeypatch):
    async def fetch(*args):
        raise KeyError("not found")
    monkeypatch.setattr(service, "_fetch_transaction", fetch)
    with pytest.raises(HTTPException) as error:
        verify(apple)
    assert error.value.status_code == 404


def test_provider_account_token_overrides_client_token(apple, monkeypatch):
    from uuid import uuid4
    provider_token = str(uuid4())
    async def fetch(*args):
        return _unsigned_jws({**apple, "appAccountToken": provider_token.upper()})
    monkeypatch.setattr(service, "_fetch_transaction", fetch)
    assert verify({**apple, "appAccountToken": str(uuid4())}).app_account_token == provider_token


@pytest.mark.parametrize("body", [None, [], {}, {"signedTransactionInfo": 42},
                                  {"signedTransactionInfo": "not-jws"}])
def test_malformed_provider_response_returns_safe_502(monkeypatch, body):
    import httpx
    class Client:
        def __init__(self, **kwargs): pass
        async def __aenter__(self): return self
        async def __aexit__(self, *args): pass
        async def get(self, *args, **kwargs):
            return httpx.Response(200, json=body)
    monkeypatch.setattr(service.httpx, "AsyncClient", Client)
    with pytest.raises(HTTPException) as error:
        asyncio.run(service._fetch_transaction("1234", service.PRODUCTION_ENDPOINT, "private-token"))
    assert error.value.status_code == 502
    assert "private-token" not in error.value.detail
