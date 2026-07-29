# Hugging Face ML Worker Deployment

The semantic matching worker can run as a Hugging Face Gradio Space while the main FastAPI backend stays on OCI.

Docker Spaces may require a paid plan. The generated Space uses `sdk: gradio` with a blank `app.py` that starts the worker FastAPI app on port `7860`. Secrets are managed from the Space settings page.

## Prepare Space Source

From the repository root:

```powershell
.\backend\scripts\prepare_huggingface_worker.ps1
```

This creates `dist/huggingface-ml-worker`, which is ignored by git and contains only the ML worker deployable source.

## Create the Space

Create a new Hugging Face Space:

- SDK: Gradio
- Template: Blank
- Visibility: Private is preferred
- Hardware: free CPU Basic first

Push the generated `dist/huggingface-ml-worker` folder contents to that Space repo.

## Space Secrets

Add these as Hugging Face Space secrets, not variables:

- `DATABASE_URL`
- `JWT_SECRET`
- `AI_TEXT_API_BASE_URL`
- `AI_TEXT_API_TOKEN`
- `ML_WORKER_TOKEN`

Add these as variables:

- `APP_ENV=worker`
- `WORKER_ONLY=true`
- `SEMANTIC_MODEL_NAME=all-MiniLM-L6-v2`
- `SEMANTIC_MATCHING_ENABLED=true`

## Wire Main API

After the Space builds, set the main OCI backend env:

```text
ML_WORKER_URL=https://<user-or-org>-<space-name>.hf.space
```

Keep the same `ML_WORKER_TOKEN` value in both the OCI backend and the Hugging Face Space.

Then redeploy the OCI backend and run:

```powershell
curl.exe -H "X-ML-Worker-Token: <token>" https://<space-url>/internal/ml/health
curl.exe -X POST -H "X-ML-Worker-Token: <token>" "https://<space-url>/internal/ml/profiles/rebuild-missing?limit=10"
```

Do not commit generated Space source, `.env`, tokens, or copied secrets.
