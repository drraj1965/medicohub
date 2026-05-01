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

  $releaseDir = Join-Path $frontendRoot "build\windows\x64\runner\Release"
  $exePath = Join-Path $releaseDir "medicohub.exe"
  if (!(Test-Path $exePath)) {
    throw "Windows release build finished, but medicohub.exe was not found at $exePath"
  }

  $pubspecPath = Join-Path $frontendRoot "pubspec.yaml"
  $pubspec = Get-Content $pubspecPath -Raw
  $versionMatch = [regex]::Match($pubspec, "version:\s*([0-9]+\.[0-9]+\.[0-9]+)")
  $version = if ($versionMatch.Success) { $versionMatch.Groups[1].Value } else { "unknown" }

  $artifactDir = Join-Path $projectRoot "artifacts"
  New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null
  $zipPath = Join-Path $artifactDir "medicohub-windows-v$version-portable.zip"
  if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
  }
  Compress-Archive -Path (Join-Path $releaseDir "*") -DestinationPath $zipPath

  Write-Host "Release build ready:"
  Write-Host $exePath
  Write-Host "Portable package ready:"
  Write-Host $zipPath
} finally {
  Pop-Location
}
