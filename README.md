# Power6

A focused, six-task productivity app that helps you finish the right work every day. Power6 pairs a frictionless daily workflow with streaks, badges, and a clean, unified UI.

---

## 🎉 What’s new (Launch-Ready)
- **Unified dark theme** with gradient + subtle glass effects across **all** screens.
- **Consistent background**: removed mismatched greys; every screen now uses the same thematic background.
- **Bottom navigation refresh**: stable nav shell with preserved tab state.
- **Badges gallery**: dedicated Badges screen with grid view and image assets.
- **Routing hardening**: added wrapper screens to avoid symbol collisions.
  - `PowerMainNav` (optional) and `MainNav` now both compile cleanly.
  - `PowerBadgeScreen` added; `BadgeScreen` retained (optional).
- **Web build stability**: removed deprecated `withOpacity` usage; replaced with `Color.fromRGBO` / `withAlpha`-safe values.
- **Launch checklist & deploy docs** added below.

---

## 🚀 Features

### ✅ Core
- **Daily Task Input**: add up to 6 priority-ranked tasks
- **Review & Complete**: check off and roll unfinished work forward
- **Streaks**: consecutive-day completion tracker
- **Timeline** *(Pro+)*: browse past days
- **Badges**: milestone rewards (now visible with PNG assets)
- **Subscriptions**: Free / Plus / Pro / Elite tiers
- **Admin** *(Elite/Admin)*: badge + user management

### 🔁 Backend Sync
- FastAPI + PostgreSQL with JWT auth
- Device-safe, multi-user data
- Schema bootstrapping, superuser creation

---

## 🧱 Tech Stack
**Frontend**: Flutter (Web/Desktop-ready), Provider/ChangeNotifier, SharedPreferences  
**Backend**: FastAPI, Pydantic v2, SQLAlchemy, PostgreSQL (prod) / SQLite (dev)  
**Hosting**: Web on **Vercel** (recommended). Backend on **Render** (example).  

> You can also host the web build on Firebase Hosting. Vercel config is included below.

---

## 📦 Project Structure (frontend excerpt)
```
power6_mobile/lib
├── app.dart                  # Minimal MaterialApp for login + root
├── main.dart                 # Providers, route table, root gate
├── navigation
│   ├── main_nav.dart         # Primary bottom nav shell (production)
│   └── power_main_nav.dart   # Wrapper nav (optional; safe fallback)
├── screens
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart
│   ├── task_input_screen.dart
│   ├── task_review_screen.dart
│   ├── timeline_screen.dart
│   ├── streak_screen.dart
│   ├── subscription_screen.dart
│   ├── badge_screen.dart          # Legacy/standard badge gallery
│   └── power_badge_screen.dart    # New badge gallery (wrapper)
├── state
│   └── app_state.dart
├── services
│   └── streak_service.dart
├── ui
│   └── theme.dart             # Unified theme + colors
└── assets
    └── badges/                # PNG badge assets
```

---

## 🖼 Badge Assets
Make sure these files exist under `assets/badges/` and are referenced in **pubspec.yaml** (see below).

```
challenge_champion.png
community_builder.png
devout.png
disciplined.png
early_bird.png
feedback_fanatic.png
feedback_guru.png
goal_getter.png
night_owl.png
over_achiever.png
social_butterfly.png
starter.png
task_master.png
veteran.png
weekend_warrior.png
```

**pubspec.yaml**
```yaml
flutter:
  assets:
    - assets/badges/
```

---

## ⚙️ Configuration
Frontend reads API settings from `lib/widgets/env.dart` (or similar). Example:
```dart
class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
```
Pass the value at build time for web:
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://your-api.example.com
```

---

## 🧪 Local Development
### Backend
```bash
cd power6_backend
uvicorn main:app --reload
```

### Frontend
```bash
cd power6_mobile
flutter pub get
flutter run -d chrome
```
Make sure CORS is enabled for `http://localhost:xxxx` in your backend.

---

## 🌐 Deploy (Web on Vercel)
1. Build the Flutter web app:
```bash
cd power6_mobile
flutter build web --release \
  --dart-define=API_BASE_URL=https://your-api.example.com
```
1. Deploy the contents of `power6_mobile/build/web` to Vercel.
1. Add `vercel.json` to route all paths to `index.html` (SPA):
```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```
> On Firebase Hosting, use a similar rewrite rule to `index.html`.

---

## 🧭 Routing Notes
- Production uses **`MainNav`** (bottom bar) and shows the **Badges** tab.
- Optional wrappers:
  - `PowerMainNav`: alternative nav shell to bypass any legacy symbol collisions.
  - `PowerBadgeScreen`: badge gallery wrapper.
