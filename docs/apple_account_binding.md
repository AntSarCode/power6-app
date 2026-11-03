# Apple purchase ownership and verified activation

## November 3, 2026 release: 0.1.5 (23)

The purchase screen previously granted a paid tier locally when server activation
failed, including HTTP errors and timeouts. That also allowed the StoreKit
transaction to be completed before the server had verified ownership. This release
removes that fallback: only a successful response for the signed-in account can
update the displayed plan, and only then may StoreKit completion run. Failed
verification leaves the purchase available for retry through Restore Purchases.
Apple can refund transactions that are not completed in time, so verification
configuration and real-device QA are release prerequisites.

## Account binding

`POST /iap/apple/account-token` (also under `/api`) requires the normal bearer
token and returns one stable, random `app_account_token` UUID for that account.
It accepts no caller-selected user ID. The new mobile build requests this UUID
before opening the purchase sheet, then passes it as `PurchaseParam.applicationUserName`.
The installed StoreKit plugin maps that field to StoreKit 2 `appAccountToken`
and the original StoreKit API's `applicationUsername`.

The backend decodes transaction information obtained directly from Apple's
authenticated HTTPS API. A client receipt is only a transaction locator. If
Apple returns `appAccountToken`, it must match the authenticated account's stored
UUID; a token from another account or an unknown token returns HTTP 409, even
before any local purchase has been claimed. Token values are absent from profile
responses, analytics and aggregate exports. No email or numeric account ID is
sent to Apple as the account token.

Legacy transactions without an Apple account token remain restorable. Their
ownership follows existing verified records and the first authenticated claim.
This preserves older binaries, but cannot prove the first claimant's identity
for a previously unseen tokenless transaction. This is a documented compatibility
limit, not proof that every historical purchase is account-bound.

## Renewal ownership and measurement

New `apple_subscription_claims` rows bind `(environment, originalTransactionId)`
to an account across renewal transaction IDs. Historical rows are checked before
claiming a chain. Existing per-transaction claims remain enforced. Ownership,
transaction evidence, one subscription projection per chain and the initial
measurement receipt commit together. Failed commits roll back and permit retry.
Restore refreshes verified dates and evidence; caller-supplied purchase and
original IDs are not persisted as provider evidence.

New chains produce one initial `purchase_verified` event, regardless of renewal
count. Adopting a historical chain produces no backfilled conversion. Earlier
Apple events remain unchanged and may include renewals; comparisons must separate
the deployment boundary. No revenue, active-subscriber or net-new-subscriber
claim should be derived from this event count.

Activation preserves an already higher tier and administrator access. It is not
a downgrade/revocation engine: automatic expiry, refunds outside activation,
App Store Server Notifications and full cross-provider reconciliation remain next
work. Transactions Apple marks `isUpgraded` are rejected; restore the current
purchase instead. The server continues supporting production-to-sandbox lookup
fallback for App Review and excludes sandbox events from production reports.

## Deployment and QA

1. Deploy the backend first. Existing startup `Base.metadata.create_all` creates
   `apple_account_tokens` and `apple_subscription_claims`; the role needs table/index
   creation privileges. No existing table columns are altered by this change.
2. Configure the existing Apple issuer, key ID, private key and exact bundle ID
   `com.power6.app`. Confirm the new authenticated token endpoint is available.
   A healthy `/health` response alone does not prove Apple credentials work.
3. Build iOS Workflow on Codemagic from main for 0.1.5 (23). The existing Xcode 26
   uploader workaround remains; this Windows run cannot validate signing/upload.
4. On a physical sandbox/TestFlight device, buy a plan, verify the returned server
   tier, finish the transaction, restore after relaunch, and verify duplicate
   callbacks do not add subscriptions/conversions. Repeat with a renewal.
5. Switch Power6 accounts while using the same Apple account: bound purchases must
   reject the second Power6 account. Test an older tokenless purchase separately.
6. Simulate offline/server failure and an eight-second timeout: keep the old plan,
   show the retry message, do not complete the purchase, then recover via Restore.
   Switch accounts or leave the screen while verification is pending; a late
   response must not overwrite the new account or acknowledge the old purchase.
7. Confirm acknowledgement failures retain the server-verified tier and offer a
   StoreKit confirmation retry. Canceled, pending, failed and unknown-product
   callbacks must not grant access.

Account deletion removes local tokens, chain claims and transaction evidence.
It does not cancel billing in Apple's systems. A provider token whose Power6
account was deleted is not automatically reassigned; recovery requires a separate
verified support procedure. Never paste keys or receipts into roadmap artifacts.

## Validation evidence

Local validation on November 3: **82 backend tests passed**, `pip check` found no
broken requirements, **23 Flutter tests passed**, `flutter analyze
--no-fatal-infos` passed with the same 41 existing informational findings and no
warnings/errors, and the production Flutter web release build succeeded.

Backend regressions cover token authentication/stability/isolation, token/chain
ownership, legacy restore compatibility, renewal deduplication, refreshed evidence,
rollback/retry, input bounds, malformed provider responses and account deletion.
Flutter widget tests use a simulated StoreKit stream and controlled server
responses to cover verification failure, timeout, account switching, callback
ordering, token handoff and acknowledgement policy. These tests contact no Apple
or Stripe payment APIs and do not substitute for the physical-device checklist.

References:
- [Apple appAccountToken](https://developer.apple.com/documentation/appstoreserverapi/appaccounttoken)
- [Apple account/transaction association](https://developer.apple.com/videos/play/wwdc2025/249/)
- Flutter plugin 0.4.9, `in_app_purchase_storekit_platform.dart`: the checked-in
  dependency resolution maps `applicationUserName` to `appAccountToken` for SK2.
