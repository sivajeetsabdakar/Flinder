param(
    [string]$OutputPath = "dist/huggingface-ml-worker"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$backendRoot = (Resolve-Path (Join-Path $repoRoot "backend")).Path
$distRoot = Join-Path $repoRoot "dist"

if (-not (Test-Path $distRoot)) {
    New-Item -ItemType Directory -Path $distRoot | Out-Null
}

$target = Join-Path $repoRoot $OutputPath
$resolvedParent = Resolve-Path (Split-Path $target -Parent) -ErrorAction SilentlyContinue

if ($null -eq $resolvedParent -or -not $resolvedParent.Path.StartsWith($distRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputPath must resolve under $distRoot"
}

if (Test-Path $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
}

New-Item -ItemType Directory -Path $target | Out-Null
Copy-Item -Path (Join-Path $backendRoot "app") -Destination (Join-Path $target "app") -Recurse
Copy-Item -Path (Join-Path $backendRoot "scripts") -Destination (Join-Path $target "scripts") -Recurse
Get-ChildItem -LiteralPath $target -Directory -Recurse -Force |
    Where-Object { $_.Name -eq "__pycache__" } |
    Remove-Item -Recurse -Force

@'
---
title: Flinder ML Worker
sdk: gradio
sdk_version: 5.38.2
app_port: 7860
---

# Flinder ML Worker

Private semantic matching worker for Flinder.

Public endpoints:
- `GET /`
- `GET /api/health`
- `GET /internal/ml/health`

Protected endpoints require `X-ML-Worker-Token`.
'@ | Set-Content -Path (Join-Path $target "README.md") -Encoding utf8

@'
import os
import uuid

import gradio as gr
import spaces
from sqlalchemy import select

os.environ.setdefault("APP_ENV", "worker")
os.environ.setdefault("WORKER_ONLY", "true")
os.environ["PORT"] = "7860"

from app.config import get_settings  # noqa: E402
from app.database import SessionLocal  # noqa: E402
from app.models import UserEmbedding  # noqa: E402
from app.services.semantic_matching import rebuild_user_embedding  # noqa: E402


def _check_token(worker_token: str):
    settings = get_settings()
    if not settings.ml_worker_token or worker_token != settings.ml_worker_token:
        raise gr.Error("Invalid worker token")


@spaces.GPU(duration=1)
def zero_gpu_probe():
    return {"status": "ok", "service": "flinder-ml-worker"}


@spaces.GPU(duration=60)
def rebuild_profile(user_id: str, worker_token: str):
    _check_token(worker_token)
    with SessionLocal() as db:
        try:
            row = rebuild_user_embedding(db, uuid.UUID(user_id))
        except ValueError as exc:
            raise gr.Error(str(exc)) from exc
        return {
            "success": row.status == "ready",
            "userId": str(row.user_id),
            "status": row.status,
            "model": row.model_name,
            "lastEmbeddedAt": row.last_embedded_at.isoformat() if row.last_embedded_at else None,
            "error": row.error,
        }


@spaces.GPU(duration=120)
def rebuild_missing(limit: int, worker_token: str):
    _check_token(worker_token)
    safe_limit = max(1, min(int(limit), 25))
    with SessionLocal() as db:
        rows = db.scalars(
            select(UserEmbedding)
            .where(UserEmbedding.status.in_(["missing", "stale", "failed"]))
            .order_by(UserEmbedding.updated_at.asc())
            .limit(safe_limit)
        ).all()
        results = []
        for row in rows:
            rebuilt = rebuild_user_embedding(db, row.user_id)
            results.append({"userId": str(rebuilt.user_id), "status": rebuilt.status, "error": rebuilt.error})
        return {"success": True, "processed": len(results), "results": results}


with gr.Blocks(title="Flinder ML Worker") as demo:
    gr.Markdown("# Flinder ML Worker")
    with gr.Row():
        user_id = gr.Textbox(label="User ID")
        token = gr.Textbox(label="Worker token", type="password")
    rebuild_button = gr.Button("Rebuild profile")
    rebuild_output = gr.JSON(label="Result")
    rebuild_button.click(rebuild_profile, [user_id, token], rebuild_output, api_name="rebuild_profile")

    limit = gr.Number(label="Missing rebuild limit", value=10, precision=0)
    missing_button = gr.Button("Rebuild missing")
    missing_output = gr.JSON(label="Missing result")
    missing_button.click(rebuild_missing, [limit, token], missing_output, api_name="rebuild_missing")
    gr.api(zero_gpu_probe, api_name="health")


demo.queue().launch(server_name="0.0.0.0", server_port=7860)
'@ | Set-Content -Path (Join-Path $target "app.py") -Encoding utf8

$spaceRequirements = @(
    "sqlalchemy==2.0.43",
    "psycopg[binary]==3.2.9",
    "python-dotenv==1.1.1",
    "pydantic-settings==2.10.1",
    "httpx==0.28.1",
    "numpy==2.2.6",
    "sentence-transformers==3.4.1"
)
$spaceRequirements | Set-Content -Path (Join-Path $target "requirements.txt") -Encoding utf8

Write-Host "Prepared Hugging Face Space source at $target"
