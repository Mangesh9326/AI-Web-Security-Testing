from uuid import UUID

from fastapi import APIRouter, Depends, Response
from sqlalchemy.orm import Session

from app.dependencies import get_current_user, get_db
from app.models.finding import FindingStatus, Severity
from app.models.user import User
from app.schemas.finding import (
    FindingCreate,
    FindingResponse,
    FindingUpdate,
)
from app.services import finding_service


router = APIRouter(
    prefix="/findings",
    tags=["Findings"],
)


# ---------------------------------------------------------
# CREATE FINDING
# Authentication remains enabled
# ---------------------------------------------------------
@router.post(
    "",
    response_model=FindingResponse,
    status_code=201,
)
def create(
    payload: FindingCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return finding_service.create_finding(
        db,
        user,
        payload,
    )


# ---------------------------------------------------------
# GET ALL FINDINGS
# Temporarily public for frontend/backend testing
# Login/Register NOT required
# ---------------------------------------------------------
@router.get(
    "",
    response_model=list[FindingResponse],
)
def list_all(
    severity: Severity | None = None,
    status: FindingStatus | None = None,
    scan_id: int | None = None,
    db: Session = Depends(get_db),
):
    return finding_service.list_findings(
        db,
        None,
        severity,
        status,
        scan_id,
    )


# ---------------------------------------------------------
# GET SINGLE FINDING
# Authentication remains enabled
# ---------------------------------------------------------
@router.get(
    "/{finding_id}",
    response_model=FindingResponse,
)
def get(
    finding_id: UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    finding = finding_service.get_finding_or_404(
        db,
        finding_id,
    )

    finding_service.ensure_finding_access(
        db,
        finding,
        user,
    )

    return finding


# ---------------------------------------------------------
# UPDATE FINDING
# Authentication remains enabled
# ---------------------------------------------------------
@router.put(
    "/{finding_id}",
    response_model=FindingResponse,
)
def update(
    finding_id: UUID,
    payload: FindingUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    finding = finding_service.get_finding_or_404(
        db,
        finding_id,
    )

    finding_service.ensure_finding_access(
        db,
        finding,
        user,
    )

    return finding_service.update_finding(
        db,
        finding,
        payload,
    )


# ---------------------------------------------------------
# DELETE FINDING
# Authentication remains enabled
# ---------------------------------------------------------
@router.delete(
    "/{finding_id}",
    status_code=204,
)
def delete(
    finding_id: UUID,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    finding = finding_service.get_finding_or_404(
        db,
        finding_id,
    )

    finding_service.ensure_finding_access(
        db,
        finding,
        user,
    )

    finding_service.delete_finding(
        db,
        finding,
    )

    return Response(status_code=204)


# ---------------------------------------------------------
# GET FINDINGS FOR A SCAN
# Authentication remains enabled for now
# ---------------------------------------------------------
@router.get(
    "/scan/{scan_id}",
    response_model=list[FindingResponse],
)
def for_scan(
    scan_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return finding_service.list_findings(
        db,
        user,
        None,
        None,
        scan_id,
    )