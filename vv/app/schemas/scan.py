from datetime import datetime
import ipaddress
from typing import Literal
from uuid import UUID
from pydantic import AnyHttpUrl, BaseModel, ConfigDict, Field, field_validator, model_validator

SECURITY_CHECKS = {"sql_injection", "xss", "csrf", "security_headers", "authentication", "authorization", "ssl_tls", "information_disclosure", "sensitive_data_exposure", "security_misconfiguration"}
class ScanCreate(BaseModel):
    target_url: AnyHttpUrl
    scan_type: Literal["quick", "standard", "full", "passive", "api"] = "standard"
    scope_type: Literal["single_url", "domain"] = "single_url"
    excluded_paths: list[str] = Field(default_factory=list, max_length=100)
    spider: bool = True; passive: bool = True; active: bool = False; authorization_confirmed: bool = False
    crawl_depth: int = Field(default=5, ge=1, le=20); max_pages: int = Field(default=500, ge=1, le=10000); request_delay_ms: int = Field(default=100, ge=0, le=10000)
    javascript_crawling: bool = True; follow_redirects: bool = True
    security_checks: list[str] = Field(default_factory=lambda: ["security_headers"], min_length=1, max_length=10)
    authentication_type: Literal["none", "username_password", "bearer_token", "cookie"] = "none"
    authentication: dict[str, str] | None = Field(default=None, exclude=True)
    request_timeout_seconds: int = Field(default=30, ge=1, le=300); max_concurrent_requests: int = Field(default=5, ge=1, le=20)
    user_agent: str | None = Field(default=None, max_length=512); custom_headers: dict[str, str] = Field(default_factory=dict, max_length=30)
    @field_validator("target_url")
    @classmethod
    def http_target(cls, value):
        if value.scheme not in {"http", "https"} or not value.host: raise ValueError("Please enter a valid HTTP/HTTPS URL")
        try:
            address = ipaddress.ip_address(value.host)
            if address.is_private or address.is_loopback or address.is_link_local:
                raise ValueError("Private, loopback, and link-local targets are not allowed")
        except ValueError as error:
            if "not allowed" in str(error): raise
        return value
    @field_validator("excluded_paths")
    @classmethod
    def safe_exclusions(cls, values):
        if any(not value.strip() or len(value) > 500 for value in values): raise ValueError("Excluded paths must be non-empty and at most 500 characters")
        return [value.strip() for value in values]
    @field_validator("security_checks")
    @classmethod
    def supported_checks(cls, values):
        if len(set(values)) != len(values) or any(value not in SECURITY_CHECKS for value in values): raise ValueError("Unsupported or duplicate security check")
        return values
    @field_validator("custom_headers")
    @classmethod
    def non_sensitive_headers(cls, values):
        forbidden = {"authorization", "cookie", "x-api-key", "proxy-authorization"}
        if any(not key.strip() or key.lower() in forbidden or len(key) > 200 or len(value) > 2000 for key, value in values.items()):
            raise ValueError("Custom headers cannot contain credentials or invalid values")
        return values
    @model_validator(mode="after")
    def validate_authorization(self):
        if self.active and not self.authorization_confirmed: raise ValueError("Active scanning requires authorization confirmation")
        return self
class ScanResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID; target_url: str; scan_type: str; scope_type: str; status: str; spider: bool; passive: bool; active: bool; authorization_confirmed: bool; crawl_depth: int; max_pages: int; request_delay_ms: int; javascript_crawling: bool; follow_redirects: bool; security_checks: list[str]; excluded_paths: list[str]; authentication_type: str; started_at: datetime | None; completed_at: datetime | None; pages_discovered: int; requests_analyzed: int; endpoints_found: int; findings_count: int; error_message: str | None; created_at: datetime
class ScanStatusResponse(BaseModel):
    id: UUID; status: str; progress_percent: int; pages_discovered: int; requests_analyzed: int; endpoints_found: int; findings_count: int; started_at: datetime | None; completed_at: datetime | None; error_message: str | None
