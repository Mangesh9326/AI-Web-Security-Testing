from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field, field_validator
from app.models.user import UserRole

class UserCreate(BaseModel):
    email: str = Field(max_length=320)
    password: str = Field(min_length=12, max_length=128)
    full_name: str | None = Field(default=None, max_length=200)
    @field_validator("email")
    @classmethod
    def valid_email(cls, value: str) -> str:
        value = value.strip().lower()
        if value.count("@") != 1 or value.startswith("@") or value.endswith("@"):
            raise ValueError("A valid email address is required")
        return value

class UserUpdate(BaseModel):
    full_name: str | None = Field(default=None, max_length=200)
    password: str | None = Field(default=None, min_length=12, max_length=128)
    is_active: bool | None = None

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID; email: str; full_name: str | None; role: UserRole; is_active: bool
    created_at: datetime; last_login_at: datetime | None
