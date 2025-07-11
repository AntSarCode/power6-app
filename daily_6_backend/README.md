# Power6

Power6 is a full-stack productivity journal app built to set and complete six daily priority-ranked tasks. It includes streak tracking, task history, subscription-based feature gating, and backend syncing.

---

##  Features

### Core Functionality
- **Task Input**: Add up to 6 ranked tasks per day
- **Task Review**: Check off completed tasks and store history
- **Streak Tracker**: Tracks consecutive days of full task completion
- **Stats Dashboard** *(Pro Only)*: Visualize task performance over time
- **Subscription Tiers**: Free, Plus, Pro — gated features and mock upgrades

###  Backend Sync
- All tasks saved to database
- Tasks pulled on next login/device
- No duplicate tasks for a single day

###  Auth & User
- User-based task storage
- Mock authentication with `get_current_user`

---

##  Tech Stack

### Frontend
- React + TypeScript + Vite
- Zustand or Context API (state)
- `localStorage` + `fetch`

### Backend
- FastAPI + Pydantic v2
- SQLAlchemy ORM
- SQLite (default), upgradeable to Postgres

### Styling
- Pure CSS for MVP simplicity

---

## 🛠 Local Setup

### 1. Clone the Repo
```bash
git clone https://github.com/your-username/power6.git
cd power6
```

### 2. Start the Backend
```bash
cd backend
uvicorn main:app --reload
```

### 3. Start the Frontend
```bash
cd daily_6_frontend
npm install
npm run dev
```

> Make sure your backend is accessible at `http://localhost:8000` and CORS is enabled.

---

## Subscription Tiers
| Feature                  | Free | Plus | Pro  |
|--------------------------|------|------|------|
| Task Input / Review      | ✅   | ✅   | ✅   |
| Streak Tracker           | ✅   | ✅   | ✅   |
| Task History (unlimited) | ❌   | ✅   | ✅   |
| Stats Dashboard          | ❌   | ❌   | ✅   |
| Multi-device Sync        | ❌   | ✅   | ✅   |

---

### Project Structure
```
.
├── daily_6_frontend        # React + Vite frontend
│   └── src
│       ├── pages           # TaskInput, TaskReview, etc.
│       ├── services        # API wrappers
│       ├── context         # UserContext for tier
│       └── components      # Navbar, Layout
│
├── backend
│   └── app
│       ├── models          # SQLAlchemy Task & User models
│       ├── routes          # FastAPI routes for /tasks
│       ├── schemas         # Pydantic models (v2)
│       └── main.py         # App entrypoint
```

---

## Future Plans
- About Page: Detailed app structure: Psychology, Productivity, and Tech
- Stripe integration
- JWT login system
- AI-based task insights
- App deployment (Vercel + Fly.io or Render)
- Mobile app (React Native)

---

## License
MIT License — feel free to use, build on, or fork.

---

First completed and refined Full-Stack undertaking. Thank you for checking out Power6! Contributions and feedback are welcome.
