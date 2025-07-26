from app.database import Base, engine
# noinspection PyUnresolvedReferences
from app.models.models import User, Task, Subscription
# noinspection PyUnresolvedReferences
from app.models.badge import Badge, UserBadge

def init_database():
    Base.metadata.create_all(bind=engine)
    print("✅ Database tables created.")