# Launch measurement and organic growth runbook

## Release preflight

Backend first, mobile second. This sprint adds two tables (`event_receipts` and
`apple_purchase_claims`) through the existing metadata startup path. It adds no
columns to existing tables and does not backfill historical milestones. Confirm
the deployed database role can create the tables before relying on the report.

Apple activation now requires server verification even when the client sends a
StoreKit JWS. Set `APPLE_IAP_ISSUER_ID`, `APPLE_IAP_KEY_ID`,
`APPLE_IAP_PRIVATE_KEY`, and `APPLE_IAP_BUNDLE_ID` in the backend deployment.
Production lookup falls back to sandbox on not-found, retaining App Review support.
Missing configuration fails with 503 instead of granting an unverified entitlement.
Use a real sandbox account to verify purchase, restore, cancellation, revoked/expired
handling, and product loading before shipping mobile. This is an intentional
behavior change; local mocks do not establish production credential readiness.

The lookup follows Apple's [Get Transaction Info API](https://developer.apple.com/documentation/appstoreserverapi/get-transaction-info).
Client transaction data is only a lookup hint. Entitlement fields come from Apple's
authenticated HTTPS response; they are not accepted from the client payload.
Restoring the same transaction re-applies the verified entitlement without another
purchase event. A different account cannot claim an already-recorded transaction.
Account binding for previously unseen transaction IDs and full renewal/refund
lifecycle processing remain separate work.

Run the configured CI checks, deploy backend, inspect `/health`, then fetch the
admin launch snapshot. Build `0.1.4+21` in Codemagic and perform the device checklist
below before selecting/submitting it in App Store Connect. A Git push does not
confirm that Render, Firebase, or App Store distribution succeeded.

## Metrics and interpretation

`GET /events/summary?days=30` remains the legacy raw event diagnostic.
`GET /events/launch?days=30` is the new admin-only aggregate launch report
(1-120 days, rolling window ending at `as_of`, UTC). No task titles, email
addresses, usernames, user IDs, transaction IDs, or receipts are exported.

| Measure | Definition |
| --- | --- |
| Stage events / users | Event count and distinct users in the window; stages are independent reach, not an ordered conversion funnel |
| Signup cohort | Non-admin accounts created in the window, excluding the configured App Review username |
| First task / completion | Cohort users with a server-recorded task create / first completion in the window, divided by cohort size |
| Six planned | Cohort users who created at least six tasks in one UTC day after this deployment, divided by cohort size |
| Six completed | Cohort users who had six tasks completed in one UTC day, regardless of streak binding, divided by cohort size |
| Day-three retention | Cohort users active on signup UTC date + 3, divided by users whose entire day-three UTC day has elapsed |
| Activity | Dashboard view, task create, or task completion; repeated activity still counts as one retained user |
| Purchase verified | First recorded activation per Apple transaction, production only; distinct users also reported |

Task completion events count each task's first observed completion once, even
after undo/redo; the daily six-completion event counts a day once. They describe
historical actions, not current task state. Planning and completion use the
backend's existing UTC day, which can differ from the app's local calendar day.
Deleted accounts disappear from reporting. Old client action events remain in raw
summary history but are excluded from the launch report. Other test accounts must
be kept separate operationally; only admins and the configured review username
are automatically excluded.

An empty eligible cohort yields `percent: null`, not 0%. Sandbox activations stay
in raw diagnostics but never count as production purchases in the launch report.
An activation can be a renewal or newly observed restore, so it is not net-new
subscriber count, revenue, or a purchase-conversion rate. Stripe fulfillment and
verified events are now implemented for tracked checkouts; follow
`stripe_release.md` for configuration and real test-mode QA before using them.
Do not treat checkout starts as sales.
Installs, impressions, and store page conversion need separate App Store Connect
figures. Pre-deployment users and old mobile builds have incomplete event coverage.

## Capture evidence twice per week

Use a real administrator token in `POWER6_ADMIN_TOKEN` in the local environment;
do not paste it into committed commands or reports. From `power6_backend`:

```powershell
python -m app.scripts.launch_snapshot --base-url https://power6-backend.onrender.com --days 30 --output launch-snapshot.json
```

Keep production snapshots in private operating records, outside Git. Record the
API deployment commit/time, distributed mobile version, report window, screenshot
status, and store-side installs with every readout. Inspect both numerator and
denominator; do not infer a trend from two small cohorts or compare event totals
as though they were sequential conversions. No production snapshot was available
to this implementation run; no user or business results are asserted.

