-- AI-WebSecTest: PostgreSQL initial schema
-- Apply with: psql -v ON_ERROR_STOP=1 -U postgres -d ai_websectest -f migrations/001_initial_schema.sql

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE user_role AS ENUM ('admin', 'analyst', 'viewer');
CREATE TYPE scan_status AS ENUM ('queued', 'running', 'completed', 'failed', 'cancelled');
CREATE TYPE scan_type AS ENUM ('passive', 'active', 'authenticated');
CREATE TYPE risk_severity AS ENUM ('info', 'low', 'medium', 'high', 'critical');
CREATE TYPE finding_status AS ENUM ('open', 'in_progress', 'resolved', 'accepted_risk', 'false_positive');
CREATE TYPE log_level AS ENUM ('debug', 'info', 'warning', 'error', 'security');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(320) NOT NULL,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(200),
    role user_role NOT NULL DEFAULT 'analyst',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT users_email_not_blank CHECK (length(btrim(email)) > 0)
);

CREATE UNIQUE INDEX uq_users_email_lower ON users (lower(email));

CREATE TABLE scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    target_url TEXT NOT NULL,
    scan_type scan_type NOT NULL DEFAULT 'active',
    status scan_status NOT NULL DEFAULT 'queued',
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    findings_count INTEGER NOT NULL DEFAULT 0 CHECK (findings_count >= 0),
    critical_count INTEGER NOT NULL DEFAULT 0 CHECK (critical_count >= 0),
    high_count INTEGER NOT NULL DEFAULT 0 CHECK (high_count >= 0),
    scan_config JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT scans_target_url_valid CHECK (target_url ~* '^https?://'),
    CONSTRAINT scans_completed_after_started CHECK (completed_at IS NULL OR started_at IS NULL OR completed_at >= started_at)
);

CREATE INDEX idx_scans_user_created_at ON scans (user_id, created_at DESC);
CREATE INDEX idx_scans_status_created_at ON scans (status, created_at DESC);

CREATE TABLE findings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID NOT NULL REFERENCES scans(id) ON DELETE CASCADE,
    vulnerability_type VARCHAR(150) NOT NULL,
    title VARCHAR(300) NOT NULL,
    description TEXT,
    severity risk_severity NOT NULL,
    cvss_score NUMERIC(3,1) CHECK (cvss_score BETWEEN 0.0 AND 10.0),
    cwe_id VARCHAR(20),
    affected_url TEXT,
    parameter_name VARCHAR(200),
    evidence JSONB NOT NULL DEFAULT '{}'::jsonb,
    remediation TEXT,
    status finding_status NOT NULL DEFAULT 'open',
    ai_confidence NUMERIC(4,3) CHECK (ai_confidence BETWEEN 0.000 AND 1.000),
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT findings_title_not_blank CHECK (length(btrim(title)) > 0),
    CONSTRAINT findings_resolved_at_valid CHECK (resolved_at IS NULL OR resolved_at >= detected_at)
);

CREATE INDEX idx_findings_scan_severity ON findings (scan_id, severity);
CREATE INDEX idx_findings_status_severity ON findings (status, severity);
CREATE INDEX idx_findings_cwe_id ON findings (cwe_id) WHERE cwe_id IS NOT NULL;

CREATE TABLE activity_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    scan_id UUID REFERENCES scans(id) ON DELETE SET NULL,
    level log_level NOT NULL DEFAULT 'info',
    action VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    ip_address INET,
    user_agent TEXT,
    details JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT activity_logs_action_not_blank CHECK (length(btrim(action)) > 0)
);

CREATE INDEX idx_activity_logs_created_at ON activity_logs (created_at DESC);
CREATE INDEX idx_activity_logs_user_created_at ON activity_logs (user_id, created_at DESC) WHERE user_id IS NOT NULL;
CREATE INDEX idx_activity_logs_scan_created_at ON activity_logs (scan_id, created_at DESC) WHERE scan_id IS NOT NULL;
CREATE INDEX idx_activity_logs_security_events ON activity_logs (created_at DESC) WHERE level IN ('warning', 'error', 'security');

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_set_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER scans_set_updated_at BEFORE UPDATE ON scans
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER findings_set_updated_at BEFORE UPDATE ON findings
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE OR REPLACE VIEW scan_risk_summary AS
SELECT
    s.id AS scan_id,
    s.user_id,
    s.target_url,
    s.status AS scan_status,
    s.created_at,
    COUNT(f.id) AS total_findings,
    COUNT(*) FILTER (WHERE f.severity = 'critical') AS critical_findings,
    COUNT(*) FILTER (WHERE f.severity = 'high') AS high_findings,
    COUNT(*) FILTER (WHERE f.severity = 'medium') AS medium_findings,
    COALESCE(MAX(f.cvss_score), 0) AS highest_cvss_score
FROM scans s
LEFT JOIN findings f ON f.scan_id = s.id
GROUP BY s.id;

COMMENT ON TABLE users IS 'Application accounts. Passwords must be stored only as strong one-way hashes.';
COMMENT ON TABLE scans IS 'Security scan executions initiated by users.';
COMMENT ON TABLE findings IS 'Vulnerabilities found during a scan, including AI classification metadata.';
COMMENT ON TABLE activity_logs IS 'Append-only audit and intrusion-detection event trail.';

COMMIT;
