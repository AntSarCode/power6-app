from passlib.context import CryptContext
import argparse

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate a bcrypt hash for a password.")
    parser.add_argument("password", type=str, help="The plain-text password to hash")
    args = parser.parse_args()

    hashed = get_password_hash(args.password)
    print(f"Hashed password:\n{hashed}")
