param(
  [string]$Device = "windows",
  [string]$ApiBaseUrl = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$frontendRoot = Join-Path $projectRoot "frontend_flutter"
$flutter = "C:\flutter\bin\flutter.bat"

if (!(Test-Path $flutter)) {
  throw "Flutter was not found at $flutter"
}

Push-Location $frontendRoot
try {
  if (!(Test-Path ".\windows") -or !(Test-Path ".\web") -or !(Test-Path ".\android")) {
    Write-Host "Generating missing Flutter platform folders..."
    & $flutter create . --platforms=android,ios,windows,linux,web
  }

  & $flutter pub get
  if ($Device -eq "android" -and [string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    Write-Warning "No -ApiBaseUrl was provided. A physical Android phone will not be able to reach your laptop backend unless you pass your laptop LAN URL, for example http://192.168.1.23:8012"
  }
  if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    & $flutter run -d $Device
  } else {
    & $flutter run -d $Device --dart-define="MEDICOHUB_API_BASE_URL=$ApiBaseUrl"
  }
} finally {
  Pop-Location
}
