from datetime import datetime
from typing import Any
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field
from app.models.log import LogLevel
class LogCreate(BaseModel):
    scan_id: UUID | None = None; level: LogLevel = LogLevel.info; action: str = Field(min_length=1, max_length=150); message: str = Field(min_length=1)
    details: dict[str, Any] = Field(default_factory=dict)
class LogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int; user_id: UUID | None; scan_id: UUID | None; level: LogLevel; action: str; message: str; details: dict[str, Any]; created_at: datetime
