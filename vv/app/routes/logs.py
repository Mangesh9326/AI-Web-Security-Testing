from uuid import UUID
from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.log import LogCreate, LogResponse
from app.services import log_service
router = APIRouter(prefix="/logs", tags=["Audit logs"])
@router.post("", response_model=LogResponse, status_code=201)
def create(payload: LogCreate, request: Request, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    client_ip = request.client.host if request.client else None
    return log_service.create_log(db, user, payload, client_ip, request.headers.get("user-agent"))
@router.get("", response_model=list[LogResponse])
def list_all(action: str | None = None, scan_id: UUID | None = None, db: Session = Depends(get_db), user: User = Depends(get_current_user)): return log_service.list_logs(db, user, action, scan_id)
@router.get("/{log_id}", response_model=LogResponse)
def get(log_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)): return log_service.get_log_or_404(db, user, log_id)
