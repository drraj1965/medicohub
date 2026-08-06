param(
    [string]$App = "medicohub-backend",
    [ValidateSet("recommended", "all", "linkedin", "meta", "google", "tiktok", "reddit", "x", "threads")]
    [string]$Provider = "recommended",
    [string]$FromFile = "",
    [switch]$StageOnly,
    [switch]$ListOnly,
    [switch]$WriteTemplate,
    [switch]$ReadFromClipboard,
    [switch]$ShowFingerprints,
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Stop"

function Convert-SecureStringToPlainText {
    param([System.Security.SecureString]$SecureValue)
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

function Normalize-SecretName {
    param([string]$Name)
    return (($Name -replace ([string][char]0xFEFF), "") -replace "[^A-Za-z0-9_]", "").Trim()
}

function Get-SecretFingerprint {
    param([string]$Value)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
        $hash = $sha.ComputeHash($bytes)
        $hex = -join ($hash | ForEach-Object { $_.ToString("x2") })
        return $hex.Substring(0, 12)
    }
    finally {
        $sha.Dispose()
    }
}

function Write-SecretFingerprint {
    param(
        [string]$Name,
        [string]$Value
    )
    Write-Host "$Name captured: length=$($Value.Length), fingerprint=$(Get-SecretFingerprint $Value)"
}

$providerSecrets = @{
    linkedin = @(
        @{ Name = "LINKEDIN_CLIENT_ID"; Label = "LinkedIn Client ID" },
        @{ Name = "LINKEDIN_CLIENT_SECRET"; Label = "LinkedIn Client Secret" }
    )
    meta = @(
        @{ Name = "META_CLIENT_ID"; Label = "Meta App ID / Client ID for Facebook + Instagram" },
        @{ Name = "META_CLIENT_SECRET"; Label = "Meta App Secret" }
    )
    google = @(
        @{ Name = "GOOGLE_OAUTH_CLIENT_ID"; Label = "Google OAuth Client ID for YouTube / Google Business" },
        @{ Name = "GOOGLE_OAUTH_CLIENT_SECRET"; Label = "Google OAuth Client Secret" }
    )
    tiktok = @(
        @{ Name = "TIKTOK_CLIENT_KEY"; Label = "TikTok Client Key" },
        @{ Name = "TIKTOK_CLIENT_SECRET"; Label = "TikTok Client Secret" }
    )
    reddit = @(
        @{ Name = "REDDIT_CLIENT_ID"; Label = "Reddit Client ID" },
        @{ Name = "REDDIT_CLIENT_SECRET"; Label = "Reddit Client Secret" }
    )
    x = @(
        @{ Name = "X_CLIENT_ID"; Label = "X / Twitter OAuth Client ID" },
        @{ Name = "X_CLIENT_SECRET"; Label = "X / Twitter OAuth Client Secret" }
    )
    threads = @(
        @{ Name = "THREADS_CLIENT_ID"; Label = "Threads Client ID" },
        @{ Name = "THREADS_CLIENT_SECRET"; Label = "Threads Client Secret" }
    )
}

$providerOrder = switch ($Provider) {
    "recommended" { @("linkedin", "meta", "google") }
    "all" { @("linkedin", "meta", "google", "tiktok", "reddit", "x", "threads") }
    default { @($Provider) }
}

Write-Host "== MedicoHub Growth OAuth Secret Import =="
Write-Host "Fly app: $App"
Write-Host "Providers: $($providerOrder -join ', ')"
Write-Host ""
Write-Host "Values are entered as secure prompts and piped to 'fly secrets import'."
Write-Host "They are not echoed, not written to disk, and not committed to Git."
if ($ReadFromClipboard) {
    Write-Host "Clipboard mode is enabled: copy each value, then press Enter when prompted."
}
if ($ShowFingerprints -or $ReadFromClipboard) {
    Write-Host "Fingerprints show length and a short local hash only; they do not show the secret value."
}
Write-Host "For retries, use -WriteTemplate once, fill secrets/growth-oauth.fly.env, then rerun with -FromFile."
Write-Host "Press Enter at a prompt to skip that value."
Write-Host ""

$secretLines = New-Object System.Collections.Generic.List[string]

if ($WriteTemplate) {
    $templatePath = Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) "secrets") "growth-oauth.fly.env"
    $templateDir = Split-Path -Parent $templatePath
    New-Item -ItemType Directory -Force -Path $templateDir | Out-Null
    $templateLines = New-Object System.Collections.Generic.List[string]
    foreach ($providerName in $providerOrder) {
        $templateLines.Add("# $providerName")
        foreach ($secret in $providerSecrets[$providerName]) {
            $templateLines.Add("$($secret.Name)=")
        }
        $templateLines.Add("")
    }
    [System.IO.File]::WriteAllText($templatePath, ($templateLines -join "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Template written to $templatePath"
    Write-Host "Fill it locally, rerun with: -FromFile $templatePath"
    exit 0
}

if (-not [string]::IsNullOrWhiteSpace($FromFile)) {
    if (-not (Test-Path -LiteralPath $FromFile)) {
        throw "Secret file not found: $FromFile"
    }
    $allowedNames = New-Object System.Collections.Generic.HashSet[string]
    foreach ($providerName in $providerOrder) {
        foreach ($secret in $providerSecrets[$providerName]) {
            [void]$allowedNames.Add($secret.Name)
        }
    }
    foreach ($line in [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $FromFile))) {
        $cleanLine = $line.Trim()
        if ($cleanLine.StartsWith([char]0xFEFF)) {
            $cleanLine = $cleanLine.TrimStart([char]0xFEFF)
        }
        if ([string]::IsNullOrWhiteSpace($cleanLine) -or $cleanLine.StartsWith("#")) {
            continue
        }
        $parts = $cleanLine.Split("=", 2)
        if ($parts.Count -ne 2) {
            throw "Invalid line in secret file. Expected NAME=VALUE."
        }
        $name = Normalize-SecretName $parts[0]
        $value = $parts[1].Trim()
        if (-not $allowedNames.Contains($name)) {
            throw "Secret name '$name' is not expected for provider selection '$Provider'."
        }
        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-Host "Skipped $name"
            continue
        }
        if ($ShowFingerprints) {
            Write-SecretFingerprint $name $value
        }
        $secretLines.Add("$name=$value")
    }
}
else {
    foreach ($providerName in $providerOrder) {
        Write-Host "-- $providerName --"
        foreach ($secret in $providerSecrets[$providerName]) {
            if ($ListOnly) {
                Write-Host $secret.Name
                continue
            }
            if ($ReadFromClipboard) {
                Read-Host -Prompt "Copy $($secret.Label) to the clipboard, then press Enter" | Out-Null
                $value = (Get-Clipboard -Raw).Trim()
            }
            else {
                $secureValue = Read-Host -Prompt $secret.Label -AsSecureString
                $value = (Convert-SecureStringToPlainText $secureValue).Trim()
            }
            if ([string]::IsNullOrWhiteSpace($value)) {
                Write-Host "Skipped $($secret.Name)"
                continue
            }
            if ($ShowFingerprints -or $ReadFromClipboard) {
                Write-SecretFingerprint $secret.Name $value
            }
            $secretLines.Add("$($secret.Name)=$value")
        }
    }
}

