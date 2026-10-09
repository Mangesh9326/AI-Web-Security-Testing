from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.auth import LoginRequest, TokenResponse
from app.schemas.user import UserCreate, UserResponse
from app.services.auth_service import create_access_token, register_user, verify_password
router = APIRouter(prefix="/auth", tags=["Authentication"])
@router.post("/register", response_model=UserResponse, status_code=201)
def register(payload: UserCreate, db: Session = Depends(get_db)): return register_user(db, payload)
@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(func.lower(User.email) == payload.email.strip().lower()))
    if not user or not user.is_active or not verify_password(payload.password, user.password_hash): raise HTTPException(status_code=401, detail="Incorrect email or password")
    user.last_login_at = datetime.now(timezone.utc); db.commit(); db.refresh(user)
    return TokenResponse(access_token=create_access_token(user), user=user)
@router.get("/me", response_model=UserResponse)
def me(current_user: User = Depends(get_current_user)): return current_user
