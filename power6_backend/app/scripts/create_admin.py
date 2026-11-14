import argparse
import os
import secrets
import string

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.models import User
from app.utils.hash import get_password_hash


def _generate_password(length: int = 18) -> str:
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    return "".join(secrets.choice(alphabet) for _ in range(length))


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Create or update an admin user.")
    parser.add_argument("--username", default=os.getenv("ADMIN_USERNAME", "AnthonyM_admin"))
    parser.add_argument("--email", default=os.getenv("ADMIN_EMAIL", "mooread@lindsey.edu"))
    parser.add_argument("--password", default=os.getenv("ADMIN_PASSWORD"))
    parser.add_argument("--tier", default=os.getenv("ADMIN_TIER", "Elite"))
    parser.add_argument(
        "--update-existing",
        action="store_true",
        default=os.getenv("ADMIN_UPDATE_EXISTING", "").lower() in {"1", "true", "yes"},
        help="Reset password/tier/admin flag if the user already exists.",
    )
    return parser


def create_admin(
    username: str,
    email: str,
    password: str | None,
    tier: str,
    update_existing: bool = False,
):
    generated_password = password is None
    password = password or _generate_password()
    username_norm = username.strip()
    email_norm = email.strip().lower()

    db: Session = SessionLocal()
    try:
        existing = (
            db.query(User)
            .filter(
                (func.lower(User.username) == username_norm.lower())
                | (func.lower(User.email) == email_norm)
            )
            .first()
        )
        if existing:
            if not update_existing:
                print(f"Admin already exists: {existing.id}")
                return

            existing.username = username_norm
            existing.email = email_norm
            existing.hashed_password = get_password_hash(password)
            existing.is_admin = True
            existing.tier = tier
            db.add(existing)
            db.commit()
            db.refresh(existing)
            user = existing
            action = "updated"
        else:
            user = User(
                username=username_norm,
                email=email_norm,
                hashed_password=get_password_hash(password),
                is_admin=True,
                tier=tier,
            )

            db.add(user)
            db.commit()
            db.refresh(user)
            action = "created"

        print(f"Admin {action}: {user.id}")
        print(f"Username: {user.username}")
        print(f"Email: {user.email}")
        print(f"Tier: {user.tier}")
        if generated_password:
            print(f"Temporary password: {password}")
    finally:
        db.close()


if __name__ == "__main__":
    args = _parser().parse_args()
    create_admin(
        username=args.username,
        email=args.email,
        password=args.password,
        tier=args.tier,
        update_existing=args.update_existing,
    )
