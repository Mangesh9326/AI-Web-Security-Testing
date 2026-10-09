from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.models.log import ActivityLog
from app.models.scan import Scan
from app.models.user import User
from app.schemas.log import LogCreate

def create_log(db: Session, user: User, payload: LogCreate, ip_address: str | None = None, user_agent: str | None = None) -> ActivityLog:
    if payload.scan_id:
        scan = db.get(Scan, payload.scan_id)
        if not scan: raise HTTPException(status_code=404, detail="Scan not found")
        if user.role != "admin" and scan.user_id != user.id: raise HTTPException(status_code=403, detail="You are not authorized to log against this scan")
    entry = ActivityLog(user_id=user.id, ip_address=ip_address, user_agent=user_agent, **payload.model_dump())
    db.add(entry); db.commit(); db.refresh(entry); return entry
def list_logs(db: Session, user: User, action: str | None, scan_id=None) -> list[ActivityLog]:
    statement = select(ActivityLog).order_by(ActivityLog.created_at.desc())
    if user.role != "admin": statement = statement.where(ActivityLog.user_id == user.id)
    if action: statement = statement.where(ActivityLog.action == action)
    if scan_id: statement = statement.where(ActivityLog.scan_id == scan_id)
    return list(db.scalars(statement))
def get_log_or_404(db: Session, user: User, log_id: int) -> ActivityLog:
    entry = db.get(ActivityLog, log_id)
    if not entry: raise HTTPException(status_code=404, detail="Log entry not found")
    if user.role != "admin" and entry.user_id != user.id: raise HTTPException(status_code=403, detail="You are not authorized to access this log")
    return entry
