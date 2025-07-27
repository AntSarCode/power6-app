
# Power6

Power6 is a full-stack productivity journal app built to help users set and complete six priority-ranked tasks each day. It features streak tracking, task history, subscription-based feature gating, and backend syncing.

---

## 🚀 Features

### ✅ Core Functionality
- **Task Input**: Add up to 6 ranked tasks per day
- **Task Review**: Check off completed tasks and store history
- **Streak Tracker**: Tracks consecutive days of full task completion
- **Timeline View** *(Plus/Pro Only)*: View past daily task completions
- **Stats Dashboard** *(Pro Only)*: Visualize performance over time
- **Subscription Tiers**: Free, Plus, Pro — gated features

### 🔁 Backend Sync
- Task and user data saved to backend via FastAPI
- Tasks pulled on next login or device
- Duplicate task prevention per day
- Automatic database schema creation at startup

### 🔐 Auth & User Management
- Token-based authentication (JWT)
- User-specific data handling
- Tier management (Free, Plus, Pro, Elite, Admin)
- ISO-formatted datetime serialization for all user/task responses

---

## 🧱 Tech Stack

### Frontend (Flutter)
- Flutter SDK (web and desktop)
- Provider or ChangeNotifier for state
- SharedPreferences for local persistence

### Backend (FastAPI)
- FastAPI + Pydantic v2
- SQLAlchemy ORM
- SQLite (default) or PostgreSQL (preferred)
- Full CRUD for tasks
- Live tier-aware auth system

### Dev Tools
- VS Code / Android Studio
- GitHub for version control
- Platform support: Web, Windows

---

## 🛠 Local Setup

### 1. Clone the Repo
```bash
git clone https://github.com/AntSarCode/power6.git
cd power6
```

### 2. Backend Setup
```bash
cd Power6Backend
uvicorn main:app --reload
```

### 3. Frontend Setup (Flutter)
```bash
cd Power6Mobile/power6_mobile
flutter run -d chrome
```

> Ensure backend runs at `http://localhost:8000` with CORS enabled.

---

## 💳 Subscription Tiers
| Feature                  | Free | Plus | Pro  | Elite |
|--------------------------|------|------|------|--------|
| Task Input / Review      | ✅   | ✅   | ✅   | ✅     |
| Streak Tracker           | ✅   | ✅   | ✅   | ✅     |
| Timeline View            | ❌   | ✅   | ✅   | ✅     |
| Stats Dashboard          | ❌   | ❌   | ✅   | ✅     |
| Multi-device Sync        | ❌   | ✅   | ✅   | ✅     |
| Admin Features           | ❌   | ❌   | ❌   | ✅     |

---

## 📁 Project Structure (Flutter + FastAPI)
```
.
├── Power6Mobile            # Flutter frontend (web + desktop)
│   ├── lib
│   │   ├── screens         # UI screens
│   │   ├── widgets         # Reusable components
│   │   ├── utils           # Helpers (date, error handling)
│   │   ├── services        # API interaction
│   │   ├── state           # AppState (provider)
│   │   └── models          # Data models
│   └── pubspec.yaml
│
├── Power6Backend           # FastAPI backend
│   └── app
│       ├── models          # SQLAlchemy models
│       ├── routes          # FastAPI route definitions
│       ├── schemas         # Pydantic schemas
│       └── main.py         # Entrypoint
```

---

## 📈 Dev Phases
- ✅ Phase 1: Flutter Foundation
- ✅ Phase 2: MVP Task Logic (completed)
- 🔄 Phase 3: Final Auth Tweaks + Full CRUD
- 🔄 Phase 4: Subscription + Monetization
- 🔜 Phase 5: Public Launch and Feedback

---

## 📬 Feedback
We welcome contributions, feedback, or ideas! Feel free to open an issue or contact the team.

---

## 🪪 License
MIT License — build, fork, and use freely.

---

Power6 is our first full-stack Flutter x FastAPI productivity build. Thanks for checking it out!
