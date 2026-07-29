# Deploy Backend On OCI

This backend is ready for the same style of deployment as AutoPrep.ai: a Dockerized Python API running on an Oracle Cloud Infrastructure Compute VM, with Neon remaining the managed Postgres database.

## OCI VM Requirements

- Ubuntu OCI Compute instance with a public IP.
- Ingress rule allowing TCP `8000`, or `80/443` if you put Nginx/Caddy in front.
- Docker installed on the VM.
- OCI CLI login on your machine. This repo defaults to profile `whatsnew` with session-token auth.
- SSH access from your machine, usually `ubuntu@<public-ip>` with your OCI private key.
- `backend/.env` configured locally with production values before deploy.

## Production Environment

Set these values in the env file deployed to the VM:

```env
APP_ENV=production
DATABASE_URL=postgresql://...
JWT_SECRET=replace_with_a_long_random_secret
GOOGLE_OAUTH_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
CORS_ORIGINS=https://your-frontend-domain
TRUSTED_HOSTS=your-api-domain,<oci-public-ip>
AUTH_RATE_LIMIT_PER_MINUTE=20
AI_TEXT_API_BASE_URL=https://your-ai-text-api.example.com/dev
AI_TEXT_API_TOKEN=your-ai-token
ML_WORKER_TOKEN=generate-a-long-random-token
ML_WORKER_URL=
SEMANTIC_MATCHING_ENABLED=true
```

Do not commit `.env`. The deploy script uploads it directly to the VM.

## First-Time VM Setup

Run this once on the OCI VM:

```sh
sudo apt-get update
sudo apt-get install -y ca-certificates curl docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu
mkdir -p /opt/flinder
```

Log out and back in after adding `ubuntu` to the Docker group.

## Deploy From Windows

From the repo root, the script can resolve the target VM through OCI CLI:

```powershell
.\backend\scripts\deploy_oci.ps1 -ResolveOnly
```

Deploy to the default OCI instance, `whatsnew-prod`:

```powershell
.\backend\scripts\deploy_oci.ps1 `
  -SshKeyPath C:\path\to\oci_private_key `
  -ApplyMigrations
```

For later deploys after migrations are already applied:

```powershell
.\backend\scripts\deploy_oci.ps1 -SshKeyPath C:\path\to\oci_private_key
```

To target a different OCI instance:

```powershell
.\backend\scripts\deploy_oci.ps1 -InstanceName <instance-name> -OciProfile <profile-name> -SshKeyPath C:\path\to\oci_private_key
```

The script uses OCI CLI to discover the VM public IP, uploads `backend/`, `database/`, and `backend/.env`, builds the Docker image on the VM, restarts the `flinder-backend` container, and leaves it running on port `8000`.

## Semantic Matching Worker

Semantic embeddings are intentionally not generated in the main API container. The current Always Free E2 micro VM is too small for `sentence-transformers`.

When OCI Ampere A1 capacity is available, create a separate `VM.Standard.A1.Flex` worker and deploy the same app with `backend/Dockerfile.ml`. The worker image installs `requirements-ml.txt` and exposes protected internal routes:

```text
GET  /internal/ml/health
POST /internal/ml/profiles/{user_id}/rebuild
POST /internal/ml/profiles/rebuild-missing
```

Set `ML_WORKER_URL` on the API VM to the worker URL and use the same `ML_WORKER_TOKEN` on both containers. Keep `AI_TEXT_API_TOKEN` only in `.env`; never commit it.

Example worker deploy once the A1 VM exists:

```powershell
.\backend\scripts\deploy_oci.ps1 `
  -HostName <worker-public-or-private-ip> `
  -SshKeyPath C:\path\to\oci_private_key `
  -ImageName flinder-ml-worker `
  -DockerfileName Dockerfile.ml `
  -Port 8000
```

## Verify

```powershell
curl http://<oci-public-ip-or-domain>:8000/api/health
```

If you add a real API domain, update Google Cloud authorized origins/redirects as needed and pass that URL into Flutter:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://api.your-domain.com `
  --dart-define=GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```
