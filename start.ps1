# MiroFish one-click start (Windows). Usage: ./start.ps1 [-Build]
param([switch]$Build)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example — fill in LLM_API_KEY and ZEP_API_KEY, then run this again." -ForegroundColor Yellow
    notepad .env
    exit 1
}

$envText = Get-Content ".env" -Raw
if ($envText -match "your_api_key_here") {
    Write-Host ".env still contains placeholder keys — fill in LLM_API_KEY and ZEP_API_KEY first." -ForegroundColor Red
    notepad .env
    exit 1
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker Desktop is not running — start it and try again." -ForegroundColor Red
    exit 1
}

if ($Build) {
    docker compose -f docker-compose.build.yml up -d --build
} else {
    docker compose up -d
}

Write-Host ""
Write-Host "MiroFish is starting:" -ForegroundColor Green
Write-Host "  UI:  http://localhost:3000"
Write-Host "  API: http://localhost:5001"
Write-Host "Stop with: docker compose down"
Start-Process "http://localhost:3000"
