from uuid import UUID
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.models.scan import Scan
from app.schemas.scan import ScanCreate

RUNNING = ("queued", "crawling", "passive", "active", "analyzing")
def create_scan(db: Session, data: ScanCreate, user_id: UUID) -> Scan:
    if db.scalar(select(Scan.id).where(Scan.user_id == user_id, Scan.target_url == str(data.target_url), Scan.status.in_(RUNNING))): raise HTTPException(status_code=409, detail="A scan for this target is already running")
    config = {"scope": {"type": data.scope_type, "excluded_paths": data.excluded_paths}, "crawler": {"depth": data.crawl_depth, "max_pages": data.max_pages, "delay_ms": data.request_delay_ms, "javascript": data.javascript_crawling, "follow_redirects": data.follow_redirects}, "security_checks": data.security_checks, "advanced": {"request_timeout_seconds": data.request_timeout_seconds, "max_concurrent_requests": data.max_concurrent_requests, "user_agent": data.user_agent, "custom_headers": data.custom_headers}}
    scan = Scan(user_id=user_id, target_url=str(data.target_url), scan_type=data.scan_type, scope_type=data.scope_type, spider=data.spider, passive=data.passive, active=data.active, authorization_confirmed=data.authorization_confirmed, crawl_depth=data.crawl_depth, max_pages=data.max_pages, request_delay_ms=data.request_delay_ms, javascript_crawling=data.javascript_crawling, follow_redirects=data.follow_redirects, security_checks=data.security_checks, excluded_paths=data.excluded_paths, authentication_type=data.authentication_type, scan_config=config, status="queued")
    db.add(scan); db.commit(); db.refresh(scan); return scan
def get_scan_or_404(db: Session, scan_id: UUID) -> Scan:
    scan = db.scalar(select(Scan).where(Scan.id == scan_id))
    if not scan: raise HTTPException(status_code=404, detail="Scan not found")
    return scan
def ensure_scan_access(scan: Scan, user) -> None:
    if user.role != "admin" and scan.user_id != user.id: raise HTTPException(status_code=403, detail="You do not have access to this scan")
def get_scans(db: Session, user):
    query = select(Scan).order_by(Scan.created_at.desc())
    if user.role != "admin": query = query.where(Scan.user_id == user.id)
    return list(db.scalars(query))
def cancel_scan(db: Session, scan: Scan) -> Scan:
    if scan.status not in RUNNING: raise HTTPException(status_code=409, detail="Only queued or running scans can be cancelled")
    scan.status = "cancelled"; db.commit(); db.refresh(scan); return scan
def progress_percent(scan: Scan) -> int:
    return {"queued": 0, "crawling": 20, "passive": 45, "active": 65, "analyzing": 85, "completed": 100}.get(scan.status, 0)
