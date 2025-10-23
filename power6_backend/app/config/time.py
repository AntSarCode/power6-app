"""Centralized time and timezone helpers for consistent streak calculations.

All time-based logic across the app (tasks, streaks, schedules) should use these helpers.
Choose either UTC or local time depending on your deployment policy.
"""

from datetime import datetime, date, timezone
import zoneinfo  # built-in since Python 3.9

# --- Configuration -----------------------------------------------------------
try:
    APP_TIMEZONE = zoneinfo.ZoneInfo("America/New_York")
except Exception:
    APP_TIMEZONE = timezone.utc

# --- Helpers -----------------------------------------------------------------
def now_tz() -> datetime:
    """Return the current time in the app's timezone (aware datetime)."""
    return datetime.now(APP_TIMEZONE)


def today_tz() -> date:
    """Return today's date in the app's timezone."""
    return now_tz().date()


def to_app_tz(dt: datetime) -> datetime:
    """Convert any datetime to the app's timezone."""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(APP_TIMEZONE)


def to_utc(dt: datetime) -> datetime:
    """Convert datetime to UTC for storage or comparison."""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def same_day(a: datetime, b: datetime) -> bool:
    """Check if two datetimes fall on the same calendar day in app timezone."""
    a_local = to_app_tz(a)
    b_local = to_app_tz(b)
    return (a_local.year == b_local.year) and (a_local.month == b_local.month) and (a_local.day == b_local.day)


# --- Example Usage -----------------------------------------------------------
if __name__ == "__main__":
    print("Now (app tz):", now_tz())
    print("Today (app tz):", today_tz())
    print("UTC conversion check:", to_utc(datetime.now()))