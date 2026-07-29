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
Copy-Item -Path (Join-Path $backendRoot "requirements.txt") -Destination (Join-Path $target "requirements.txt")
Copy-Item -Path (Join-Path $backendRoot "requirements-ml.txt") -Destination (Join-Path $target "requirements-ml.txt")

@'
---
title: Flinder ML Worker
sdk: docker
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
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=7860
ENV WORKER_ONLY=true
ENV APP_ENV=worker

WORKDIR /app

COPY requirements.txt .
COPY requirements-ml.txt .
RUN pip install --no-cache-dir -r requirements-ml.txt

COPY app ./app
COPY scripts ./scripts

EXPOSE 7860

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:7860/internal/ml/health', timeout=5).read()"

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-7860}"]
'@ | Set-Content -Path (Join-Path $target "Dockerfile") -Encoding utf8

Write-Host "Prepared Hugging Face Space source at $target"
