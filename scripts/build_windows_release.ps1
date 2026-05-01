param()

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$frontendRoot = Join-Path $projectRoot "frontend_flutter"
$flutter = "C:\flutter\bin\flutter.bat"

if (!(Test-Path $flutter)) {
  throw "Flutter was not found at $flutter"
}

Push-Location $frontendRoot
try {
  & $flutter pub get
  & $flutter build windows --release

  $exePath = Join-Path $frontendRoot "build\windows\x64\runner\Release\medicohub.exe"
  if (!(Test-Path $exePath)) {
    throw "Windows release build finished, but medicohub.exe was not found at $exePath"
  }

  Write-Host "Release build ready:"
  Write-Host $exePath
} finally {
  Pop-Location
}
