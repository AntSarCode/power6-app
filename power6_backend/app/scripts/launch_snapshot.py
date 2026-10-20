# SPDX-License-Identifier: AGPL-3.0-or-later
"""Fetch aggregate evidence; token stays in the environment, never in output."""
import argparse
import json
import os
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlparse
from urllib.request import HTTPRedirectHandler, Request, build_opener


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Never forward an administrator bearer token to a redirected host.
        return None


def fetch_snapshot(base_url, token, days):
    parsed = urlparse(base_url)
    if parsed.scheme != "https" and not (
        parsed.scheme == "http" and parsed.hostname in {"localhost", "127.0.0.1"}
    ):
        raise ValueError("Use HTTPS, or HTTP on localhost for local QA.")
    if parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise ValueError("Base URL must not contain credentials, query, or fragment.")
    if not token or not 1 <= days <= 120:
        raise ValueError("Provide POWER6_ADMIN_TOKEN and days between 1 and 120.")
    request = Request(
        base_url.rstrip("/") + "/events/launch?" + urlencode({"days": days}),
        headers={"Authorization": f"Bearer {token}", "Accept": "application/json"},
    )
    with build_opener(NoRedirect()).open(request, timeout=30) as response:
        report = json.load(response)
    if report.get("schema_version") != 1 or "signup_cohort" not in report:
        raise ValueError("Unexpected launch report schema.")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--days", type=int, default=30)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    try:
        report = fetch_snapshot(args.base_url, os.getenv("POWER6_ADMIN_TOKEN"), args.days)
    except (ValueError, HTTPError, URLError, TimeoutError):
        parser.exit(1, "Snapshot unavailable. Check API URL, deployment, admin token, and connectivity.\n")
    content = json.dumps(report, indent=2) + "\n"
    if args.output:
        args.output.write_text(content, encoding="utf-8")
    else:
        print(content, end="")


if __name__ == "__main__":
    main()
