from database import Base, engine
from app.scripts.seed_badges import seed_badges

# === FORCE IMPORT OF ALL MODELS TO REGISTER WITH BASE ===
from app.models import models  # <-- this is key

def reset_database():
    print("🔄 Dropping and recreating test.sqlite schema...")
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    print("✅ Schema recreated.")

    seed_badges()