## Next organic experiments

These are prepared drafts and operating hypotheses. No messages/posts have been
sent, no testimonials collected, and no money spent by this implementation.

| Experiment | Draft/action | Evidence and next decision |
| --- | --- | --- |
| Six-task activation | Post: “Before opening your inbox, write the six things that would make today worthwhile. Start with one you can finish. Power6 keeps that short plan in view.” | Publish to one owned channel; record date, reach, clicks, store installs, cohort first-task and six-planned counts. If new users cannot name their next action, revise onboarding before buying traffic. |
| Completion and review | Post: “A useful daily review takes two questions: what got finished, and what still deserves tomorrow's attention? Try one week with a six-task plan.” | Ask for one point of confusion in the workflow; compare completion and mature day-three retention with the preceding cohort without claiming causality. |
| Paid value clarity | Post: “Plan six tasks for free. Plus adds streak and badge motivation; Pro adds timeline insights and export for reviewing your progress.” | Record subscription-screen users, checkout users, and verified production Apple users separately. Interview users who viewed plans but did not understand the benefits. |
| Founder feedback | Prepare 20-30 relevant contacts using the existing outreach tracker; send its feedback script only with explicit authorization. | Capture useful/confusing observations and 3-5 permissioned quotes. Do not publish names or testimonials without consent. |

Budget for these first experiments is $0. Keep any later Apple Search Ads test
within the existing $50 reserve and the $100 monthly ceiling, after release,
screenshots/copy, real purchase QA, and meaningful measurement evidence are ready.
This document does not authorize ad spending or external account posts.

## Validation and device checklist

Implementation validation on 2026-10-20:

| Check | Result |
| --- | --- |
| Backend pytest using an isolated SQLite database | 35 passed; existing SQLAlchemy and FastAPI deprecation warnings |
| Flutter tests | 8 passed, including signup profile hydration, lazy tabs, and telemetry lifecycle |
| Flutter analysis | `--no-fatal-infos` passed; 41 existing informational findings, no errors or warnings |
| Flutter release web build | Passed with both local and production API defines |
| Playwright browser smoke test | Signup, onboarding, dashboard, quick add, completion, review save, and subscription tab passed against local API |
| Persisted smoke-test events | One signup, onboarding start/complete, dashboard, task create/complete; subscription visit absent before opening tab and one afterward |

The initial smoke run exposed a signup profile/login bounce, phantom hidden-tab
events, and SQLite streak grouping failure. All three were corrected and covered
by regression tests; review/streak refresh succeeded in the repeated run.
PostgreSQL behavior and real store purchases still require deployed validation.

### 2026-10-21 Render startup correction

Render's failed deploy stopped at `create_engine(DATABASE_URL)` with
`ModuleNotFoundError: No module named 'psycopg'`. The unpinned SQLAlchemy dependency
resolved to 2.1, whose default driver for `postgresql://` URLs is Psycopg 3;
the requirements previously installed only `psycopg2-binary`. See the
[SQLAlchemy 2.1 migration note](https://docs.sqlalchemy.org/en/21/changelog/migration_21.html#default-postgresql-driver-changed-to-psycopg-psycopg-3).

Added `psycopg[binary]>=3.2,<4`, retaining Psycopg 2 for explicitly configured
legacy URLs. A clean Python 3.13 environment reproduced the exact import failure
before this addition and passed all 38 tests afterward, with SQLAlchemy 2.1.6.
New tests load the DBAPI for plain PostgreSQL, explicit Psycopg 3, and explicit
Psycopg 2 URLs without connecting to a database. CI now installs the same
requirements as Render, runs `pip check`, and includes these driver regressions.
These tests verify the reported startup blocker; they do not claim a live
PostgreSQL connection or a successful Render deployment.

Automated validation covers event filtering/access control, server action
milestones, daily limit, duplicate completion and purchase callbacks, account
deletion, Apple server lookup/mismatch/expiry/revocation, sandbox exclusion,
retention denominator boundaries, snapshot token handling, Flutter tier access,
unauthenticated launch, and telemetry disposal/failure.

Device/live release checks remain required: signup/login; six tasks and seventh
rejection; complete, undo, and save review; UTC/local rollover and streak behavior;
free/Plus/Pro/Elite gates; iOS sandbox purchase/restore and non-iOS checkout;
privacy/support pages; production launch snapshot; GitHub deployment result.
Neither real payments nor physical iOS distribution can be validated by mocked
backend tests or a web build.
