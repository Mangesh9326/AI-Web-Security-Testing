# AI-WebSecTest frontend (Phase 4)

React/Vite dashboard for the existing FastAPI API. It does not change the database or implement scanning, AI, intrusion detection, risk calculations, or reporting.

## Structure

- `components/` – reusable layout, state, badge, and route-protection UI.
- `pages/` – authenticated screens for overview, scans, findings, logs, and profile; plus login/register.
- `services/` – the only layer that calls Axios/FastAPI.
- `context/` and `hooks/` – request-safe authentication state.
- `utils/` – formatting and API-aligned option values.

## Run

```powershell
cd C:\Users\Admin\Desktop\AI-WebSecTest\frontend
npm run dev
```

The UI defaults to `http://127.0.0.1:8000/api`. Copy `.env.example` to `.env` only to point at a different API deployment. `VITE_` values are bundled into browser code, so they must never contain JWT secrets, database passwords, or server credentials.

## Authentication storage

The access token is stored in `sessionStorage`: it survives page refreshes within one tab session but is cleared when that session ends. This is a practical development choice for the current JWT backend. `localStorage` persists longer and increases exposure after an XSS event; memory is safer but loses sessions on refresh; secure httpOnly cookies are usually preferred in production but require backend cookie/CSRF support not present in Phase 3.

## API behavior

Axios adds `Authorization: Bearer <token>` centrally and clears the session after a `401`. Pages show loading, non-sensitive error, and empty states. Dashboard totals and charts use returned scan/finding records—no permanent mock data or client-side risk calculation.
