# Stripe fulfillment release: 2026-10-27

## What changed

The former webhook acknowledged checkout completion without changing access.
The checkout endpoint also accepted an unauthenticated account ID. Checkout now
requires authentication, persists server-owned session evidence, and fulfills
only paid completed subscriptions verified through Stripe's current API state.
The original checkout price remains fixed even when a subscription changes plans.

The design follows Stripe's [webhook verification](https://docs.stripe.com/webhooks)
and [subscription lifecycle guidance](https://docs.stripe.com/billing/subscriptions/webhooks).
We verify the raw request, then retrieve the session and subscription rather than
trusting stale event contents. A redirect, client-supplied tier, or signed event
metadata alone cannot grant access. Unknown/untracked sessions are acknowledged
without granting access; historical purchases are not automatically backfilled.

## Deployment and configuration

The existing startup metadata path creates `stripe_checkouts`. No existing table
columns are changed. Its account foreign key cascades on deletion; a nullable
subscription projection link permits the existing account-deletion flow.
The deployment database role must be able to create this table before checkout
traffic is accepted. Stripe SDK is constrained to `>=16,<17`; API resources are
converted through `to_dict()` before dictionary access.

Required environment configuration:

- `STRIPE_SECRET_KEY`: the appropriate `sk_live_`/`rk_live_` key for production,
  or `sk_test_`/`rk_test_` in a separate test deployment.
- `STRIPE_WEBHOOK_SECRET`: signing secret for the exact registered endpoint.
- `STRIPE_PRICE_ID_{PLUS,PRO,ELITE}_{MONTHLY,YEARLY}`: six configured recurring
  prices, one item and quantity one. Only configured plan changes are accepted.
- `STRIPE_SUCCESS_URL` and `STRIPE_CANCEL_URL`: the existing application redirects.
- `STRIPE_ENABLE_TEST_ENTITLEMENTS`: false by default. Enable only in an isolated
  test deployment when exercising test-mode entitlements. Do not enable in production.

Use one canonical snapshot-event webhook URL, normally
`https://power6-backend.onrender.com/stripe/webhook`. `/api/stripe/webhook` remains
an alias. Subscribe to:

- `checkout.session.completed`
- `checkout.session.async_payment_succeeded`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `customer.subscription.paused`
- `customer.subscription.resumed`

Keep secrets in deployment settings. No key values or raw payment payloads are
written to analytics or error responses. Missing configuration returns 503,
invalid signatures/modes 400, unknown plan/ownership/price mismatches 422, and
Stripe API failures 502. Retryable failures do not commit a grant. Configure
alerts for repeated non-2xx webhook responses and fix configuration/price issues
before retrying events. Do not register both URL aliases unnecessarily.

## Entitlement and reporting rules

- First paid completed checkout with an active subscription grants its verified
  tier and emits one `purchase_verified` event. Replays re-fetch current state,
  but never create another subscription projection or initial purchase event.
- Lifecycle events re-fetch current subscription state under the account lock.
  `active` grants access; `past_due`, `unpaid`, `paused`, `incomplete`, and cancelled
  states do not grant Stripe access. A cancel-at-period-end subscription that is
  still active retains access until Stripe changes its status. No grace period
  or free trial is configured by this checkout flow.
- Reconciliation selects the highest of the original pre-Stripe access, other
  active tracked Stripe checkouts, and currently valid stored Apple purchases.
  Admin access is preserved. This protects existing access; the baseline is not
  a replacement for a complete cross-provider entitlement ledger. Later manual
  grants and Apple lifecycle revocation/expiration still require that future work.
- Account deletion removes local ledger/event rows. It does not call Stripe to
  cancel billing. Account deletion and billing cancellation are separate actions;
  a customer portal/cancellation UX remains a release follow-up.
- The admin report adds `verified_purchases_by_provider`, with `apple`, `stripe`,
  and `unknown` rows. Production-only counts exclude sandbox/test entitlements.
  Stripe events count initial verified tracked checkouts, not invoice renewals,
  revenue, refunds, or net-new customers. Historical untracked sessions need a
  separate ownership reconciliation, not a client metadata-based backfill.

## Validation and required external QA

Local validation: full backend suite passed (62 tests); `pip check` reported no
broken requirements; all 8 Flutter tests passed; Flutter analysis passed with
`--no-fatal-infos` and the same 41 existing informational findings. The original
SQLite API integration tests continue to cover signup, six-task limits,
completion/streak refresh, account deletion, and tier-gated analytics/export.
Real PostgreSQL transactions and live Stripe payment delivery remain external QA.

Automated regression coverage uses real HMAC-signed payloads checked by the
installed Stripe SDK, with session/subscription API responses mocked. It exercises
auth and spoofing, plan configuration, signature/mode isolation, paid/price/customer
checks, SDK objects, duplicate events, failed commits/retries, delayed events,
plan changes, multiple subscriptions, Apple/baseline preservation, local account
deletion, and aggregate provider reporting. No Stripe account/API was contacted.

Before relying on paid conversions, an operator must configure the endpoint and
prices in Stripe, run Checkout with test cards in a separate deployment, confirm
purchase/renewal/cancellation behavior and user-profile refresh, and then validate
the production webhook configuration. No real purchase or production snapshot was
available for this scheduled run. Physical iOS/App Store QA remains separate.
