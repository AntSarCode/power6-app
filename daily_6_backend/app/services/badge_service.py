from sqlalchemy.orm import Session
from app.models.badge import Badge, UserBadge
from app.models.models import User


def get_user_badges(db: Session, user_id: int):
    return db.query(UserBadge).filter(UserBadge.user_id == user_id).all()


def evaluate_and_assign_badges(db: Session, user_id: int):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return []

    assigned_badges = []
    unlocked_ids = {
        ub.badge_id for ub in db.query(UserBadge).filter(UserBadge.user_id == user_id)
    }

    # Example criteria (extend as needed)
    criteria = {
        "streak_3": lambda u: u.current_streak >= 3,
        "streak_7": lambda u: u.current_streak >= 7,
        "tasks_100": lambda u: u.total_completed_tasks >= 100,
    }

    for badge in db.query(Badge).all():
        unlock_key = getattr(badge, "unlock_condition", None)
        if not unlock_key or badge.id in unlocked_ids:
            continue

        condition = criteria.get(unlock_key)
        if condition and condition(user):
            new_entry = UserBadge(user_id=user.id, badge_id=badge.id)
            db.add(new_entry)
            assigned_badges.append(badge)

    db.commit()
    return assigned_badges
