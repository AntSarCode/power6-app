# iOS publishing recovery

The October 28, 2026 Codemagic build `6ae18e29206ce93970c6bb73` at
`93cbeab` successfully signed and exported Power6 0.1.4 (21), then failed
during App Store Connect upload with altool error 19:
`Cannot determine the Apple ID from Bundle ID 'com.power6.app' and platform 'IOS'`.

The iOS workflow now sets
`APP_STORE_CONNECT_ALTOOL_ADDITIONAL_ARGUMENTS: "--use-old-altool"`, the
[Codemagic-documented workaround](https://help.codemagic.io/articles/6636894916-fixing-ios-build-errors-with-xcode-26-2-and-altool-verification-issues)
for Xcode 26 uploader compatibility. This changes the uploader, not the build SDK,
bundle identifier, signing team, or App Store Connect integration.
The retry uses 0.1.4 (22) to give the new binary its own build number.

Rebuild `main` with **iOS Workflow**, then verify Publishing succeeds and build
0.1.4 (22) finishes processing in App Store Connect for app `6765852645`.
Only that remote result confirms recovery; local Flutter checks cannot exercise
Apple's uploader.

If error 19 persists, check for pending developer/App Store Connect agreements
and confirm the `power6_key` integration can access the existing app
`6765852645` (`com.power6.app`). Do not create a replacement app or change the
bundle identifier. Review the workaround when upgrading Codemagic/Xcode and
remove it once the modern uploader is verified against this account.
