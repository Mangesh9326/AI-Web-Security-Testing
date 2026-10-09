import enum
from datetime import datetime
from typing import Any

from sqlalchemy import BigInteger, DateTime, Enum, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import INET, JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.config.database import Base


class LogLevel(str, enum.Enum):
    debug = "debug"
    info = "info"
    warning = "warning"
    error = "error"
    security = "security"


class ActivityLog(Base):
    __tablename__ = "activity_logs"

    id: Mapped[int] = mapped_column(
        BigInteger,
        primary_key=True
    )

    user_id: Mapped[UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id"),
        nullable=True
    )

    scan_id: Mapped[UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("scans.id"),
        nullable=True
    )

    level: Mapped[LogLevel] = mapped_column(
        Enum(
            LogLevel,
            name="log_level",
            create_type=False
        ),
        default=LogLevel.info,
        nullable=False
    )

    action: Mapped[str] = mapped_column(
        String(150),
        nullable=False
    )

    message: Mapped[str] = mapped_column(
        Text,
        nullable=False
    )

    ip_address: Mapped[str | None] = mapped_column(
        INET
    )

    user_agent: Mapped[str | None] = mapped_column(
        Text
    )

    details: Mapped[dict[str, Any]] = mapped_column(
        JSONB,
        default=dict,
        nullable=False
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    user: Mapped["User | None"] = relationship(
        back_populates="logs"
    )
