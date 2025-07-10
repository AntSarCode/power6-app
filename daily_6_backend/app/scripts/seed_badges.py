from sqlalchemy.orm import Session
from app.models.badge import Badge
from app.database import SessionLocal

BADGE_DATA = [
    {"title": "Starter", "description": "Complete your first task"},
    {"title": "Disciplined", "description": "Complete tasks 5 days in a row"},
    {"title": "Night Owl", "description": "Finish a task after midnight"},
    {"title": "Early Bird", "description": "Finish a task before 7am"},
    {"title": "Weekend Warrior", "description": "Complete a task on the weekend"},
    {"title": "Veteran", "description": "Complete 100 tasks"},
    {"title": "Overachiever", "description": "Complete 500 tasks"},
    {"title": "Task Master", "description": "Complete 1000 tasks"},
    {"title": "Social Butterfly", "description": "Share a task on social media"},
    {"title": "Feedback Guru", "description": "Give feedback on 10 tasks"},
    {"title": "Goal Getter", "description": "Set and achieve 5 goals"},
    {"title": "Community Builder", "description": "Invite 10 friends to join"},
    {"title": "Challenge Champion", "description": "Complete 5 weekly challenges"},
    {"title": "Devout", "description": "Complete tasks for 30 days straight"},
    {"title": "Feedback Fanatic", "description": "Receive feedback on 20 tasks"},
]

def seed_badges():
    db: Session = SessionLocal()
    try:
        for badge in BADGE_DATA:
            exists = db.query(Badge).filter(Badge.title == badge["title"]).first()
            if not exists:
                db.add(Badge(**badge))
        db.commit()
        print("✅ Badges seeded.")
    except Exception as e:
        print("❌ Error seeding badges:", e)
    finally:
        db.close()

if __name__ == "__main__":
    seed_badges()
