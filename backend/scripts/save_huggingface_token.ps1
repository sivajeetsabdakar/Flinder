$ErrorActionPreference = "Stop"

$tokenSecure = Read-Host "Paste Hugging Face write token to save as HF_TOKEN" -AsSecureString
$tokenPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($tokenSecure)
$token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($tokenPtr)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenPtr)

if (-not $token) {
    throw "No token provided"
}

[Environment]::SetEnvironmentVariable("HF_TOKEN", $token, "User")
$env:HF_TOKEN = $token

Write-Host "Saved HF_TOKEN to the Windows user environment for future PowerShell sessions."
