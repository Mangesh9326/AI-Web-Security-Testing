# AI-WebSecTest Phase 3 backend

FastAPI REST API for authentication and the database business layer. It uses the existing Phase 2 PostgreSQL schema; it does not create, recreate, scan, classify, or calculate risk.

## Architecture

`React -> route -> Pydantic schema -> service -> SQLAlchemy model -> PostgreSQL`.

- Routes define HTTP paths, status codes, and dependencies.
- Schemas validate input and define safe response payloads.
- Models map the existing database tables.
- Services hold database transactions and authorization checks.
- Dependencies create one SQLAlchemy session per request and close it afterward.

Sessions group work into a transaction. `commit()` makes successful changes durable; an uncommitted or failed request is rolled back by the database. The request-scoped session is then closed, returning its connection to the pool.

## Security

Passwords are bcrypt hashes, never plaintext. Plaintext passwords expose every account if the database leaks. Bcrypt stores a salted, deliberately slow one-way hash; login hashes the submitted password using the stored hash's salt and compares the result. `password_hash`, JWT secrets, and database credentials are never returned by the API.

JWT access tokens expire after the configured interval. Put a strong random `JWT_SECRET_KEY` and the real database URL in `.env`; do not commit that file.

## Run

```powershell
cd C:\Users\Admin\Desktop\AI-WebSecTest\backend
.\venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

Open `http://127.0.0.1:8000/docs`.

Before starting the API against a new database, apply both schema migrations in pgAdmin Query Tool or with `psql`:

```powershell
psql -v ON_ERROR_STOP=1 -U postgres -d ai_websectest -f ..\database\migrations\001_initial_schema.sql
psql -v ON_ERROR_STOP=1 -U postgres -d ai_websectest -f ..\database\migrations\002_scan_configuration.sql
```

1. Call `POST /api/auth/register`.
2. Call `POST /api/auth/login` and copy `access_token`.
3. Click **Authorize** in Swagger and enter `Bearer <access_token>`.
4. Call `/api/auth/me`, then create/list scans, findings, and logs.

### Local demo data

Apply the database migration first, then seed a reusable local demo account:

```powershell
cd C:\Users\Admin\Desktop\AI-WebSecTest\backend
.\venv\Scripts\python.exe .\seed_data.py
```

The default account is `analyst@example.test` with password `DemoPassword123!`.
Use `--email` and `--password` to override these values. This script is for local development only; it upserts the demo account and adds a scan, a finding, and an activity log only when they do not already exist.

Routes enforce ownership: analysts see their own scans/findings/logs; admins can see all records and manage users. Invalid bodies return 422, missing authentication returns 401, unauthorized ownership returns 403, missing records return 404, and duplicate registration returns 409. The database health route returns 503 without exposing connection details.

## API routes

- `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me`
- `GET|PUT /api/users/{user_id}`, admin `GET /api/users`, `DELETE /api/users/{user_id}`
- `POST|GET /api/scans`, `GET|PUT|DELETE /api/scans/{scan_id}`
- `POST|GET /api/findings`, `GET|PUT|DELETE /api/findings/{finding_id}`, `GET /api/findings/scan/{scan_id}`
- `POST|GET /api/logs`, `GET /api/logs/{log_id}`
- `GET /api/health`, `GET /api/database-test`
