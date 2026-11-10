# SPDX-License-Identifier: AGPL-3.0-or-later
"""Compare two fixed-cohort captures locally, without network access."""
import argparse
import json
from datetime import datetime, timedelta
from pathlib import Path

from app.scripts.launch_snapshot import MAX_REPORT_BYTES


METRICS = ("first_task", "six_tasks_planned", "first_completion", "six_tasks_completed")


def _utc(value):
    result = datetime.fromisoformat(value)
    if result.utcoffset() != timedelta(0):
        raise ValueError("Expected UTC timestamps.")
    return result


def _window(report):
    window = report["cohort_window"]
    if report["schema_version"] != 1 or report["timezone"] != "UTC" or window["mode"] != "fixed":
        raise ValueError("Use fixed UTC signup snapshots from the launch report.")
    start, end, observed = map(_utc, (window["since"], window["until"], report["as_of"]))
    if not start < end <= observed or any((dt.hour, dt.minute, dt.second, dt.microsecond) != (0, 0, 0, 0)
                                          for dt in (start, end)):
        raise ValueError("Invalid completed signup window.")
    return start, end, observed


def _metric(cohort, key):
    group, _, name = key.rpartition(".")
    row = cohort[group][name] if group else cohort[name]
    population = cohort["users"]
    users, eligible = row["users"], row["eligible_users"]
    if any(type(value) is not int for value in (users, eligible, population)) or not 0 <= users <= eligible <= population:
        raise ValueError("Invalid cohort numerator or denominator.")
    return {"users": users, "eligible_users": eligible,
            "percent": round(100 * users / eligible, 1) if eligible else None}


def compare(previous, current):
    old_start, old_end, old_as_of = _window(previous)
    new_start, new_end, new_as_of = _window(current)
    same_window = (old_start, old_end) == (new_start, new_end)
    if new_as_of <= old_as_of or previous["population"] != current["population"]:
        raise ValueError("Compare chronological captures with the same population definition.")
    if not same_window and (old_end > new_start or old_end - old_start != new_end - new_start):
        raise ValueError("Use the same window or equal-length non-overlapping signup windows.")
    rows = {}
    old_cohort, new_cohort = previous["signup_cohort"], current["signup_cohort"]
    for key in (*METRICS, "day_1_retention", "day_3_retention", "day_7_retention",
                *(f"first_24_hours.{name}" for name in METRICS)):
        old, new = _metric(old_cohort, key), _metric(new_cohort, key)
        maturity = {"day_1_retention": 1, "day_3_retention": 3, "day_7_retention": 7}.get(key, 1)
        comparable = (key.startswith("day_") or key.startswith("first_24_hours.")) and all(
            observed >= end + timedelta(days=maturity)
            for end, observed in ((old_end, old_as_of), (new_end, new_as_of))
        ) and old["eligible_users"] == old_cohort["users"] and new["eligible_users"] == new_cohort["users"]
        rows[key] = {
            "previous": old, "current": new,
            "change_percentage_points": round(new["percent"] - old["percent"], 1)
            if comparable and old["percent"] is not None and new["percent"] is not None else None,
        }
    return {
        "comparison": "same_signup_window" if same_window else "separate_signup_windows",
        "previous": {"since": old_start.isoformat(), "until": old_end.isoformat(),
                     "as_of": old_as_of.isoformat(), "signup_users": old_cohort["users"]},
        "current": {"since": new_start.isoformat(), "until": new_end.isoformat(),
                    "as_of": new_as_of.isoformat(), "signup_users": new_cohort["users"]},
        "metrics": rows,
    }


def _read(path):
    with path.open("rb") as stream:
        data = stream.read(MAX_REPORT_BYTES + 1)
    if len(data) > MAX_REPORT_BYTES:
        raise ValueError("Snapshot exceeds the input limit.")
    return json.loads(data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("previous", type=Path)
    parser.add_argument("current", type=Path)
    args = parser.parse_args()
    try:
        result = compare(_read(args.previous), _read(args.current))
    except (OSError, ValueError, KeyError, TypeError):
        parser.exit(1, "Comparison unavailable. Check the snapshot schema, dates, and population.\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
