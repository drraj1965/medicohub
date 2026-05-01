param(
  [string]$Label = "manual"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$backupRoot = Join-Path $projectRoot ".backups"
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$archivePath = Join-Path $backupRoot "medicohub_${Label}_$timestamp.zip"

Compress-Archive -Path (Join-Path $projectRoot "backend_fastapi"), (Join-Path $projectRoot "frontend_flutter"), (Join-Path $projectRoot "docs"), (Join-Path $projectRoot "scripts"), (Join-Path $projectRoot "README.md"), (Join-Path $projectRoot ".env.example"), (Join-Path $projectRoot "update.json") -DestinationPath $archivePath -Force

Write-Host "Backup created: $archivePath"
