param(
  [string]$HostName = "",
  [string]$InstanceName = "whatsnew-prod",
  [string]$InstanceId = "",
  [string]$CompartmentId = "",
  [string]$OciProfile = "whatsnew",
  [string]$OciAuth = "security_token",

  [string]$User = "ubuntu",
  [string]$SshKeyPath = "",
  [string]$RemoteDir = "/home/ubuntu/flinder",
  [string]$EnvFile = "backend/.env",
  [string]$ImageName = "flinder-backend",
  [int]$Port = 8000,
  [switch]$ApplyMigrations,
  [switch]$ResolveOnly
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$backendDir = Join-Path $repoRoot "backend"
$databaseDir = Join-Path $repoRoot "database"
$secretsDir = Join-Path $backendDir "secrets"
$envPath = Resolve-Path (Join-Path $repoRoot $EnvFile)
$sshArgs = @()

if ($SshKeyPath) {
  $sshArgs += @("-i", $SshKeyPath)
}

if (-not (Test-Path -LiteralPath $backendDir)) {
  throw "Backend directory not found: $backendDir"
}

if (-not (Test-Path -LiteralPath $databaseDir)) {
  throw "Database directory not found: $databaseDir"
}

function Get-OciProfileValue {
  param(
    [string]$Profile,
    [string]$Key
  )

  $configPath = Join-Path $HOME ".oci\config"
  if (-not (Test-Path -LiteralPath $configPath)) {
    return ""
  }

  $inProfile = $false
  foreach ($line in Get-Content -LiteralPath $configPath) {
    $trimmed = $line.Trim()
    if ($trimmed -match "^\[(.+)\]$") {
      $inProfile = $Matches[1] -eq $Profile
      continue
    }

    if ($inProfile -and $trimmed -match "^$([regex]::Escape($Key))=(.+)$") {
      return $Matches[1].Trim()
    }
  }

  return ""
}

function Invoke-OciJson {
  param([string[]]$Arguments)

  $env:OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING = "True"
  $baseArgs = @()
  if ($OciProfile) {
    $baseArgs += @("--profile", $OciProfile)
  }
  if ($OciAuth) {
    $baseArgs += @("--auth", $OciAuth)
  }

  $json = & oci @Arguments @baseArgs --output json
  if ($LASTEXITCODE -ne 0) {
    throw "OCI CLI command failed: oci $($Arguments -join ' ')"
  }

  return $json | ConvertFrom-Json
}

function Resolve-OciInstanceHost {
  if ($HostName) {
    return $HostName
  }

  $resolvedCompartmentId = $CompartmentId
  if (-not $resolvedCompartmentId) {
    $resolvedCompartmentId = Get-OciProfileValue -Profile $OciProfile -Key "tenancy"
  }
  if (-not $resolvedCompartmentId) {
    throw "Set -CompartmentId or configure tenancy in OCI profile '$OciProfile'."
  }

  $resolvedInstanceId = $InstanceId
  if (-not $resolvedInstanceId) {
    $instances = Invoke-OciJson @("compute", "instance", "list", "--compartment-id", $resolvedCompartmentId, "--all")
    $match = @($instances.data) | Where-Object {
      $_."display-name" -eq $InstanceName -and $_."lifecycle-state" -eq "RUNNING"
    } | Select-Object -First 1

    if (-not $match) {
      throw "No running OCI instance named '$InstanceName' found in compartment '$resolvedCompartmentId'."
    }

    $resolvedInstanceId = $match.id
    Write-Host "Resolved OCI instance '$($match.'display-name')'."
  }

  $vnics = Invoke-OciJson @(
    "compute", "instance", "list-vnics",
    "--compartment-id", $resolvedCompartmentId,
    "--instance-id", $resolvedInstanceId
  )
  $vnic = @($vnics.data) | Where-Object { $_."public-ip" } | Select-Object -First 1
  if (-not $vnic) {
    throw "OCI instance has no public IP. Add one or deploy through a bastion/VPN and pass -HostName."
  }

  Write-Host "Resolved OCI public IP $($vnic.'public-ip')."
  return $vnic."public-ip"
}

$resolvedHostName = Resolve-OciInstanceHost
if ($ResolveOnly) {
  Write-Host "OCI target host: $resolvedHostName"
  exit 0
}

$sshTarget = "$User@$resolvedHostName"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("flinder-oci-" + [guid]::NewGuid().ToString("N"))
$bundlePath = Join-Path $tempRoot "flinder-backend.tgz"

function Invoke-Checked {
  param(
    [string]$Label,
    [scriptblock]$Command
  )

  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "$Label failed with exit code $LASTEXITCODE"
  }
}

function Copy-SourceTree {
  param(
    [string]$Source,
    [string]$Destination
  )

  New-Item -ItemType Directory -Path $Destination | Out-Null
  $excludeDirs = @(".venv", "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache", "secrets")
  $excludeFiles = @(".env", ".env.*", ".oauth-local-notes.txt", "*.pyc", "*.pyo", "*.log")
  robocopy $Source $Destination /E /XD $excludeDirs /XF $excludeFiles /NFL /NDL /NJH /NJS /NP | Out-Null
  if ($LASTEXITCODE -gt 7) {
    throw "robocopy failed for $Source with exit code $LASTEXITCODE"
  }
}

try {
  New-Item -ItemType Directory -Path $tempRoot | Out-Null
  Copy-SourceTree -Source $backendDir -Destination (Join-Path $tempRoot "backend")
  Copy-SourceTree -Source $databaseDir -Destination (Join-Path $tempRoot "database")

  Invoke-Checked "tar create bundle" { tar -czf $bundlePath -C $tempRoot backend database }

  Invoke-Checked "remote mkdir" { ssh @sshArgs $sshTarget "mkdir -p $RemoteDir" }
  Invoke-Checked "upload source bundle" { scp @sshArgs $bundlePath "${sshTarget}:$RemoteDir/flinder-backend.tgz" }
  Invoke-Checked "upload env file" { scp @sshArgs $envPath "${sshTarget}:$RemoteDir/.env" }
  if (Test-Path -LiteralPath $secretsDir) {
    Invoke-Checked "remote secrets mkdir" { ssh @sshArgs $sshTarget "mkdir -p $RemoteDir/secrets" }
    Invoke-Checked "upload secret files" { scp @sshArgs (Join-Path $secretsDir "*") "${sshTarget}:$RemoteDir/secrets/" }
  }

  $remote = @(
    "set -e",
    "cd $RemoteDir",
    "tar -xzf flinder-backend.tgz",
    "cp .env backend/.env",
    "docker build -t ${ImageName}:latest backend",
    "docker rm -f $ImageName >/dev/null 2>&1 || true"
  )

  if ($ApplyMigrations) {
    $remote += "docker run --rm --env-file .env -v $RemoteDir/database:/app/database:ro ${ImageName}:latest python scripts/apply_migrations.py"
  }

  $remote += @(
    "docker run -d --restart unless-stopped --name $ImageName --env-file .env -v $RemoteDir/secrets:/run/secrets/flinder:ro -p ${Port}:8000 ${ImageName}:latest",
    "docker image prune -f >/dev/null",
    "docker ps --filter name=$ImageName"
  )

  $remoteCommand = $remote -join " && "
  Invoke-Checked "remote deploy" { ssh @sshArgs $sshTarget $remoteCommand }
}
finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}
