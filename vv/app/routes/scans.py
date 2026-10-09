from uuid import UUID
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.scan import ScanCreate, ScanResponse, ScanStatusResponse
from app.services import scan_service
router = APIRouter(prefix="/scans", tags=["Scans"])
@router.post("", response_model=ScanResponse, status_code=status.HTTP_201_CREATED)
def create_new_scan(payload: ScanCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)): return scan_service.create_scan(db, payload, current_user.id)
@router.get("", response_model=list[ScanResponse])
def list_scans(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)): return scan_service.get_scans(db, current_user)
@router.get("/{scan_id}", response_model=ScanResponse)
def get_single_scan(scan_id: UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    scan = scan_service.get_scan_or_404(db, scan_id); scan_service.ensure_scan_access(scan, current_user); return scan
@router.get("/{scan_id}/status", response_model=ScanStatusResponse)
def get_scan_status(scan_id: UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    scan = scan_service.get_scan_or_404(db, scan_id); scan_service.ensure_scan_access(scan, current_user)
    return ScanStatusResponse(id=scan.id, status=scan.status, progress_percent=scan_service.progress_percent(scan), pages_discovered=scan.pages_discovered, requests_analyzed=scan.requests_analyzed, endpoints_found=scan.endpoints_found, findings_count=scan.findings_count, started_at=scan.started_at, completed_at=scan.completed_at, error_message=scan.error_message)
@router.post("/{scan_id}/cancel", response_model=ScanResponse)
def cancel_scan(scan_id: UUID, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    scan = scan_service.get_scan_or_404(db, scan_id); scan_service.ensure_scan_access(scan, current_user); return scan_service.cancel_scan(db, scan)