if ($ListOnly) {
    exit 0
}

if ($secretLines.Count -eq 0) {
    Write-Host "No secrets entered. Nothing to import."
    exit 0
}

$secretMap = @{}
foreach ($line in $secretLines) {
    $parts = $line.Split("=", 2)
    $secretMap[(Normalize-SecretName $parts[0])] = $parts[1]
}
foreach ($providerName in $providerOrder) {
    $clientEntry = $providerSecrets[$providerName] | Where-Object { $_.Name -match "(_CLIENT_ID|OAUTH_CLIENT_ID|CLIENT_KEY)$" } | Select-Object -First 1
    $secretEntry = $providerSecrets[$providerName] | Where-Object { $_.Name -match "(_CLIENT_SECRET|OAUTH_CLIENT_SECRET|APP_SECRET)$" } | Select-Object -First 1
    if ($null -eq $clientEntry -or $null -eq $secretEntry) {
        continue
    }
    $clientName = $clientEntry.Name
    $secretName = $secretEntry.Name
    if (
        $secretMap.ContainsKey($clientName) -and
        $secretMap.ContainsKey($secretName) -and
        -not [string]::IsNullOrWhiteSpace($secretMap[$clientName]) -and
        $secretMap[$clientName] -eq $secretMap[$secretName]
    ) {
        $fingerprint = Get-SecretFingerprint $secretMap[$clientName]
        throw "$clientName and $secretName are identical after trimming whitespace. Captured length=$($secretMap[$clientName].Length), fingerprint=$fingerprint. Re-check the provider console and enter the OAuth client ID and client secret as two different values."
    }
}

if ($ValidateOnly) {
    Write-Host ""
    Write-Host "Secret values validated. No import performed because -ValidateOnly was used."
    exit 0
}

$flyArgs = @("secrets", "import", "--app", $App)
if ($StageOnly) {
    $flyArgs += "--stage"
}

Write-Host ""
Write-Host "Importing $($secretLines.Count) secret value(s) to Fly..."
$secretInput = (($secretLines | ForEach-Object {
    $parts = $_.Split("=", 2)
    "$(Normalize-SecretName $parts[0])=$($parts[1])"
}) -join "`n") + "`n"
$flyExe = (Get-Command fly -ErrorAction Stop).Source
$tempPath = Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) "secrets") ".growth-oauth.fly.import.tmp"
[System.IO.File]::WriteAllText($tempPath, $secretInput, (New-Object System.Text.UTF8Encoding($false)))
try {
    $quotedFly = '"' + $flyExe + '"'
    $quotedTemp = '"' + $tempPath + '"'
    $argText = ($flyArgs | ForEach-Object {
        if ($_ -match '[\s"]') {
            '"' + ($_ -replace '"', '\"') + '"'
        }
        else {
            $_
        }
    }) -join " "
    & cmd.exe /d /c "$quotedFly $argText < $quotedTemp"
    if ($LASTEXITCODE -ne 0) {
        throw "fly secrets import failed with exit code $LASTEXITCODE."
    }
}
finally {
    if (Test-Path -LiteralPath $tempPath) {
        Remove-Item -LiteralPath $tempPath -Force
    }
}

Write-Host ""
Write-Host "Current Fly secret names:"
fly secrets list --app $App
