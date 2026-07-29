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

import uvicorn

os.environ.setdefault("APP_ENV", "worker")
os.environ.setdefault("WORKER_ONLY", "true")
os.environ.setdefault("PORT", "7860")

from app.main import app  # noqa: E402


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ["PORT"]))
'@ | Set-Content -Path (Join-Path $target "app.py") -Encoding utf8

$spaceRequirements = @(
    "fastapi==0.116.1",
    "uvicorn[standard]==0.35.0",
    "sqlalchemy==2.0.43",
    "psycopg[binary]==3.2.9",
    "python-dotenv==1.1.1",
    "pydantic-settings==2.10.1",
    "httpx==0.28.1",
    "python-multipart==0.0.21",
    "numpy==2.2.6",
    "sentence-transformers==3.4.1",
    "gradio==5.38.2"
)
$spaceRequirements | Set-Content -Path (Join-Path $target "requirements.txt") -Encoding utf8

Write-Host "Prepared Hugging Face Space source at $target"
