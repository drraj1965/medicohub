param(
  [string]$ArchivePath
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$backupRoot = Join-Path $projectRoot ".backups"

if ([string]::IsNullOrWhiteSpace($ArchivePath)) {
  $ArchivePath = Get-ChildItem $backupRoot -Filter "*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { $_.FullName }
}

if ([string]::IsNullOrWhiteSpace($ArchivePath) -or !(Test-Path $ArchivePath)) {
  throw "Backup archive not found."
}

$restoreRoot = Join-Path $projectRoot ".restore_temp"
if (Test-Path $restoreRoot) {
  Remove-Item $restoreRoot -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $restoreRoot | Out-Null
Expand-Archive -Path $ArchivePath -DestinationPath $restoreRoot -Force

foreach ($name in @("backend_fastapi", "frontend_flutter", "docs", "scripts", "README.md", ".env.example", "update.json")) {
  $source = Join-Path $restoreRoot $name
  $destination = Join-Path $projectRoot $name
  if (Test-Path $destination) {
    Remove-Item $destination -Recurse -Force
  }
  Move-Item -Path $source -Destination $destination
}

Remove-Item $restoreRoot -Recurse -Force
Write-Host "Rollback complete from $ArchivePath"
