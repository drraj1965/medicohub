param(
  [int]$Port = 8012,
  [switch]$Reload = $true
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
  $arguments = @("-m", "uvicorn", "backend_fastapi.main:app", "--host", "127.0.0.1", "--port", "$Port")
  if ($Reload) {
    $arguments += "--reload"
  }
  & $pythonExe @arguments
} finally {
  Pop-Location
}
