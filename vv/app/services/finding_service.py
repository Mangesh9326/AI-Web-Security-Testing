from datetime import datetime, timezone

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.finding import Finding, FindingStatus, Severity
from app.models.scan import Scan
from app.models.user import User
from app.schemas.finding import FindingCreate, FindingUpdate
from app.services.scan_service import (
    ensure_scan_access,
    get_scan_or_404,
)


def get_finding_or_404(db: Session, finding_id) -> Finding:
    finding = db.get(Finding, finding_id)

    if not finding:
        raise HTTPException(
            status_code=404,
            detail="Finding not found",
        )

    return finding


def ensure_finding_access(
    db: Session,
    finding: Finding,
    user: User,
) -> Scan:
    scan = get_scan_or_404(db, finding.scan_id)
    ensure_scan_access(scan, user)
    return scan


def create_finding(
    db: Session,
    user: User,
    payload: FindingCreate,
) -> Finding:
    scan = get_scan_or_404(db, payload.scan_id)

    ensure_scan_access(scan, user)

    finding = Finding(
        **payload.model_dump()
    )

    db.add(finding)
    db.flush()

    # Update scan counters only if these fields exist
    if hasattr(scan, "findings_count"):
        scan.findings_count += 1

    if (
        finding.severity == Severity.critical
        and hasattr(scan, "critical_count")
    ):
        scan.critical_count += 1

    if (
        finding.severity == Severity.high
        and hasattr(scan, "high_count")
    ):
        scan.high_count += 1

    db.commit()
    db.refresh(finding)

    return finding


def list_findings(
    db: Session,
    user: User | None,
    severity: Severity | None,
    finding_status: FindingStatus | None,
    scan_id=None,
) -> list[Finding]:

    statement = (
        select(Finding)
        .join(Scan)
        .order_by(Finding.created_at.desc())
    )

    # Authentication is temporarily optional while we test
    # the frontend/backend connection.
    #
    # If a user is supplied, keep the normal access restriction.
    if user is not None and user.role != "admin":
        statement = statement.where(
            Scan.user_id == user.id
        )

    if severity:
        statement = statement.where(
            Finding.severity == severity
        )

    if finding_status:
        statement = statement.where(
            Finding.status == finding_status
        )

    if scan_id:
        statement = statement.where(
            Finding.scan_id == scan_id
        )

    return list(db.scalars(statement))


def update_finding(
    db: Session,
    finding: Finding,
    payload: FindingUpdate,
) -> Finding:

    for key, value in payload.model_dump(
        exclude_unset=True
    ).items():
        setattr(finding, key, value)

    if (
        finding.status == FindingStatus.resolved
        and finding.resolved_at is None
    ):
        finding.resolved_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(finding)

    return finding


def delete_finding(
    db: Session,
    finding: Finding,
) -> None:

    scan = get_scan_or_404(
        db,
        finding.scan_id,
    )

    if (
        finding.severity == Severity.critical
        and hasattr(scan, "critical_count")
    ):
        scan.critical_count = max(
            0,
            scan.critical_count - 1,
        )

    if (
        finding.severity == Severity.high
        and hasattr(scan, "high_count")
    ):
        scan.high_count = max(
            0,
            scan.high_count - 1,
        )

    if hasattr(scan, "findings_count"):
        scan.findings_count = max(
            0,
            scan.findings_count - 1,
        )

    db.delete(finding)
    db.commit()