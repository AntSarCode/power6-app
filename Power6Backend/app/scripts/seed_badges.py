from sqlalchemy.orm import Session
from Power6Backend.app.models.badge import Badge
from Power6Backend.app.database import SessionLocal

BADGE_DATA = [
    {"title": "Starter", "description": "Complete your first task", "icon_uri": "starter.png"},
    {"title": "Disciplined", "description": "Complete tasks 5 days in a row", "icon_uri": "disciplined.png"},
    {"title": "Night Owl", "description": "Finish a task after midnight", "icon_uri": "night_owl.png"},
    {"title": "Early Bird", "description": "Finish a task before 7am", "icon_uri": "early_bird.png"},
    {"title": "Weekend Warrior", "description": "Complete a task on the weekend", "icon_uri": "weekend_warrior.png"},
    {"title": "Veteran", "description": "Complete 100 tasks", "icon_uri": "veteran.png"},
    {"title": "Overachiever", "description": "Complete 500 tasks", "icon_uri": "overachiever.png"},
    {"title": "Task Master", "description": "Complete 1000 tasks", "icon_uri": "task_master.png"},
    {"title": "Social Butterfly", "description": "Share a task on social media", "icon_uri": "social_butterfly.png"},
    {"title": "Feedback Guru", "description": "Give feedback on 10 tasks", "icon_uri": "feedback_guru.png"},
    {"title": "Goal Getter", "description": "Set and achieve 5 goals", "icon_uri": "goal_getter.png"},
    {"title": "Community Builder", "description": "Invite 10 friends to join", "icon_uri": "community_builder.png"},
    {"title": "Challenge Champion", "description": "Complete 5 weekly challenges", "icon_uri": "challenge_champion.png"},
    {"title": "Devout", "description": "Complete tasks for 30 days straight", "icon_uri": "devout.png"},
    {"title": "Feedback Fanatic", "description": "Receive feedback on 20 tasks", "icon_uri": "feedback_fanatic.png"},
]

def seed_badges():
    db: Session = SessionLocal()
    try:
        for badge in BADGE_DATA:
            exists = db.query(Badge).filter(Badge.title == badge["title"]).first()
            if not exists:
                db.add(Badge(
                    title=badge["title"],
                    description=badge["description"],
                    icon_uri=badge["icon_uri"]
                ))
        db.commit()
        print("✅ Badges seeded.")
    except Exception as e:
        print("❌ Error seeding badges:", e)
    finally:
        db.close()

if __name__ == "__main__":
    seed_badges()
