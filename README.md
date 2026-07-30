# Flinder

![Flinder AI-Powered Roommate Matching System](docs/assets/flinder-ai-powered-roommate-matching-system.png)

Flinder is structured as a Flutter mobile app with a Python FastAPI backend and Neon Postgres database.

For a deeper breakdown of the semantic matching pipeline, vector embeddings, scoring formulas, and production architecture, see [TECHNICAL_ANALYSIS.md](TECHNICAL_ANALYSIS.md).

## Project Layout

```text
frontend/              Flutter app
backend/               FastAPI backend
database/migrations/   Neon/Postgres SQL migrations
```

## Run The Backend

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Or build the backend container:

```powershell
cd backend
docker build -t flinder-backend .
docker run --env-file .env -p 8000:8000 flinder-backend
```

For OCI deployment, use the backend deploy guide:

```powershell
.\backend\scripts\deploy_oci.ps1 -SshKeyPath C:\path\to\oci_private_key -ApplyMigrations
```

See [backend/DEPLOY_OCI.md](backend/DEPLOY_OCI.md).

Set `DATABASE_URL` in `backend/.env` to your Neon pooled or direct Postgres connection string.
Set `GOOGLE_OAUTH_CLIENT_ID` to the Web OAuth client ID from Google Cloud Console.

## Apply Database Schema

```powershell
psql "$env:DATABASE_URL" -f database/migrations/001_initial_schema.sql
```

If you already applied the initial schema before Google auth was added, also run:

```powershell
psql "$env:DATABASE_URL" -f database/migrations/002_google_auth.sql
```

Or run all migrations through the backend venv:

```powershell
cd backend
.\.venv\Scripts\python.exe scripts\apply_migrations.py
```

## Run The Flutter App

```powershell
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

For Android emulator, use your host IP or `http://10.0.2.2:8000` instead of `localhost`.

## Google Auth Setup

In Google Cloud Console:

1. Create or select a project.
2. Configure the OAuth consent screen.
3. Create OAuth client IDs for your Flutter targets.
4. Use the Web client ID as `GOOGLE_OAUTH_CLIENT_ID` in `backend/.env`.
5. Pass the same Web client ID to Flutter as `GOOGLE_WEB_CLIENT_ID`.

For Android, create an Android OAuth client with the app package name and SHA-1/SHA-256 fingerprints. For iOS, create an iOS OAuth client with the bundle ID and add the reversed client ID to the iOS URL schemes when you enable iOS builds.

## Swipe UI

The discovery card behaves like a Tinder-style deck:

- Swipe right to like.
- Swipe left to pass.
- Cards animate smoothly back to center or fly out.
- Like/pass buttons trigger the same animations.

See [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md) for the remaining launch items.
