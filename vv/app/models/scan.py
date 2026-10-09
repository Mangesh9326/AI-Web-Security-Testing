import uuid
from datetime import datetime
from typing import Any
from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.config.database import Base

class Scan(Base):
    __tablename__ = "scans"
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    target_url: Mapped[str] = mapped_column(Text, nullable=False)
    scan_type: Mapped[str] = mapped_column(String(30), nullable=False, default="standard")
    scope_type: Mapped[str] = mapped_column(String(20), nullable=False, default="single_url")
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="queued", index=True)
    spider: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    passive: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    authorization_confirmed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    crawl_depth: Mapped[int] = mapped_column(Integer, nullable=False, default=5)
    max_pages: Mapped[int] = mapped_column(Integer, nullable=False, default=500)
    request_delay_ms: Mapped[int] = mapped_column(Integer, nullable=False, default=100)
    javascript_crawling: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    follow_redirects: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    security_checks: Mapped[list[str]] = mapped_column(JSONB, nullable=False, default=list)
    excluded_paths: Mapped[list[str]] = mapped_column(JSONB, nullable=False, default=list)
    authentication_type: Mapped[str] = mapped_column(String(20), nullable=False, default="none")
    scan_config: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False, default=dict)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    pages_discovered: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    requests_analyzed: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    endpoints_found: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    findings_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    error_message: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    user: Mapped["User"] = relationship(back_populates="scans")
    findings: Mapped[list["Finding"]] = relationship(back_populates="scan", cascade="all, delete-orphan")
