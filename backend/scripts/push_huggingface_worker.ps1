param(
    [string]$SpaceUrl = "https://huggingface.co/spaces/SivajeetSabdakar/flinder-ml-worker",
    [string]$SourcePath = "dist/huggingface-ml-worker",
    [string]$WorkPath = "dist/huggingface-ml-worker-repo"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$source = Join-Path $repoRoot $SourcePath
$work = Join-Path $repoRoot $WorkPath
$distRoot = Join-Path $repoRoot "dist"

if (-not (Test-Path $source)) {
    throw "Source bundle not found. Run .\backend\scripts\prepare_huggingface_worker.ps1 first."
}

if (-not ([System.IO.Path]::GetFullPath($work).StartsWith([System.IO.Path]::GetFullPath($distRoot), [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "WorkPath must be under $distRoot"
}

$tokenSecure = Read-Host "Paste Hugging Face write token" -AsSecureString
$tokenPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($tokenSecure)
$token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($tokenPtr)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenPtr)

if (-not $token) {
    throw "No token provided"
}

if (Test-Path $work) {
    Remove-Item -LiteralPath $work -Recurse -Force
}

$remote = $SpaceUrl -replace "^https://", "https://SivajeetSabdakar:$token@"
git clone $remote $work

Get-ChildItem -LiteralPath $work -Force |
    Where-Object { $_.Name -ne ".git" } |
    Remove-Item -Recurse -Force

Copy-Item -Path (Join-Path $source "*") -Destination $work -Recurse -Force

git -C $work add .
git -C $work commit -m "Deploy Flinder ML worker"
git -C $work push origin main

Write-Host "Pushed ML worker to $SpaceUrl"
