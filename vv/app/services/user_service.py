from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.user import UserUpdate
from app.services.auth_service import hash_password

def get_user_or_404(db: Session, user_id) -> User:
    user = db.get(User, user_id)
    if not user: raise HTTPException(status_code=404, detail="User not found")
    return user
def list_users(db: Session) -> list[User]: return list(db.scalars(select(User).order_by(User.created_at.desc())))
def update_user(db: Session, user: User, payload: UserUpdate) -> User:
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(user, "password_hash" if field == "password" else field, hash_password(value) if field == "password" else value)
    db.commit(); db.refresh(user); return user
def delete_user(db: Session, user: User) -> None:
    if user.scans: raise HTTPException(status_code=409, detail="Users with scan history cannot be deleted")
    db.delete(user); db.commit()
