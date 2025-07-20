from database import Base, engine
from Power6Backend.app.scripts.seed_badges import seed_badges

def reset_database():
    print("🔄 Dropping and recreating test.sqlite schema...")
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    print("✅ Schema recreated.")

    seed_badges()
