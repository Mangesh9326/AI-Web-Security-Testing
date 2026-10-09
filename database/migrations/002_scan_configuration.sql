-- Scan configuration migration. Apply after 001_initial_schema.sql.
-- Safe to rerun after a failed attempt; the transaction rolls back on error.
BEGIN;

-- scan_risk_summary depends on scans.status; recreate it after conversion.
DROP VIEW IF EXISTS scan_risk_summary;

ALTER TABLE scans ALTER COLUMN scan_type DROP DEFAULT;
ALTER TABLE scans ALTER COLUMN scan_type TYPE VARCHAR(30) USING scan_type::text;
ALTER TABLE scans ALTER COLUMN scan_type SET DEFAULT 'standard';
ALTER TABLE scans ALTER COLUMN status DROP DEFAULT;
ALTER TABLE scans ALTER COLUMN status TYPE VARCHAR(20) USING status::text;
ALTER TABLE scans ALTER COLUMN status SET DEFAULT 'queued';

-- These legacy UI options were not represented in the original 001 schema.
ALTER TABLE scans ADD COLUMN IF NOT EXISTS spider BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS passive BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS scope_type VARCHAR(20) NOT NULL DEFAULT 'single_url';
ALTER TABLE scans ADD COLUMN IF NOT EXISTS authorization_confirmed BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS crawl_depth INTEGER NOT NULL DEFAULT 5 CHECK (crawl_depth BETWEEN 1 AND 20);
ALTER TABLE scans ADD COLUMN IF NOT EXISTS max_pages INTEGER NOT NULL DEFAULT 500 CHECK (max_pages BETWEEN 1 AND 10000);
ALTER TABLE scans ADD COLUMN IF NOT EXISTS request_delay_ms INTEGER NOT NULL DEFAULT 100 CHECK (request_delay_ms BETWEEN 0 AND 10000);
ALTER TABLE scans ADD COLUMN IF NOT EXISTS javascript_crawling BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS follow_redirects BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS security_checks JSONB NOT NULL DEFAULT '["security_headers"]'::jsonb;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS excluded_paths JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS authentication_type VARCHAR(20) NOT NULL DEFAULT 'none';
ALTER TABLE scans ADD COLUMN IF NOT EXISTS pages_discovered INTEGER NOT NULL DEFAULT 0;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS requests_analyzed INTEGER NOT NULL DEFAULT 0;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS endpoints_found INTEGER NOT NULL DEFAULT 0;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS error_message TEXT;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'scans_active_requires_authorization') THEN
    ALTER TABLE scans ADD CONSTRAINT scans_active_requires_authorization CHECK (NOT active OR authorization_confirmed);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'scans_status_valid') THEN
    ALTER TABLE scans ADD CONSTRAINT scans_status_valid CHECK (status IN ('queued','crawling','passive','active','analyzing','completed','failed','cancelled'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_scans_user_status_created_at ON scans (user_id, status, created_at DESC);

CREATE VIEW scan_risk_summary AS
SELECT s.id AS scan_id, s.user_id, s.target_url, s.status AS scan_status, s.created_at,
       COUNT(f.id) AS total_findings,
       COUNT(*) FILTER (WHERE f.severity = 'critical') AS critical_findings,
       COUNT(*) FILTER (WHERE f.severity = 'high') AS high_findings,
       COUNT(*) FILTER (WHERE f.severity = 'medium') AS medium_findings,
       COALESCE(MAX(f.cvss_score), 0) AS highest_cvss_score
FROM scans s LEFT JOIN findings f ON f.scan_id = s.id
GROUP BY s.id;

COMMIT;
