param(
  [string]$PythonCommand = "python"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot "backend_fastapi"
$venvRoot = Join-Path $backendRoot ".venv"
$pythonExe = Join-Path $venvRoot "Scripts\python.exe"

function Invoke-CheckedCommand {
  param(
    [string]$FilePath,
    [string[]]$Arguments
  )

  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed: $FilePath $($Arguments -join ' ')"
  }
}

if (!(Test-Path $venvRoot)) {
  Write-Host "Creating backend virtual environment..."
  & $PythonCommand -m venv $venvRoot
}

if (!(Test-Path $pythonExe)) {
  throw "Virtual environment Python was not created at $pythonExe"
}

Write-Host "Installing backend dependencies..."
Invoke-CheckedCommand -FilePath $pythonExe -Arguments @("-m", "pip", "install", "--upgrade", "pip")
Invoke-CheckedCommand -FilePath $pythonExe -Arguments @("-m", "pip", "install", "-r", (Join-Path $backendRoot "requirements.txt"))

Write-Host "Seeding dummy data..."
Push-Location $projectRoot
try {
  Invoke-CheckedCommand -FilePath $pythonExe -Arguments @("-m", "backend_fastapi.seed_dummy_data")
} finally {
  Pop-Location
}

Write-Host "Backend setup complete."
