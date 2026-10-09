from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.config.database import SessionLocal
from app.config.settings import settings
from app.routes import auth, findings, logs, scans, users


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    description="Phase 3 REST API for AI-WebSecTest"
)


# ============================================================
# CORS MIDDLEWARE
# ============================================================

origins = [
    "http://localhost:5173",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=[
        "GET",
        "POST",
        "PUT",
        "PATCH",
        "DELETE",
        "OPTIONS",
    ],
    allow_headers=[
        "Content-Type",
        "Authorization",
    ],
)


# ============================================================
# API ROUTES
# ============================================================

app.include_router(
    auth.router,
    prefix=settings.api_prefix,
)

app.include_router(
    users.router,
    prefix=settings.api_prefix,
)

app.include_router(
    scans.router,
    prefix=settings.api_prefix,
)

app.include_router(
    findings.router,
    prefix=settings.api_prefix,
)

app.include_router(
    logs.router,
    prefix=settings.api_prefix,
)


# ============================================================
# HEALTH CHECK
# ============================================================

@app.get(
    "/api/health",
    tags=["System"],
)
def health():
    return {
        "status": "ok",
        "service": "ai-websectest-api",
    }


# ============================================================
# DATABASE CONNECTION TEST
# ============================================================

@app.get(
    "/api/database-test",
    tags=["System"],
)
def database_test():
    try:
        with SessionLocal() as db:
            db.execute(text("SELECT 1"))

    except SQLAlchemyError:
        return JSONResponse(
            status_code=503,
            content={
                "status": "unavailable",
                "detail": "Database connection failed",
            },
        )

    return {
        "status": "ok",
        "detail": "Database connection successful",
    }