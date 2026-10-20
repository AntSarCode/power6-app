# Power6 development roadmap

## Direction and working rules

Continue the July 2026 launch roadmap: a polished first minute, a clear six-task
habit, visible Plus/Pro value, and repeatable growth learning on $0-$100/month.
The latest roadmap chat selected **Launch Measurement + Organic Growth** after
`0.1.3+20`. It deferred a large AI/MCP feature and paid acquisition until the
existing workflow and measurement are proven.

Each scheduled run should inspect this file, the current code, and prior Power6
chats; choose ten coherent passes from the next unfinished priorities; implement
and validate them; update this log; then commit and push to the existing
`https://github.com/AntSarCode/power6-app` repository's `main` branch. Preserve
unrelated edits, never force-push, and record external prerequisites separately
from completed code. Do not invent product metrics or mark live release checks
complete from unit tests.

Source context: Power6 roadmap chat `019f4b29-f092-7992-9b81-255ba6f04452`,
including the approved 30-Day Launch Push plan and the subsequent measurement,
conversion, and growth steps. The earlier App Review chat
`019ed65c-2b43-7070-a30c-0d595aebe751` confirms the actual short Apple product IDs
and `main`/Codemagic release path.

## 2026-10-20: ten implementation passes

1. **Event integrity and privacy:** reject unknown/spoofed milestone names,
   restrict property values to known categories/counters, stop retaining user
   agents, and silently accept legacy action events without recording duplicates.
2. **Signup and planning activation:** record successful signup and task creation
   on the backend, plus one six-task planning milestone per UTC day.
3. **Completion evidence:** cover PATCH, PUT, toggle, and create-completed paths;
   count first completion per task and one six-completion milestone per UTC day.
   Correct SQLite streak date grouping discovered in browser QA, retaining UTC
   grouping on PostgreSQL; verify six-task completion and streak refresh together.
4. **Onboarding delivery:** record the Start planning action and let bounded
   telemetry requests finish across screen disposal. Remove redundant client
   signup/task events. Hydrate the new user profile before onboarding so hidden
   tier guards cannot bounce new accounts to login. Initialize navigation tabs
   only when first visited, avoiding phantom paywall visits and hidden API calls.
5. **Apple verification prerequisite:** remove the client-payload trust shortcut;
   retrieve the transaction from Apple's authenticated server API and validate
   bundle, product, ID, expiration, and revocation before activation.
6. **Purchase measurement and restores:** claim transaction ownership atomically,
   prevent duplicate subscriptions/events on replay, restore verified entitlement,
   and record production/sandbox categories without receipts in analytics. Account
   deletion removes new measurement/claim records and Apple transaction rows.
7. **Launch cohort report:** add admin-only `/events/launch`, independent stage
   reach, signup activation denominators, and mature UTC day-three retention.
   Exclude admins, the configured review account, legacy client action events,
   future events, and sandbox purchases from launch results.
8. **Repeatable evidence capture:** add a snapshot CLI with environment-only admin
   token, HTTPS enforcement, redirect blocking, and aggregate-only JSON output.
9. **Validation before web deployment:** reusable backend/Flutter CI gates the
   existing Firebase deployment; PRs run the same checks. Pin the Flutter SDK to
   the validated version and cover the new contracts with regression tests.
10. **Growth/release handoff:** preserve this roadmap, define metrics and rollout
    prerequisites, prepare the next organic experiment cards, and advance the
    mobile build to `0.1.4+21` for the existing Codemagic release process.

Validation results and release limits are recorded in
[the measurement runbook](launch_measurement.md). These passes prepare the
measurement sprint; they do not claim production deployment, real user retention,
posted marketing, testimonials, or an App Store submission.

## Next priorities

- Deploy the backend after configuring Apple Server API credentials; validate a
  real sandbox purchase/restore and the existing free/Plus/Pro/Elite gates on a
  physical iOS device. Build/release `0.1.4+21` with Codemagic/App Store Connect.
- Capture the first authenticated production snapshot and store-side impressions,
  installs, and screenshot/copy status; collect a second snapshot after mature
  day-three cohorts exist. Distinguish pre/post deployment and app versions.
- Execute and record the organic/outreach experiments in the measurement runbook;
  obtain explicit permission for sending messages or posting to external accounts.
- Complete Stripe webhook entitlement fulfillment and verified purchase telemetry
  before using non-iOS paid conversions in decisions. The existing webhook is a
  placeholder; checkout starts are purchase intent only.
- Add subscription lifecycle/revocation notifications and account-bound purchase
  tokens; the activation report is not a full subscription/revenue ledger.
- Prioritize the next UI/retention work from observed activation failures and
  feedback. Keep Elite team features positioned as future value and defer MCP/AI
  expansion and paid ads until the current release and measurement are proven.
