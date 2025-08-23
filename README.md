# Power6

Power6 is a full-stack productivity journal app built to help users set and complete six priority-ranked tasks each day. It features streak tracking, task history, badge rewards, subscription-based feature gating, live database syncing, and admin-level management.

---

## 🚀 Features

### ✅ Core Functionality
- **Task Input**: Add up to 6 ranked tasks per day
- **Task Review**: Check off completed tasks and store history
- **Streak Tracker**: Tracks consecutive days of full task completion
- **Timeline View** *(Plus/Pro Only)*: View past daily task completions
- **Stats Dashboard** *(Pro/Elite Only)*: Visualize performance over time
- **Badges**: Earn milestones based on behavior with live backend seeding
- **Subscription Tiers**: Free, Plus, Pro, Elite — gated features
- **Admin Controls** *(Elite/Admin Only)*: Full user and badge management

### 🔁 Backend Sync
- Task, user, and badge data saved to live PostgreSQL via FastAPI
- Multi-device sync with JWT-based authentication
- Duplicate task prevention per day
- Automatic database schema creation at startup
- Superuser creation support via secure script or direct DB insert

### 🔐 Auth & User Management
- Token-based authentication (JWT)
- User-specific data handling
- Tier management (Free, Plus, Pro, Elite, Admin)
- Password hashing (bcrypt) for secure storage
- ISO-formatted datetime serialization for all responses

---

## 🧱 Tech Stack

### Frontend (Flutter)
- Flutter SDK (web and desktop)
- Provider/ChangeNotifier for state management
- SharedPreferences for local persistence
- Deployed to Firebase Hosting

### Backend (FastAPI)
- FastAPI + Pydantic v2
- SQLAlchemy ORM
- PostgreSQL (production) / SQLite (local dev)
- Full CRUD for tasks and badges
- Stripe subscription integration (WIP)
- Deployed to Render

### Dev Tools
- VS Code / Android Studio
- GitHub for version control
- Platform support: Web, Windows, macOS (planned)

---

## 🛠 Local Setup

### 1. Clone the Repo
```bash
git clone https://github.com/AntSarCode/power6.git
cd power6
```

### 2. Backend Setup
```bash
cd power6_backend
uvicorn main:app --reload
```

### 3. Frontend Setup (Flutter)
```bash
cd power6_mobile
flutter run -d chrome
```

> Ensure backend runs at `http://localhost:8000` with CORS enabled.

---

## 💳 Subscription Tiers
| Feature                  | Free | Plus | Pro  | Elite |
|--------------------------|------|------|------|-------|
| Task Input / Review      | ✅   | ✅   | ✅   | ✅   |
| Streak Tracker           | ✅   | ✅   | ✅   | ✅   |
| Timeline View            | ❌   | ✅   | ✅   | ✅   |
| Stats Dashboard          | ❌   | ❌   | ✅   | ✅   |
| Badge Rewards            | ❌   | ✅   | ✅   | ✅   |
| Multi-device Sync        | ❌   | ✅   | ✅   | ✅   |
| Admin Features           | ❌   | ❌   | ❌   | ✅   |

---

## 📁 Project Structure
```
.
├── power6_mobile          # Flutter frontend
│   ├── lib                # UI screens, widgets, services, state, models
│   └── pubspec.yaml
│
├── power6_backend         # FastAPI backend
│   └── app
│       ├── models         # SQLAlchemy models
│       ├── routes         # FastAPI route definitions
│       ├── schemas        # Pydantic schemas
│       ├── core           # Security, config
│       └── main.py        # Entrypoint
```

---

## 📈 Dev Phases
- ✅ Phase 1: Core UI, routing, local logic
- ✅ Phase 2: Task CRUD + Auth integration
- ✅ Phase 3: Subscription UI + tier gating
- ✅ Phase 4: Badges, admin features, deployment
- 🔜 Phase 5: Feedback loop + Stripe integration

---

## 📬 Feedback
We welcome contributions, feedback, or ideas! Open an issue or contact the team.

---

## 🪪 License
MIT License — build, fork, and use freely.

---

Power6 is our first full-stack Flutter x FastAPI productivity build, now running in production with live superuser capabilities.
