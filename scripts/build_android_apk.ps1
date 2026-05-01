param(
  [string]$ApiBaseUrl = "",
  [switch]$Release,
  [string]$ArtifactLabel = ""
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
  & $flutter pub get
  $arguments = @("build", "apk")
  $apkName = "app-debug.apk"
  if ($Release) {
    $arguments += "--release"
    $apkName = "app-release.apk"
  } else {
    $arguments += "--debug"
  }
  if (![string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $arguments += "--dart-define=MEDICOHUB_API_BASE_URL=$ApiBaseUrl"
  } elseif (!$Release) {
    Write-Warning "No -ApiBaseUrl was provided. A debug APK installed on a physical Android phone will need a laptop LAN URL such as http://192.168.1.23:8012 to reach your backend."
  }

  & $flutter @arguments

  $pubspecPath = Join-Path $frontendRoot "pubspec.yaml"
  $pubspec = Get-Content $pubspecPath -Raw
  $versionMatch = [regex]::Match($pubspec, "version:\s*([0-9]+\.[0-9]+\.[0-9]+)")
  $version = if ($versionMatch.Success) { $versionMatch.Groups[1].Value } else { "unknown" }

  $artifactDir = Join-Path $projectRoot "artifacts"
  New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null
  $builtApk = Join-Path $frontendRoot "build\app\outputs\flutter-apk\$apkName"
  if (Test-Path $builtApk) {
    $labelSuffix = if ([string]::IsNullOrWhiteSpace($ArtifactLabel)) {
      if ($Release) { "release" } else { "debug" }
    } else {
      $ArtifactLabel
    }
    $artifactApk = Join-Path $artifactDir "medicohub-android-v$version-$labelSuffix.apk"
    Copy-Item $builtApk $artifactApk -Force
    Write-Host "Android APK ready:"
    Write-Host $artifactApk
  }
} finally {
  Pop-Location
}
