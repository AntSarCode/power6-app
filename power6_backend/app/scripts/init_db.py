from app.database import Base, engine
from app.models.models import Task

Base.metadata.create_all(bind=engine)
print("✅ Database tables created.")