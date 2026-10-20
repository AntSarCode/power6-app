# SPDX-License-Identifier: AGPL-3.0-or-later
"""Aggregate launch evidence, with explicit cohort denominators and UTC days."""
import os
from collections import defaultdict
from datetime import datetime, timedelta, timezone

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


def build_launch_report(db, *, days=30, now=None):
    now = utc(now or datetime.now(timezone.utc))
    since = now - timedelta(days=days)
    # These criteria apply to every query in this report, including the cohort.
    population = (
        User.is_admin.is_(False),
        func.lower(User.username) != os.getenv("POWER6_REVIEW_USERNAME", "app_review_expired").lower(),
    )
    cohort = dict(db.query(User.id, User.created_at).filter(
        *population, User.created_at >= since, User.created_at <= now,
    ).all())
    # Group in SQL; memory is bounded by users x event names x window days.
    event_day = (func.date(func.timezone("UTC", UserEvent.created_at))
                 if db.get_bind().dialect.name == "postgresql" else func.date(UserEvent.created_at))
    rows = db.query(
        UserEvent.user_id, UserEvent.name, event_day,
        func.count(UserEvent.id), func.min(UserEvent.created_at),
    ).join(User, User.id == UserEvent.user_id).filter(
        *population, UserEvent.created_at >= since, UserEvent.created_at <= now,
        ((UserEvent.name.notin_(SERVER_EVENTS)) | (UserEvent.source == "server")),
        # Sandbox activations remain visible in /summary but never count as sales.
        ((UserEvent.name != "purchase_verified") |
         (UserEvent.properties["environment"].as_string() == "production")),
    ).group_by(UserEvent.user_id, UserEvent.name, event_day).all()
    reached = defaultdict(set)
    cohort_reached = defaultdict(set)
    totals = defaultdict(int)
    activity_days = defaultdict(set)
    for uid, name, day, count, first in rows:
        reached[name].add(uid)
        totals[name] += count
        if uid in cohort and utc(first) >= utc(cohort[uid]):
            cohort_reached[name].add(uid)
        if name in ACTIVITY:
            activity_days[uid].add(str(day))
    eligible = {uid for uid, created in cohort.items()
                if utc(created).date() + timedelta(days=4) <= now.date()}
    retained = {uid for uid in eligible
                if (utc(cohort[uid]).date() + timedelta(days=3)).isoformat()
                in activity_days[uid]}
    return {
        "schema_version": 1, "window_days": days,
        "since": since.isoformat(), "as_of": now.isoformat(), "timezone": "UTC",
        "population": "Non-admin accounts excluding the configured App Review username",
        "stages": [{"name": name, "events": totals[name], "users": len(reached[name])}
                   for name in STAGES],
        "signup_cohort": {
            "users": len(cohort),
            "first_task": metric(len(cohort_reached["task_created"]), len(cohort)),
            "six_tasks_planned": metric(len(cohort_reached["six_tasks_planned"]), len(cohort)),
            "first_completion": metric(len(cohort_reached["task_completed"]), len(cohort)),
            "six_tasks_completed": metric(len(cohort_reached["six_tasks_completed"]), len(cohort)),
            "day_3_retention": metric(len(retained), len(eligible)),
        },
        "limitations": [
            "Stages are independent reach counts, not an ordered conversion funnel.",
            "Day 3 is activity on signup UTC date + 3; only fully elapsed days are eligible.",
            "Server task milestones and verified purchases start at deployment; no backfill.",
            "Purchases are production Apple activations, not revenue or net-new subscribers; Stripe is unmeasured.",
            "Installs and store impressions require separate App Store Connect figures.",
        ],
    }
