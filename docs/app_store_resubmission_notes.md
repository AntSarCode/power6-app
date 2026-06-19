# Power6 App Store Resubmission Notes

## Review Notes Summary

- Support URL: `https://power6.app/support`
- App Store description includes EULA: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
- Power6 Terms: `https://power6.app/terms`
- Privacy Policy: `https://power6.app/privacy`
- Delete account path: Menu > Account settings > Delete Account
- Review account:
  - Username: `app_review_expired`
  - Email: `app-review@power6.app`
  - Password: `Power6Review!2026`
  - State: expired subscription account; Subscribe tab is available for App Store purchase flow review
- IAP product IDs:
  - `power6_plusM`
  - `power6_plusY`
  - `power6_proM`
  - `power6_proY`
  - `power6_eliteM`
  - `power6_eliteY`
- Reminder: IAP products must be submitted in App Store Connect with the binary.
- Reminder: upload build `0.1.0 (16)` or newer; build `0.1.0 (15)` was rejected on June 19, 2026.
- Reminder: upload a physical-device screen recording of account deletion.
- Reminder: upload real iPad screenshots from the installed app, not Safari or `power6.app`.

## Review Account

Seed an expired review account from the backend directory:

```bash
python -m app.scripts.seed_review_account
```

Default credentials:

- Username: app_review_expired
- Email: app-review@power6.app
- Password: Power6Review!2026
- Subscription state: Expired user tier with an inactive Expired subscription record

Override these values with `POWER6_REVIEW_USERNAME`, `POWER6_REVIEW_EMAIL`, and `POWER6_REVIEW_PASSWORD` before running the script.

## App Store Connect Checklist

- Support URL: `https://power6.app/support`
- Terms of Use (EULA): `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
- Power6 Terms: `https://power6.app/terms`
- Privacy Policy: `https://power6.app/privacy`
- Delete account path in app: Menu > Account settings > Delete Account
- Account deletion screen recording: upload with review notes or describe the attached media location.
- Create subscription products matching these product IDs:
  - `power6_plusM`
  - `power6_plusY`
  - `power6_proM`
  - `power6_proY`
  - `power6_eliteM`
  - `power6_eliteY`
- Upload the required IAP review screenshot for each subscription group/product.
- Submit the IAP products with the new binary so review can validate purchases.
- Set the Support URL to `https://power6.app/support`.
- Confirm the App Store description includes the Apple Standard Terms of Use (EULA) link.
- Confirm App Review Notes mention the Terms, Privacy Policy, and fixed StoreKit 2 post-purchase activation path.
- Add the review account credentials above.
- Upload iPad screenshots showing the installed app in use. The majority should show core workflows such as dashboard/task usage, input, review, timeline, streaks, badges, subscription, and account deletion. Avoid using Safari screenshots or mostly login/splash screens.
- Add review notes explaining that account deletion is available at Menu > Account settings > Delete Account.
- Upload a new binary after the code changes are built.

## Manual Checks Before Resubmission

- [ ] Backend deployed with DELETE /users/me.
- [ ] Review account seed script run against production DB.
- [ ] https://power6.app/support opens publicly.
- [ ] App Store Connect Support URL updated.
- [x] App Store description includes Apple Standard Terms of Use (EULA) link.
- [x] App Review Notes include Terms, Privacy Policy, and StoreKit 2 activation fix.
- [ ] All IAP products created and submitted for review.
- [ ] New 13-inch iPad screenshots uploaded.
- [ ] Account deletion screen recording uploaded in review notes.
- [ ] New binary `0.1.0 (16)` uploaded after these changes.
