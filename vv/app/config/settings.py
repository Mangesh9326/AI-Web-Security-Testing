"""Application configuration loaded from environment variables."""
from pathlib import Path
import os

from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parents[2] / ".env")


class Settings:
    app_name = "AI-WebSecTest API"
    api_prefix = "/api"
    database_url = os.getenv("DATABASE_URL", "postgresql+psycopg2://postgres:postgres@localhost:5432/ai_websectest")
    jwt_secret_key = os.getenv("JWT_SECRET_KEY", "")
    jwt_algorithm = os.getenv("JWT_ALGORITHM", "HS256")
    access_token_expire_minutes = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))

    def validate_security_settings(self) -> None:
        if not self.jwt_secret_key or self.jwt_secret_key == "change-me-in-production":
            raise RuntimeError("JWT_SECRET_KEY must be set to a strong value in .env")


settings = Settings()