- Update routes in `main.dart`/`app.dart` if you switch wrappers.

Example (`main.dart`):
```dart
void example() {
  final routes = <String, WidgetBuilder>{
    '/home'   : (ctx) => const MainNav(),
    '/badges' : (ctx) => const PowerBadgeScreen(),
  };
}
```

---

## 💄 UI Guidelines (implemented)
- Unified dark gradient background on all screens
- Subtle glow and glass (BackdropFilter) accents
- Smooth, low-friction inputs and large tap targets
- Consistent spacing and rounded corners
- Reduced visual noise; emphasis on primary actions

---

## ✅ Launch Checklist
- [ ] `flutter analyze` → 0 errors
- [ ] `dart format .` clean
- [ ] Badge assets present & listed in `pubspec.yaml`
- [ ] API base URL defined via `--dart-define` (web) or `env.dart`
- [ ] SPA rewrites in hosting config (Vercel/Firebase)
- [ ] Smoke test: login → dashboard → every tab → badges grid visible
- [ ] Version bump + changelog updated

---

## 🧭 Changelog (high level)
- **UI**: unified theme, gradient background, glass accents
- **Nav**: stable bottom navigation with tab state, badges tab visible
- **Badges**: image grid screen; assets wired; error-safe fallbacks
- **Build**: removed deprecated color APIs that broke web precision
- **Routing**: added wrappers (`PowerMainNav`, `PowerBadgeScreen`) to prevent analyzer conflicts
- **Docs**: deploy instructions for Vercel + SPA rewrites; launch checklist

---

## 📬 Feedback
Ideas, issues, PRs welcome. Let us know what would make Power6 even smoother.

---

## 🧰 Requirements
- Flutter **stable 3.x** and Dart **3.x**
- Android SDK / Xcode (for mobile builds)
- Node/npm (only if you deploy to Vercel via CLI)

## 🔧 Setup (first time)
```bash
# from repo root
cd power6_mobile
flutter pub get
```

### Configure API endpoint
Use a Dart define (recommended) or edit your env file.
```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://your-api.example.com
```

## 📱 Build Targets
**Web (release)**
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://your-api.example.com
```
**Android (release APK)**
```bash
flutter build apk --release
```
**iOS (release)**
```bash
flutter build ios --release
```

## 🛠 Troubleshooting
### 1) `The name 'X' isn't a class` in routes
This usually means the imported file doesn’t expose a class with that name **or** your route value is outside the `MaterialApp(...)` call.
- Ensure imports are unaliased when you reference a class directly:
  ```dart
  import 'navigation/main_nav.dart';
  import 'screens/power_badge_screen.dart';
  ```
- Use constructors in routes:
  ```dart
void example() {
  final routes = <String, WidgetBuilder>{
    '/home'   : (ctx) => const MainNav(),
    '/badges' : (ctx) => const PowerBadgeScreen(),
  };
}
```
- If the legacy files are conflicted, you can safely switch to the wrappers: `PowerMainNav`, `PowerBadgeScreen`.

### 2) Parser error near a colon (e.g., `get or set expected, got :`)
Happens when the `routes:` map fell **outside** `MaterialApp(...)` because of a missing comma/brace above it.
- Ensure the line before `routes:` ends with a comma (e.g., `home: const _RootGate(),`).
- Make sure parentheses/braces around `MaterialApp(` are balanced.
- Route keys must be quoted strings and separated by commas.

### 3) Badges not visible
- Verify files exist under `assets/badges/` and are listed in **pubspec.yaml**:
  ```yaml
  flutter:
    assets:
      - assets/badges/
  ```
- File names must match exactly (snake_case), e.g. `goal_getter.png`.
- Hard refresh cache on web (Ctrl/Cmd+Shift+R) after deploy.

### 4) `withOpacity` deprecation / precision loss (web)
Replace with one of:
```dart
// exact RGBA
const c = Color.fromRGBO(15, 179, 160, 0.22);
// or integer alpha
const c2 = Color(0xFF009688).withAlpha(56);
```

## 🔐 Environment & Security
- Keep secrets out of the repo; prefer `--dart-define` or hosting env vars.
- Backend should enforce auth (JWT), rate-limits, and CORS for your domains.

## 🗺 Roadmap (post-launch ideas)
- Settings page (theme toggles, notifications)
- Streak/badge detail dialogs and share images
- CSV export (Pro) and calendar sync
- Team/group features (Elite)
- Offline queue & optimistic updates

## 🪪 License
MIT — open to use, modify, and share.
