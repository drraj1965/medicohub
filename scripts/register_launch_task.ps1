param()

$ErrorActionPreference = "Stop"

$taskName = "MedicoHubLaunch"
$projectRoot = Split-Path -Parent $PSScriptRoot
$launchScript = Join-Path $PSScriptRoot "launch_medicohub.ps1"
$powerShellExe = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"

if (!(Test-Path $launchScript)) {
  throw "Launch script not found at $launchScript"
}

$action = New-ScheduledTaskAction `
  -Execute $powerShellExe `
  -Argument "-ExecutionPolicy Bypass -File `"$launchScript`""

$principal = New-ScheduledTaskPrincipal `
  -UserId $env:USERNAME `
  -LogonType Interactive `
  -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit (New-TimeSpan -Hours 2)

Register-ScheduledTask `
  -TaskName $taskName `
  -Action $action `
  -Principal $principal `
  -Settings $settings `
  -Description "Launch MedicoHub backend and desktop app" `
  -Force | Out-Null

Write-Host "Scheduled task registered:"
Write-Host $taskName
