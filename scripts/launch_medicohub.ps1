param(
  [int]$BackendPort = 8012,
  [switch]$SkipBackendStart
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendScript = Join-Path $PSScriptRoot "run_backend.ps1"
$frontendScript = Join-Path $PSScriptRoot "run_frontend.ps1"
$releaseExe = Join-Path $projectRoot "frontend_flutter\build\windows\x64\runner\Release\medicohub.exe"
$debugExe = Join-Path $projectRoot "frontend_flutter\build\windows\x64\runner\Debug\medicohub.exe"
$healthUrl = "http://127.0.0.1:$BackendPort/docs"

if (-not $SkipBackendStart) {
  Start-Process powershell -ArgumentList @(
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    $backendScript,
    "-Port",
    "$BackendPort"
  ) -WorkingDirectory $projectRoot
}

$ready = $false
for ($i = 0; $i -lt 30; $i++) {
  try {
    $response = Invoke-WebRequest -UseBasicParsing $healthUrl -TimeoutSec 2
    if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
      $ready = $true
      break
    }
  } catch {
    Start-Sleep -Seconds 1
  }
}

if (-not $ready) {
  throw "Backend did not become ready at $healthUrl within 30 seconds."
}

if (Test-Path $releaseExe) {
  Start-Process $releaseExe -WorkingDirectory (Split-Path $releaseExe)
} elseif (Test-Path $debugExe) {
  Start-Process $debugExe -WorkingDirectory (Split-Path $debugExe)
} else {
  Start-Process powershell -ArgumentList @(
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    $frontendScript,
    "-Device",
    "windows"
  ) -WorkingDirectory $projectRoot
}
