# MiroFish one-click start (Windows).
# Usage: ./start.ps1 [-Build] [-Ollama] [-Model <ollama model>]
#   -Build   build the Docker image from this repo's source instead of pulling
#   -Ollama  use a free local model via Ollama instead of a paid API
#   -Model   Ollama model to use (default: qwen2.5:32b)
param(
    [switch]$Build,
    [switch]$Ollama,
    [string]$Model = "qwen2.5:32b"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Set-EnvLine([string]$Name, [string]$Value) {
    $line = "$Name=$Value"
    $content = Get-Content ".env"
    if ($content -match "^$Name=") {
        $content = $content -replace "^$Name=.*", $line
    } else {
        $content += $line
    }
    Set-Content ".env" $content -Encoding UTF8
}

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    if (-not $Ollama) {
        Write-Host "Created .env - fill in LLM_API_KEY and ZEP_API_KEY, then run this again." -ForegroundColor Yellow
        notepad .env
        exit 1
    }
    Write-Host "Created .env - Ollama mode will fill the LLM settings; you still need ZEP_API_KEY." -ForegroundColor Yellow
}

if ($Ollama) {
    # 1. Ollama server reachable?
    try {
        $tags = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
    } catch {
        Write-Host "Ollama isn't reachable on localhost:11434." -ForegroundColor Red
        Write-Host "Install it from https://ollama.com/download and make sure it's running, then retry."
        exit 1
    }
    # 2. Model pulled?
    $have = @($tags.models | ForEach-Object { $_.name })
    if (-not ($have -contains $Model -or $have -contains "$Model`:latest")) {
        Write-Host "Model '$Model' not found locally - pulling it now (this can take a while)..." -ForegroundColor Yellow
        ollama pull $Model
        if ($LASTEXITCODE -ne 0) {
            Write-Host "ollama pull failed - check the model name (https://ollama.com/library)." -ForegroundColor Red
            exit 1
        }
    }
    # 3. Point MiroFish at Ollama (host.docker.internal = this machine, seen from the container)
    Copy-Item ".env" ".env.bak" -Force
    Set-EnvLine "LLM_API_KEY"     "ollama"
    Set-EnvLine "LLM_BASE_URL"    "http://host.docker.internal:11434/v1"
    Set-EnvLine "LLM_MODEL_NAME"  $Model
    Write-Host "Configured .env for Ollama model '$Model' (backup in .env.bak)." -ForegroundColor Green
}

$envText = Get-Content ".env" -Raw
if ($envText -match "your_[a-z_]*_here") {
    Write-Host ".env still contains placeholder values - fill them in first." -ForegroundColor Red
    Write-Host "(Ollama mode still needs ZEP_API_KEY - free tier at https://app.getzep.com/)"
    notepad .env
    exit 1
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker Desktop is not running - start it and try again." -ForegroundColor Red
    exit 1
}

$composeArgs = @("-f", $(if ($Build) { "docker-compose.build.yml" } else { "docker-compose.yml" }))
$composeArgs += @("-f", "docker-compose.local.yml")
if ($Ollama) { $composeArgs += @("-f", "docker-compose.ollama.yml") }

if ($Build) {
    docker compose @composeArgs up -d --build
} else {
    docker compose @composeArgs up -d
}

Write-Host ""
Write-Host "MiroFish is starting:" -ForegroundColor Green
Write-Host "  UI:  http://localhost:3000"
Write-Host "  API: http://localhost:5001"
if ($Ollama) { Write-Host "  LLM: Ollama / $Model (free, local)" }
Write-Host "Stop with: docker compose down"
Start-Process "http://localhost:3000"
