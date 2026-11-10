# SPDX-License-Identifier: AGPL-3.0-or-later
"""Aggregate launch evidence, with explicit cohort denominators and UTC days."""
import os
from collections import defaultdict
from datetime import datetime, time, timedelta, timezone

from sqlalchemy import func

from app.models.models import User, UserEvent
from app.services.event_service import SERVER_EVENTS

STAGES = [
    "signup_completed", "onboarding_started", "onboarding_completed",
    "dashboard_viewed", "task_created", "six_tasks_planned", "task_completed",
    "six_tasks_completed", "subscription_screen_viewed", "checkout_started",
    "purchase_verified",
]
ACTIVITY = {"dashboard_viewed", "task_created", "task_completed"}


def utc(value):
    return value.replace(tzinfo=timezone.utc) if value.tzinfo is None else value.astimezone(timezone.utc)


def metric(numerator, denominator):
    return {
        "users": numerator, "eligible_users": denominator,
        "percent": round(100 * numerator / denominator, 1) if denominator else None,
    }


def build_launch_report(db, *, days=30, now=None, cohort_start=None, cohort_end=None):
    now = utc(now or datetime.now(timezone.utc))
    since = now - timedelta(days=days)
    if (cohort_start is None) != (cohort_end is None):
        raise ValueError("Provide both cohort dates.")
    cohort_since, cohort_until = since, now
    if cohort_start is not None:
        if not now.date() - timedelta(days=120) <= cohort_start < cohort_end <= now.date():
            raise ValueError("Use a completed UTC signup window within the past 120 days.")
        cohort_since = datetime.combine(cohort_start, time.min, tzinfo=timezone.utc)
        cohort_until = datetime.combine(cohort_end, time.min, tzinfo=timezone.utc)
    # These criteria apply to every query in this report, including the cohort.
    population = (
        User.is_admin.is_(False),
        func.lower(User.username) != os.getenv("POWER6_REVIEW_USERNAME", "app_review_expired").lower(),
    )
    cohort_filter = (
        *population, User.created_at >= cohort_since,
        User.created_at < cohort_until if cohort_end else User.created_at <= now,
    )
    cohort = dict(db.query(User.id, User.created_at).filter(*cohort_filter).all())
    # Aggregate reach separately from signup-cohort activity.
    event_day = (func.date(func.timezone("UTC", UserEvent.created_at))
                 if db.get_bind().dialect.name == "postgresql" else func.date(UserEvent.created_at))
    platform = UserEvent.properties["platform"].as_string()
    rows = db.query(
        UserEvent.user_id, UserEvent.name,
        func.count(UserEvent.id), platform,
    ).join(User, User.id == UserEvent.user_id).filter(
        *population, UserEvent.created_at >= since, UserEvent.created_at <= now,
        UserEvent.name.in_(STAGES),
        ((UserEvent.name.notin_(SERVER_EVENTS)) | (UserEvent.source == "server")),
        # Sandbox activations remain visible in /summary but never count as sales.
        ((UserEvent.name != "purchase_verified") |
         (UserEvent.properties["environment"].as_string() == "production")),
    ).group_by(UserEvent.user_id, UserEvent.name, platform).all()
    reached = defaultdict(set)
    totals = defaultdict(int)
    activity_days = defaultdict(set)
    purchase_users, purchase_events = defaultdict(set), defaultdict(int)
    for uid, name, count, event_platform in rows:
        reached[name].add(uid)
        totals[name] += count
        if name == "purchase_verified":
            provider = "stripe" if event_platform == "web" else "apple" if event_platform == "ios" else "unknown"
            purchase_users[provider].add(uid)
            purchase_events[provider] += count
    activation_events = {
        "first_task": "task_created", "six_tasks_planned": "six_tasks_planned",
        "first_completion": "task_completed", "six_tasks_completed": "six_tasks_completed",
    }
    cohort_reached = defaultdict(set)
    first_day_reached = defaultdict(set)
    mature_first_day = {uid for uid, created in cohort.items()
                        if utc(created) + timedelta(days=1) <= now}
    cohort_rows = db.query(
        UserEvent.user_id, UserEvent.name, event_day, func.min(UserEvent.created_at),
    ).join(User, User.id == UserEvent.user_id).filter(
        *cohort_filter, UserEvent.created_at >= User.created_at, UserEvent.created_at <= now,
        UserEvent.name.in_(ACTIVITY | set(activation_events.values())),
        ((UserEvent.name.notin_(SERVER_EVENTS)) | (UserEvent.source == "server")),
    ).group_by(UserEvent.user_id, UserEvent.name, event_day).all()
    for uid, name, day, first in cohort_rows:
        if uid not in cohort:
            continue
        cohort_reached[name].add(uid)
        if uid in mature_first_day and utc(first) < utc(cohort[uid]) + timedelta(days=1):
            first_day_reached[name].add(uid)
        if name in ACTIVITY:
            activity_days[uid].add(str(day))

    def retention(offset):
        eligible = {uid for uid, created in cohort.items()
                    if utc(created).date() + timedelta(days=offset + 1) <= now.date()}
        retained = sum(
            (utc(cohort[uid]).date() + timedelta(days=offset)).isoformat() in activity_days[uid]
            for uid in eligible
        )
        return metric(retained, len(eligible))
    return {
        "schema_version": 1, "window_days": days,
        "since": since.isoformat(), "as_of": now.isoformat(), "timezone": "UTC",
        "cohort_window": {
            "mode": "fixed" if cohort_start else "rolling",
            "since": cohort_since.isoformat(), "until": cohort_until.isoformat(),
        },
        "population": "Non-admin accounts excluding the configured App Review username",
        "stages": [{"name": name, "events": totals[name], "users": len(reached[name])}
                   for name in STAGES],
        "verified_purchases_by_provider": [
            {"provider": provider, "events": purchase_events[provider], "users": len(purchase_users[provider])}
            for provider in ("apple", "stripe", "unknown")
        ],
        "signup_cohort": {
            "users": len(cohort),
            **{key: metric(len(cohort_reached[name]), len(cohort))
               for key, name in activation_events.items()},
            "first_24_hours": {
                key: metric(len(first_day_reached[name]), len(mature_first_day))
                for key, name in activation_events.items()
            },
            **{f"day_{day}_retention": retention(day) for day in (1, 3, 7)},
        },
        "limitations": [
            "Stages are independent reach counts, not an ordered conversion funnel.",
            "Retention uses the signup UTC date plus the stated offset; only fully elapsed days are eligible.",
            "First 24 hours uses elapsed time since signup and excludes accounts younger than 24 hours.",
            "Fixed signup dates change cohort metrics only; stage and purchase counts use the rolling report window.",
            "Server task milestones and verified purchases start at deployment; no backfill.",
            "Purchases are production Apple activations or first verified Stripe checkouts; not revenue or net-new subscribers.",
            "Apple chain deduplication starts with the account-binding deployment; earlier Apple activation counts may include renewals.",
            "Installs and store impressions require separate App Store Connect figures.",
        ],
    }
