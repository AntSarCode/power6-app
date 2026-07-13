# Power6

Power6 is a focused six-task productivity app for choosing the work that matters today, finishing it, and building consistency through review, streaks, badges, and tiered insights.

The repository contains a Flutter client and a FastAPI backend.

## Current Status

- App version: `0.1.3+20` in `power6_mobile/pubspec.yaml`
- Frontend: Flutter, Provider/ChangeNotifier, secure token storage, in-app purchase support
- Backend: FastAPI, SQLAlchemy/SQLModel, Pydantic, JWT auth, PostgreSQL in production and SQLite for local/test
- Production API fallback: `https://power6-backend.onrender.com`
- Public app/legal pages: privacy, terms, support, and web deploy output are included
- iOS subscription flow: Apple In-App Purchase product IDs are wired in `ApiConstants`

## Licensing

Power6 is licensed under the GNU Affero General Public License v3.0, as published in the root `LICENSE` file.

The previous README claimed MIT licensing, but the repo did not contain an MIT license file and the project owner chose a stronger copyleft license model instead. `AGPL-3.0-or-later` is the better fit for Power6 because the project includes a hosted backend/API and web/mobile clients.

Recommended source notice for new or substantially edited source files:

```txt
SPDX-License-Identifier: AGPL-3.0-or-later
Copyright (c) 2026 Power6
```

The root `LICENSE` file contains the full GNU Affero General Public License v3.0 text. GitHub should detect the repository license from that standard file.

## Features

- Daily planning for up to six priority-ranked tasks
- Review flow for completing work and carrying unfinished tasks forward
- Streak tracking and streak refresh support
- Badge gallery backed by PNG assets and backend badge evaluation
- Timeline and task history views for paid tiers
- Pro analytics and CSV export endpoints
- Free, Plus, Pro, Elite, Expired, and Admin tier handling
- Apple App Store subscription products for iOS
- Stripe checkout support for non-iOS/web subscription paths
- In-app account deletion with backend cleanup of tasks, subscriptions, badges, and related records
- Feedback submission and conversion event tracking
- App review support account seeding for Apple review workflows

## Project Structure

```text
power6_mobile/
  lib/
    config/api_constants.dart      API base URL and endpoint constants
    env.dart                       Environment-driven API settings
    main.dart                      Providers, route table, root auth gate
    navigation/main_nav.dart       Primary bottom navigation shell
    screens/                       Login, signup, home, task, streak, badges, subscription, account views
    services/                      Auth, API, tasks, badges, purchases, analytics
    state/                         App state and backend adapter
    ui/                            Theme, scaffold, cards, overlays, launch UI
    widgets/                       Shared UI and feedback modal
  assets/
    badges/                        Badge PNG assets
    graphics/                      Power6 logo and supporting graphics
  web/
    privacy/ terms/ support/       Public policy/support pages

power6_backend/
  app/
    main.py                        FastAPI app factory, CORS, bootstrap migrations
    routes/                        Auth, users, tasks, streaks, badges, IAP, Stripe, feedback, events
    services/                      Task, badge, streak, Apple IAP, Stripe services
    models/ schemas/ config/       Database models, DTOs, settings
    scripts/                       DB init, admin creation, badge seeding, review-account seeding
  tests/                           Backend regression tests

docs/                              App Store review notes, legal docs, launch/marketing docs
deploy_out/                        Static exported public pages
```

## Subscription Products

The iOS App Store product IDs are configured in `power6_mobile/lib/config/api_constants.dart`:

```text
power6_plusM
power6_plusY
power6_proM
power6_proY
power6_eliteM
power6_eliteY
```

The iOS app uses Apple In-App Purchase and activates tiers through `/iap/apple/activate`. Stripe checkout remains available for web or other non-iOS payment paths through `/stripe/create-checkout-session`.

## Configuration

The Flutter app resolves its API base URL through `power6_mobile/lib/config/api_constants.dart`, which reads `power6_mobile/lib/env.dart` and falls back to the production Render backend.

For local or web builds, pass the API URL with a Dart define:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

For release web builds:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://your-api.example.com
```

Backend configuration should come from environment variables. Keep secrets out of the repository.

## Local Development

Backend:

```bash
cd power6_backend
uvicorn app.main:app --reload
```

Frontend:

```bash
cd power6_mobile
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

## Deployment Notes

Frontend web:

```bash
cd power6_mobile
flutter build web --release --dart-define=API_BASE_URL=https://your-api.example.com
```

Deploy `power6_mobile/build/web` to your static host. For single-page-app routing, rewrite all routes to `index.html`.

Backend:

- Run the FastAPI app from `power6_backend/app/main.py`.
- Configure CORS through `ALLOWED_ORIGINS` or `CORS_ALLOW_ALL=1` for debugging only.
- Provide database, JWT, Apple IAP, and Stripe settings through environment variables.
- The app includes lightweight bootstrap migrations for critical task/subscription columns.

## Useful Commands

```bash
flutter analyze
flutter test
flutter build web --release
pytest
```

Run backend tests from `power6_backend` or with the configured project virtual environment.

## Launch Checklist

- [x] Add the root `LICENSE` file for the selected AGPL/GPL license
- [ ] Add SPDX headers or notices to source files where desired
- [ ] Run `flutter analyze`
- [ ] Run Flutter widget/accessibility tests
- [ ] Run backend `pytest`
- [ ] Verify badge assets are present and listed in `pubspec.yaml`
- [ ] Smoke test login, task creation, review, dashboard, timeline, streaks, badges, subscriptions, feedback, and account deletion
- [ ] Confirm Privacy Policy, Terms, Support, and App Store metadata match the current app behavior
- [ ] Confirm Apple IAP products are available in App Store Connect and submitted with the iOS build

## Recent Updates Reflected In This README

- Removed the stale MIT license claim
- Documented the intended AGPL/GPL licensing path
- Updated version and dependency context for the current Flutter app
- Added Apple IAP product IDs and activation endpoint notes
- Added account deletion, app review, feedback, event tracking, analytics, and CSV export coverage
- Corrected API configuration paths and backend startup command
- Replaced stale/garbled emoji-heavy sections with plain ASCII documentation
