param(
  [int]$Port = 8012,
  [string]$BindHost = "",
  [switch]$Reload
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot "backend_fastapi"
$venvRoot = Join-Path $backendRoot ".venv"
$pythonExe = Join-Path $venvRoot "Scripts\python.exe"

if (!(Test-Path $pythonExe)) {
  throw "Backend environment missing. Run .\scripts\setup_backend.ps1 first."
}

Push-Location $projectRoot
try {
  $resolvedHost = if ([string]::IsNullOrWhiteSpace($BindHost)) {
    if ([string]::IsNullOrWhiteSpace($env:BACKEND_HOST)) { "127.0.0.1" } else { $env:BACKEND_HOST }
  } else {
    $BindHost
  }

  $arguments = @("-m", "uvicorn", "backend_fastapi.main:app", "--host", "$resolvedHost", "--port", "$Port")
  if ($Reload) {
    $arguments += "--reload"
  }
  & $pythonExe @arguments
} finally {
  Pop-Location
}
