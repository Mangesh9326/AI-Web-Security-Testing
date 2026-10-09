from uuid import UUID
from fastapi import APIRouter, Depends, Response
from sqlalchemy.orm import Session
from app.dependencies import get_current_user, get_db, require_admin
from app.models.user import User
from app.schemas.user import UserResponse, UserUpdate
from app.services import user_service
router = APIRouter(prefix="/users", tags=["Users"])
@router.get("", response_model=list[UserResponse])
def users(db: Session = Depends(get_db), _: User = Depends(require_admin)): return user_service.list_users(db)
@router.get("/{user_id}", response_model=UserResponse)
def user(user_id: UUID, db: Session = Depends(get_db), current: User = Depends(get_current_user)):
    target = user_service.get_user_or_404(db, user_id)
    if current.role != "admin" and current.id != target.id: from fastapi import HTTPException; raise HTTPException(status_code=403, detail="Not authorized")
    return target
@router.put("/{user_id}", response_model=UserResponse)
def update(user_id: UUID, payload: UserUpdate, db: Session = Depends(get_db), current: User = Depends(get_current_user)):
    target = user_service.get_user_or_404(db, user_id)
    if current.role != "admin" and current.id != target.id: from fastapi import HTTPException; raise HTTPException(status_code=403, detail="Not authorized")
    if current.role != "admin" and payload.is_active is not None: from fastapi import HTTPException; raise HTTPException(status_code=403, detail="Only administrators can change account status")
    return user_service.update_user(db, target, payload)
@router.delete("/{user_id}", status_code=204)
def delete(user_id: UUID, db: Session = Depends(get_db), _: User = Depends(require_admin)): user_service.delete_user(db, user_service.get_user_or_404(db, user_id)); return Response(status_code=204)
