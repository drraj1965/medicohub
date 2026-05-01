param()

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$shortcutPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "MedicoHub.lnk"
$iconPath = Join-Path $projectRoot "frontend_flutter\windows\runner\resources\app_icon.ico"
$taskName = "MedicoHubLaunch"
$systemRoot = $env:WINDIR
$schtasksExe = Join-Path $systemRoot "System32\schtasks.exe"

$wshShell = New-Object -ComObject WScript.Shell
$shortcut = $wshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $schtasksExe
$shortcut.Arguments = "/run /tn `"$taskName`""
$shortcut.WorkingDirectory = $projectRoot
if (Test-Path $iconPath) {
  $shortcut.IconLocation = $iconPath
}
$shortcut.Description = "Launch MedicoHub backend and desktop app via scheduled task"
$shortcut.Save()

Write-Host "Desktop shortcut created:"
Write-Host $shortcutPath
