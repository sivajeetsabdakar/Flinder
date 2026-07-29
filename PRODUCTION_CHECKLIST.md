# Production Checklist

## Done In Repo

- Flutter app lives in `frontend/`.
- FastAPI backend lives in `backend/`.
- Neon/Postgres migrations live in `database/migrations/`.
- Google auth flow is implemented with backend ID-token verification.
- Conversations, chat membership, and messages persist through the backend.
- Discovery swipe UI has smooth Tinder-style left/right card motion.
- Backend has a Dockerfile for container deployment.
- Backend has an OCI VM Docker deployment guide and PowerShell deploy helper.
- Backend has a migration runner and CI scaffold.
- Backend has a live Neon smoke-tested path for register, login, profile update, chat creation, and message send.

## Required Before Launch

- Create Google Cloud OAuth clients for Android, iOS, and Web.
- Set `GOOGLE_OAUTH_CLIENT_ID`, `DATABASE_URL`, `JWT_SECRET`, and production `CORS_ORIGINS`.
- Apply `database/migrations/001_initial_schema.sql` and `002_google_auth.sql` to Neon.
- Choose and wire profile image storage. Neon stores metadata only, not image files.
- Add production API URL to Flutter builds with `--dart-define=API_BASE_URL=...`.
- Deploy the backend to OCI and put it behind HTTPS before mobile release builds.
- Configure Android package/SHA fingerprints and iOS reversed client ID URL scheme.
- Run full device testing for Google sign-in, profile completion, swiping, flats, applications, and chat.
- Add CI for backend tests, Flutter analyze, and Flutter tests.
- Add monitoring/logging for backend errors and auth failures.
- Rotate any development secrets before deployment.

## Still Thin

- Chat is request/response polling only. Real-time chat needs WebSockets, push notifications, or periodic refresh.
- Flat applications have basic ownership checks only. Add landlord/admin roles before real approvals.
- Email/password auth still exists as legacy. Decide whether to remove it or keep it behind a feature flag.
- Flutter has many pre-existing analyzer warnings. They are not fatal today, but should be reduced before release.
