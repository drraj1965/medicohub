param(
    [string]$Tag = "store-release"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$BackendDir = Join-Path $RepoRoot "backend_fastapi"
$Image = "registry.fly.io/medicohub-backend:$Tag"

Write-Host "== MedicoHub Backend Fly Deploy =="
Write-Host "Image: $Image"

Push-Location $BackendDir
try {
    python -m py_compile main.py models.py services.py providers.py storage.py
    docker build -t "medicohub-backend:$Tag" .
    fly auth docker
    docker tag "medicohub-backend:$Tag" $Image
    docker push $Image
    fly deploy --image $Image
    Invoke-RestMethod "https://medicohub-backend.fly.dev/" | ConvertTo-Json -Depth 5
}
finally {
    Pop-Location
}
