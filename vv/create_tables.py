from app.config.database import Base, engine

# Import all models so SQLAlchemy knows about them
from app.models.user import User
from app.models.scan import Scan
from app.models.finding import Finding
from app.models.log import ActivityLog

print("Creating database tables...")

Base.metadata.create_all(bind=engine)

print("Database tables created successfully.")