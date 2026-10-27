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
- Configure and test the new Stripe fulfillment path with Stripe test-mode
  fixtures before relying on non-iOS paid conversions. Follow `stripe_release.md`.
- Add subscription lifecycle/revocation notifications and account-bound purchase
  tokens; the activation report is not a full subscription/revenue ledger.
- Prioritize the next UI/retention work from observed activation failures and
  feedback. Keep Elite team features positioned as future value and defer MCP/AI
  expansion and paid ads until the current release and measurement are proven.

## 2026-10-27: ten Stripe conversion and entitlement passes

This batch advances the unfinished Stripe priority while physical iOS release QA,
authenticated production metrics, and external marketing publication remain
dependent on account/device access. The separate Power6 marketing chat's homepage
CTA edits are outside this batch and are preserved in their original checkout.

1. **Authenticated checkout:** bind checkout ownership to the bearer-token user;
   reject a mismatched legacy `user_id` and support clients that omit it.
2. **Plan configuration:** validate/normalize the six paid plan/interval choices,
   resolve current configured prices, and return safe configuration/upstream errors.
3. **Durable ownership:** persist server-created session IDs, original prices,
   mode, account, and pre-Stripe access in a dedicated checkout ledger.
4. **Webhook trust boundary:** verify the raw request signature, bound payload
   size, require signing configuration, and reject live/test mode mismatches.
5. **Authoritative fulfillment:** retrieve current Stripe session/subscription
   state; validate paid completion, ownership, customer, quantity, and price before
   granting access. Event metadata and success redirects cannot grant a tier.
6. **Atomic replay handling:** serialize per-account decisions and commit access,
   subscription projection, purchase receipt, and event together. Duplicate event
   IDs and distinct events for one session produce one initial purchase; failed
   commits roll back and permit retries.
7. **Subscription lifecycle:** reconcile updates, cancellation, pause/resume,
   recognized price changes, and delayed events against current API state. Keep
   original checkout evidence immutable after a plan change.
8. **Access and data protection:** retain baseline access, other active Stripe
   subscriptions, currently valid Apple purchases, and admin access. Delete local
   checkout/measurement records with the account; test grants require an explicit
   non-production opt-in.
9. **Provider measurement:** add production-only Apple/Stripe/unknown purchase
   breakdowns to the admin launch report, with no session/customer IDs exported.
10. **SDK and release validation:** bound the Stripe SDK to its tested major,
    use SDK resource conversion, add signed-webhook/rollback/lifecycle regression
    coverage, run required backend/Flutter checks, and document deployment QA.

Validation and configuration evidence are in [stripe_release.md](stripe_release.md).
This is a backend-only batch; mobile version remains `0.1.4+21`. No real payment,
test-mode provider request, marketing message, ad purchase, or store submission
was performed. Next: real Stripe test-mode QA and production cohort evidence;
Apple lifecycle/account-binding work remains pending.
