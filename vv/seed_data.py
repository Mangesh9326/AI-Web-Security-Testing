"""Create idempotent local-development data for AI-WebSecTest.

Run after applying database/migrations/001_initial_schema.sql.  The script uses
the DATABASE_URL in backend/.env and never runs automatically in the API.
"""

from __future__ import annotations

import argparse
import uuid

from sqlalchemy import text

from app.config.database import engine
from app.services.auth_service import hash_password


DEMO_EMAIL = "analyst@example.test"
DEMO_NAME = "Demo Security Analyst"
DEMO_TARGET = "https://demo.example.test"
DEMO_USERNAME = "demo_analyst"


def columns_for(connection, table_name: str) -> set[str]:
    """Return the columns present in the currently installed PostgreSQL table."""
    return set(
        connection.scalars(
            text(
                """
                SELECT column_name
                FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = :table_name
                """
            ),
            {"table_name": table_name},
        )
    )


def seed(email: str, password: str) -> None:
    """Upsert one analyst, scan, finding, and audit record for local use."""
    with engine.begin() as connection:
        user_columns = columns_for(connection, "users")
        scan_columns = columns_for(connection, "scans")
        finding_columns = columns_for(connection, "findings")

        user_id = connection.scalar(
            text(
                """
                SELECT id FROM users
                WHERE lower(email) = lower(:email)
                ORDER BY created_at ASC
                LIMIT 1
                """
            ),
            {"email": email},
        )
        password_hash = hash_password(password)
        if user_id is None:
            if "username" in user_columns:
                user_id = connection.scalar(
                    text(
                        """
                        INSERT INTO users (username, email, password_hash, full_name, role)
                        VALUES (:username, :email, :password_hash, :full_name, 'analyst')
                        RETURNING id
                        """
                    ),
                    {"username": DEMO_USERNAME, "email": email.lower(), "password_hash": password_hash, "full_name": DEMO_NAME},
                )
            else:
                user_id = connection.scalar(
                    text(
                        """
                        INSERT INTO users (email, password_hash, full_name, role)
                        VALUES (:email, :password_hash, :full_name, 'analyst')
                        RETURNING id
                        """
                    ),
                    {"email": email.lower(), "password_hash": password_hash, "full_name": DEMO_NAME},
                )
        else:
            assignments = "email = :email, password_hash = :password_hash, full_name = :full_name, role = 'analyst'"
            if "username" in user_columns:
                assignments = "username = :username, " + assignments
            if "is_active" in user_columns:
                assignments += ", is_active = TRUE"
            connection.execute(
                text(f"UPDATE users SET {assignments} WHERE id = :user_id"),
                {
                    "username": DEMO_USERNAME,
                    "email": email.lower(),
                    "password_hash": password_hash,
                    "full_name": DEMO_NAME,
                    "user_id": user_id,
                },
            )

        scan_id = connection.scalar(
            text(
                """
                SELECT id FROM scans
                WHERE user_id = :user_id AND target_url = :target_url
                ORDER BY created_at DESC
                LIMIT 1
                """
            ),
            {"user_id": user_id, "target_url": DEMO_TARGET},
        )
        if scan_id is None and "started_at" in scan_columns:
            scan_id = connection.scalar(
                text(
                    """
                    INSERT INTO scans (
                        user_id, target_url, scan_type, status, started_at,
                        completed_at, findings_count, critical_count, high_count,
                        scan_config
                    )
                    VALUES (
                        :user_id, :target_url, 'active', 'completed',
                        NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '3 minutes',
                        1, 0, 1, CAST(:scan_config AS jsonb)
                    )
                    RETURNING id
                    """
                ),
                {
                    "user_id": user_id,
                    "target_url": DEMO_TARGET,
                    "scan_config": '{"depth": 2, "ai_classification": true}',
                },
            )
        elif scan_id is None:
            scan_id = connection.scalar(
                text(
                    """
                    INSERT INTO scans (user_id, target_url, scan_type, spider, passive, active, status)
                    VALUES (:user_id, :target_url, 'Web Application Scan', TRUE, TRUE, FALSE, 'completed')
                    RETURNING id
                    """
                ),
                {"user_id": user_id, "target_url": DEMO_TARGET},
            )

        finding_insert_columns = "scan_id, vulnerability_type, title, description, severity, cvss_score, cwe_id, affected_url, parameter_name, evidence, remediation, ai_confidence"
        finding_insert_values = ":scan_id, 'SQL Injection', 'Unsanitized search parameter', 'Demo finding for development validation.', 'high', 8.1, 'CWE-89', :affected_url, 'q', CAST(:evidence AS jsonb), 'Use parameterized queries and server-side input validation.', 0.943"
        finding_parameters = {
            "scan_id": scan_id,
            "affected_url": f"{DEMO_TARGET}/search",
            "evidence": '{"payload": "test payload", "http_status": 500}',
        }
        if "id" in finding_columns:
            finding_insert_columns = "id, " + finding_insert_columns
            finding_insert_values = ":finding_id, " + finding_insert_values
            finding_parameters["finding_id"] = uuid.uuid4()
        if "status" in finding_columns:
            finding_insert_columns += ", status"
            finding_insert_values += ", 'open'"

        connection.execute(
            text(
                f"""
                INSERT INTO findings ({finding_insert_columns})
                SELECT
                    {finding_insert_values}
                WHERE NOT EXISTS (
                    SELECT 1 FROM findings
                    WHERE scan_id = :scan_id
                      AND title = 'Unsanitized search parameter'
                )
                """
            ),
            finding_parameters,
        )

        connection.execute(
            text(
                """
                INSERT INTO activity_logs (user_id, scan_id, level, action, message, details)
                SELECT :user_id, :scan_id, 'info', 'seed.created',
                       'Development seed data applied.', CAST(:details AS jsonb)
                WHERE NOT EXISTS (
                    SELECT 1 FROM activity_logs
                    WHERE user_id = :user_id AND action = 'seed.created'
                )
                """
            ),
            {
                "user_id": user_id,
                "scan_id": scan_id,
                "details": '{"source": "backend/seed_data.py"}',
            },
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed local AI-WebSecTest demo data.")
    parser.add_argument("--email", default=DEMO_EMAIL, help=f"Demo account email (default: {DEMO_EMAIL})")
    parser.add_argument(
        "--password",
        default="DemoPassword123!",
        help="Demo account password (default: DemoPassword123!). Use a different value outside local development.",
    )
    args = parser.parse_args()

    if len(args.password) < 12:
        parser.error("--password must be at least 12 characters")

    seed(args.email, args.password)
    print(f"Seeded local demo account: {args.email.lower()}")


if __name__ == "__main__":
    main()
