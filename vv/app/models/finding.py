import enum
import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any

from sqlalchemy import (
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.config.database import Base


class Severity(str, enum.Enum):
    info = "info"
    low = "low"
    medium = "medium"
    high = "high"
    critical = "critical"


class FindingStatus(str, enum.Enum):
    open = "open"
    in_progress = "in_progress"
    resolved = "resolved"
    accepted_risk = "accepted_risk"
    false_positive = "false_positive"


class Finding(Base):
    __tablename__ = "findings"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
    )

    scan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("scans.id"),
        nullable=False,
        index=True,
    )

    vulnerability_type: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
    )

    title: Mapped[str] = mapped_column(
        String(300),
        nullable=False,
    )

    description: Mapped[str | None] = mapped_column(
        Text,
    )

    severity: Mapped[Severity] = mapped_column(
        Enum(
            Severity,
            name="risk_severity",
            create_type=False,
        ),
        nullable=False,
    )

    cvss_score: Mapped[Decimal | None] = mapped_column(
        Numeric(3, 1),
    )

    cwe_id: Mapped[str | None] = mapped_column(
        String(20),
    )

    affected_url: Mapped[str | None] = mapped_column(
        Text,
    )

    parameter_name: Mapped[str | None] = mapped_column(
        String(200),
    )

    evidence: Mapped[dict[str, Any]] = mapped_column(
        JSONB,
        default=dict,
        nullable=False,
    )

    remediation: Mapped[str | None] = mapped_column(
        Text,
    )

    status: Mapped[FindingStatus] = mapped_column(
        Enum(
            FindingStatus,
            name="finding_status",
            create_type=False,
        ),
        default=FindingStatus.open,
        nullable=False,
    )

    ai_confidence: Mapped[Decimal | None] = mapped_column(
        Numeric(4, 3),
    )

    detected_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    resolved_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    scan: Mapped["Scan"] = relationship(
        back_populates="findings",
    )
