import io
import json
from datetime import date

import pytest

from app.scripts import launch_snapshot as snapshot
from app.scripts.compare_launch_snapshots import METRICS, compare


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


def fixed(as_of, *, start="2026-10-01", end="2026-10-03", users=2, reached=1):
    metric = {"users": reached, "eligible_users": users, "percent": 999}
    return {
        "schema_version": 1, "timezone": "UTC", "population": "test population",
        "as_of": f"{as_of}T12:00:00+00:00",
        "cohort_window": {"mode": "fixed", "since": f"{start}T00:00:00+00:00",
                          "until": f"{end}T00:00:00+00:00"},
        "signup_cohort": {
            "users": users, **dict.fromkeys(METRICS, metric),
            **{f"day_{day}_retention": metric for day in (1, 3, 7)},
            "first_24_hours": dict.fromkeys(METRICS, metric),
        },
    }


def test_snapshot_validates_fixed_window_echo(monkeypatch):
    class Opener:
        def open(self, request, timeout):
            assert request.full_url.endswith("days=7&cohort_start=2026-10-01&cohort_end=2026-10-03")
            return io.BytesIO(json.dumps(fixed("2026-10-04")).encode())
    monkeypatch.setattr(snapshot, "build_opener", lambda *args: Opener())
    assert snapshot.fetch_snapshot("https://example.com", "token", 7,
                                   cohort_start=date(2026, 10, 1),
                                   cohort_end=date(2026, 10, 3))["cohort_window"]["mode"] == "fixed"


def test_comparison_recalculates_percentages_and_withholds_immature_deltas():
    old, new = fixed("2026-10-05"), fixed("2026-10-12", reached=2)
    result = compare(old, new)
    assert result["comparison"] == "same_signup_window"
    metrics = result["metrics"]
    assert metrics["first_24_hours.first_task"]["change_percentage_points"] == 50.0
    assert metrics["day_7_retention"]["change_percentage_points"] is None
    assert metrics["first_task"]["change_percentage_points"] is None


def test_comparison_requires_compatible_windows_and_counts():
    old = fixed("2026-10-12")
    new = fixed("2026-10-14", start="2026-10-02", end="2026-10-04")
    with pytest.raises(ValueError):
        compare(old, new)
    with pytest.raises(ValueError):
        compare(old, fixed("2026-10-14", reached=3))
    result = compare(old, fixed("2026-10-14", start="2026-10-04", end="2026-10-06"))
    assert result["comparison"] == "separate_signup_windows"
