param(
  [int]$BackendPort = 8012,
  [string]$Device = "windows"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendScript = Join-Path $PSScriptRoot "run_backend.ps1"
$frontendScript = Join-Path $PSScriptRoot "run_frontend.ps1"

Start-Process powershell -ArgumentList @(
  "-ExecutionPolicy",
  "Bypass",
  "-File",
  $backendScript,
  "-Port",
  "$BackendPort"
) -WorkingDirectory $projectRoot

Start-Sleep -Seconds 4

& $frontendScript -Device $Device
