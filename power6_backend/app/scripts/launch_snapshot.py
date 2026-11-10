# SPDX-License-Identifier: AGPL-3.0-or-later
"""Fetch aggregate evidence; token stays in the environment, never in output."""
import argparse
import json
import os
from datetime import date, datetime, time, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlparse
from urllib.request import HTTPRedirectHandler, Request, build_opener


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Never forward an administrator bearer token to a redirected host.
        return None


MAX_REPORT_BYTES = 1024 * 1024


def fetch_snapshot(base_url, token, days, *, cohort_start=None, cohort_end=None):
    parsed = urlparse(base_url)
    if parsed.scheme != "https" and not (
        parsed.scheme == "http" and parsed.hostname in {"localhost", "127.0.0.1"}
    ):
        raise ValueError("Use HTTPS, or HTTP on localhost for local QA.")
    if parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise ValueError("Base URL must not contain credentials, query, or fragment.")
    if not token or not 1 <= days <= 120:
        raise ValueError("Provide POWER6_ADMIN_TOKEN and days between 1 and 120.")
    params = {"days": days}
    if (cohort_start is None) != (cohort_end is None):
        raise ValueError("Provide both cohort dates.")
    if cohort_start is not None:
        if cohort_start >= cohort_end:
            raise ValueError("Cohort end must follow cohort start.")
        params.update(cohort_start=cohort_start.isoformat(), cohort_end=cohort_end.isoformat())
    request = Request(
        base_url.rstrip("/") + "/events/launch?" + urlencode(params),
        headers={"Authorization": f"Bearer {token}", "Accept": "application/json"},
    )
    with build_opener(NoRedirect()).open(request, timeout=30) as response:
        raw = response.read(MAX_REPORT_BYTES + 1)
    if len(raw) > MAX_REPORT_BYTES:
        raise ValueError("Launch report exceeds the response limit.")
    report = json.loads(raw)
    if not isinstance(report, dict) or report.get("schema_version") != 1 or not isinstance(report.get("signup_cohort"), dict):
        raise ValueError("Unexpected launch report schema.")
    if cohort_start is not None:
        expected = {
            "mode": "fixed",
            "since": datetime.combine(cohort_start, time.min, tzinfo=timezone.utc).isoformat(),
            "until": datetime.combine(cohort_end, time.min, tzinfo=timezone.utc).isoformat(),
        }
        if report.get("cohort_window") != expected:
            raise ValueError("Server did not return the requested fixed cohort.")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--days", type=int, default=30)
    parser.add_argument("--cohort-start", type=date.fromisoformat)
    parser.add_argument("--cohort-end", type=date.fromisoformat)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        report = fetch_snapshot(args.base_url, os.getenv("POWER6_ADMIN_TOKEN"), args.days,
                                cohort_start=args.cohort_start, cohort_end=args.cohort_end)
    except (ValueError, HTTPError, URLError, TimeoutError):
        parser.exit(1, "Snapshot unavailable. Check API URL, deployment, admin token, and connectivity.\n")
    content = json.dumps(report, indent=2) + "\n"
    if args.output:
        args.output.write_text(content, encoding="utf-8")
    else:
        print(content, end="")


if __name__ == "__main__":
    main()
