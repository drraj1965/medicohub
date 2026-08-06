param(
    [switch]$SkipClean,
    [switch]$InstallOnDevice,
    [string]$BuildNumber = "34"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$FlutterDir = Join-Path $RepoRoot "frontend_flutter"
$BackendUrl = "https://medicohub-backend.fly.dev/"
$AabPath = Join-Path $FlutterDir "build\app\outputs\bundle\release\app-release.aab"
$ApkPath = Join-Path $FlutterDir "build\app\outputs\flutter-apk\app-release.apk"
$KeyProperties = Join-Path $FlutterDir "android\key.properties"
$GoogleServices = Join-Path $FlutterDir "android\app\google-services.json"

Write-Host "== MedicoHub Android Store Release =="
Write-Host "Repo: $RepoRoot"

if (-not (Test-Path $KeyProperties)) {
    throw "Missing Android signing file: $KeyProperties"
}
if (-not (Test-Path $GoogleServices)) {
    throw "Missing Firebase Android config: $GoogleServices"
}

Write-Host "Checking backend health..."
$health = Invoke-RestMethod $BackendUrl
if ($health.status -ne "ok") {
    throw "Backend health check failed."
}

Push-Location $FlutterDir
try {
    flutter --version
    flutter doctor -v

    if (-not $SkipClean) {
        flutter clean
    }

    flutter pub get
    flutter analyze
    flutter build appbundle --release `
        --dart-define "MEDICOHUB_API_BASE_URL=https://medicohub-backend.fly.dev" `
        --dart-define "MEDICOHUB_BUILD_NUMBER=$BuildNumber"

    if (-not (Test-Path $AabPath)) {
        throw "AAB was not created: $AabPath"
    }

    Write-Host ""
    Write-Host "Google Play AAB ready:"
    Write-Host $AabPath

    if ($InstallOnDevice) {
        flutter build apk --release
        if (-not (Test-Path $ApkPath)) {
            throw "APK was not created: $ApkPath"
        }
        $adb = Join-Path $env:LOCALAPPDATA "Android\sdk\platform-tools\adb.exe"
        if (-not (Test-Path $adb)) {
            throw "adb not found: $adb"
        }
        & $adb uninstall com.aster.medichub | Out-Host
        & $adb install $ApkPath
    }
}
finally {
    Pop-Location
}
