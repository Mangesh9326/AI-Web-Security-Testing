from datetime import datetime, timedelta, timezone
import bcrypt
from jose import jwt
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from app.config.settings import settings
from app.models.user import User, UserRole
from app.schemas.user import UserCreate

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

def verify_password(password: str, password_hash: str) -> bool:
    return bcrypt.checkpw(password.encode(), password_hash.encode())

def create_access_token(user: User) -> str:
    settings.validate_security_settings()
    expires = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_expire_minutes)
    return jwt.encode({"sub": str(user.id), "exp": expires}, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)

def register_user(db: Session, payload: UserCreate) -> User:
    exists = db.scalar(select(User.id).where(func.lower(User.email) == payload.email.lower()))
    if exists:
        from fastapi import HTTPException
        raise HTTPException(status_code=409, detail="An account with this email already exists")
    user = User(email=payload.email, password_hash=hash_password(payload.password), full_name=payload.full_name, role=UserRole.analyst)
    db.add(user); db.commit(); db.refresh(user)
    return user
