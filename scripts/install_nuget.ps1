param()

$ErrorActionPreference = "Stop"

$installDir = Join-Path $env:USERPROFILE "tools\nuget"
$nugetExe = Join-Path $installDir "nuget.exe"
$downloadUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"

New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Invoke-WebRequest -Uri $downloadUrl -OutFile $nugetExe

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathEntries = @()
if ($userPath) {
  $pathEntries = $userPath.Split(';') | Where-Object { $_.Trim() -ne "" }
}

if ($pathEntries -notcontains $installDir) {
  $newPath = ($pathEntries + $installDir) -join ';'
  [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

if (($env:Path.Split(';') | Where-Object { $_ -eq $installDir }).Count -eq 0) {
  $env:Path = "$env:Path;$installDir"
}

Write-Host "nuget.exe installed at:"
Write-Host $nugetExe
Write-Host "Restart PowerShell after this if other terminals do not see nuget yet."
