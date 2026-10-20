import io
import json

import pytest

from app.scripts import launch_snapshot as snapshot


def test_fetches_aggregate_snapshot_without_exposing_token(monkeypatch):
    class Opener:
        def open(self, request, timeout):
            assert request.full_url == "https://example.com/events/launch?days=7"
            assert request.get_header("Authorization") == "Bearer test-token"
            assert timeout == 30
            return io.BytesIO(json.dumps({"schema_version": 1, "signup_cohort": {}}).encode())
    monkeypatch.setattr(snapshot, "build_opener", lambda *args: Opener())
    report = snapshot.fetch_snapshot("https://example.com", "test-token", 7)
    assert "test-token" not in str(report)


@pytest.mark.parametrize("url", ["http://example.com", "https://user:secret@example.com",
                                     "https://example.com/?token=secret"])
def test_refuses_unsafe_snapshot_destinations(url):
    with pytest.raises(ValueError):
        snapshot.fetch_snapshot(url, "test-token", 7)


def test_snapshot_does_not_forward_admin_token_on_redirect():
    assert snapshot.NoRedirect().redirect_request(None, None, 302, "", {}, "https://other.com") is None
