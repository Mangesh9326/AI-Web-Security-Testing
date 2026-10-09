from datetime import datetime
from decimal import Decimal
from typing import Any
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field
from app.models.finding import FindingStatus, Severity
class FindingCreate(BaseModel):
    scan_id: UUID; vulnerability_type: str = Field(min_length=1, max_length=150); title: str = Field(min_length=1, max_length=300)
    description: str | None = None; severity: Severity; cvss_score: Decimal | None = Field(default=None, ge=0, le=10)
    cwe_id: str | None = Field(default=None, max_length=20); affected_url: str | None = None; parameter_name: str | None = Field(default=None, max_length=200)
    evidence: dict[str, Any] = Field(default_factory=dict); remediation: str | None = None; ai_confidence: Decimal | None = Field(default=None, ge=0, le=1)
class FindingUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=300); description: str | None = None; severity: Severity | None = None
    cvss_score: Decimal | None = Field(default=None, ge=0, le=10); remediation: str | None = None; status: FindingStatus | None = None; ai_confidence: Decimal | None = Field(default=None, ge=0, le=1)
class FindingResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID; scan_id: UUID; vulnerability_type: str; title: str; description: str | None; severity: Severity; cvss_score: Decimal | None
    cwe_id: str | None; status: FindingStatus; ai_confidence: Decimal | None; detected_at: datetime; created_at: datetime
