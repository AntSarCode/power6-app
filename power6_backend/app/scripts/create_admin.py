from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.models import User
from app.utils.hash import get_password_hash

def create_admin():
    db: Session = SessionLocal()

    existing = db.query(User).filter(User.username == "AnthonyM_admin").first()
    if existing:
        print("Admin already exists")
        return

    user = User(
        username="AnthonyM_admin",
        email="mooread@lindsey.edu",
        hashed_password=get_password_hash("BigManOnCampus"),
        is_admin=True,
        tier="Elite"
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    print(f"Admin created: {user.id}")

if __name__ == "__main__":
    create_admin()