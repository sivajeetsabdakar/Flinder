# Flinder Python Backend

FastAPI backend for the Flinder Flutter app, backed by Neon Postgres.

## Setup

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Update `.env` with your Neon connection string and JWT secret.

## Database

Apply the schema from the repo root:

```powershell
psql "$env:DATABASE_URL" -f database/migrations/001_initial_schema.sql
```

## Run

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## OCI Deployment

The backend can run on an OCI Compute VM as a Docker container:

```powershell
.\scripts\deploy_oci.ps1 -SshKeyPath C:\path\to\oci_private_key -ApplyMigrations
```

See [DEPLOY_OCI.md](DEPLOY_OCI.md) for VM setup, env vars, and verification.
