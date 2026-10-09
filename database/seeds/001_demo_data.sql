-- Development-only sample data. Do not use the password hash in production.
-- Apply after the initial migration.

BEGIN;

INSERT INTO users (email, password_hash, full_name, role)
VALUES ('analyst@example.test', '$2b$12$development.only.replace.this.hash', 'Demo Security Analyst', 'analyst')
ON CONFLICT (lower(email)) DO UPDATE
SET full_name = EXCLUDED.full_name,
    role = EXCLUDED.role;

WITH demo_user AS (
    SELECT id FROM users WHERE lower(email) = 'analyst@example.test'
), inserted_scan AS (
    INSERT INTO scans (user_id, target_url, scan_type, status, started_at, completed_at, findings_count, critical_count, high_count, scan_config)
    SELECT id, 'https://demo.example.test', 'active', 'completed', NOW() - INTERVAL '5 minutes', NOW() - INTERVAL '3 minutes', 2, 0, 1,
           '{"depth": 2, "ai_classification": true}'::jsonb
    FROM demo_user
    WHERE NOT EXISTS (SELECT 1 FROM scans WHERE target_url = 'https://demo.example.test')
    RETURNING id, user_id
)
INSERT INTO findings (scan_id, vulnerability_type, title, description, severity, cvss_score, cwe_id, affected_url, parameter_name, evidence, remediation, ai_confidence)
SELECT id, 'SQL Injection', 'Unsanitized search parameter', 'Demo finding for development validation.', 'high', 8.1, 'CWE-89',
       'https://demo.example.test/search', 'q', '{"payload": "test payload", "http_status": 500}'::jsonb,
       'Use parameterized queries and server-side input validation.', 0.943
FROM inserted_scan;

INSERT INTO activity_logs (user_id, level, action, message, details)
SELECT id, 'info', 'seed.created', 'Development seed data applied.', '{"source": "database/seeds/001_demo_data.sql"}'::jsonb
FROM users
WHERE lower(email) = 'analyst@example.test';

COMMIT;
