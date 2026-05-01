param()

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot "backend_fastapi"
$venvPython = Join-Path $backendRoot ".venv\Scripts\python.exe"
$distRoot = Join-Path $projectRoot "artifacts\backend_dist"

if (!(Test-Path $venvPython)) {
  throw "Backend virtual environment missing. Run .\scripts\setup_backend.ps1 first."
}

Push-Location $projectRoot
try {
  & $venvPython -m PyInstaller `
    --noconfirm `
    --clean `
    --noconsole `
    --name medicohub_backend `
    --distpath $distRoot `
    --workpath (Join-Path $projectRoot "artifacts\pyinstaller_work") `
    --specpath (Join-Path $projectRoot "artifacts") `
    --hidden-import backend_fastapi.main `
    --hidden-import backend_fastapi.services `
    --hidden-import backend_fastapi.providers `
    --hidden-import backend_fastapi.storage `
    --hidden-import backend_fastapi.config `
    --hidden-import backend_fastapi.models `
    --collect-submodules uvicorn `
    --collect-submodules firebase_admin `
    --collect-submodules googleapiclient `
    --collect-submodules google.auth `
    --collect-submodules google.cloud.firestore `
    --collect-submodules google.cloud.storage `
    (Join-Path $backendRoot "packaged_backend.py")

  $backendExe = Join-Path $distRoot "medicohub_backend\medicohub_backend.exe"
  if (!(Test-Path $backendExe)) {
    throw "PyInstaller finished, but medicohub_backend.exe was not found at $backendExe"
  }

  Write-Host "Backend release build ready:"
  Write-Host $backendExe
} finally {
  Pop-Location
}
