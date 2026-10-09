# AI-WebSecTest database

PostgreSQL schema for Phase 2: users, scans, vulnerability findings, and audit/intrusion-detection logs.

## Data relationships

```text
users 1 ──< scans 1 ──< findings
  │           │
  └──────< activity_logs >──────┘
```

`activity_logs.user_id` and `activity_logs.scan_id` are optional so that failed or system-level events can still be recorded. Deleting a scan deletes its findings, while user deletion is blocked if scans exist to protect forensic history.

## Prerequisites

- PostgreSQL 15 or later
- A database named `ai_websectest`
- `psql` available on your PATH (or run the scripts from pgAdmin Query Tool)

Create the database once:

```powershell
psql -U postgres -c "CREATE DATABASE ai_websectest;"
```

## Apply

From this `database` directory, run:

```powershell
psql -v ON_ERROR_STOP=1 -U postgres -d ai_websectest -f migrations/001_initial_schema.sql
cd ..\backend
.\venv\Scripts\python.exe .\seed_data.py
```

The seed is optional and intended only for local development. It creates a bcrypt-hashed account that can be used with the login page, plus a completed scan, finding, and audit log. The default credentials are `analyst@example.test` / `DemoPassword123!`; override them with `--email` and `--password`.

## Design notes

- UUIDs prevent predictable public identifiers for users, scans, and findings.
- PostgreSQL enums constrain status and severity values.
- `JSONB` holds evolving scanner evidence, configuration, and AI metadata without weakening the core relational design.
- Indexes support the most common dashboard, scan-history, finding-triage, and security-event queries.
- `scan_risk_summary` is a read-only view for risk-prioritization dashboards.

## Verify

```powershell
psql -U postgres -d ai_websectest -c "SELECT * FROM scan_risk_summary;"
psql -U postgres -d ai_websectest -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;"
```
