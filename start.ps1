# One-click start: backend (FastAPI) + frontend (Vite+Vue)

param(
    [int]$BackendPort = 8000,
    [int]$FrontendPort = 5173
)

$ProjectRoot = $PSScriptRoot
$VenvPython = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
$FrontendDir = Join-Path $ProjectRoot "frontend"

# Ensure Node.js is in PATH
$nodePath = "D:\Software\DailyTools\NodeJs"
if (Test-Path $nodePath) {
    $env:Path = "$nodePath;$env:Path"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Travel AI - Starting services" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check backend
if (-not (Test-Path $VenvPython)) {
    Write-Host "[ERROR] venv not found: $VenvPython" -ForegroundColor Red
    exit 1
}

# Check frontend deps
if (-not (Test-Path (Join-Path $FrontendDir "node_modules"))) {
    Write-Host "[INFO] Installing frontend deps..." -ForegroundColor Yellow
    Push-Location $FrontendDir
    npm install
    Pop-Location
}

# Start backend
Write-Host "[1/2] Backend  -> http://localhost:$BackendPort" -ForegroundColor Green
$backendCmd = "cd '$ProjectRoot'; & '$VenvPython' -m uvicorn main:app --reload --host 0.0.0.0 --port $BackendPort"
Start-Process pwsh -ArgumentList "-NoExit","-Command",$backendCmd

# Start frontend
Write-Host "[2/2] Frontend -> http://localhost:$FrontendPort" -ForegroundColor Green
$frontendCmd = "`$env:Path = '$nodePath;' + `$env:Path; cd '$FrontendDir'; npm run dev"
Start-Process pwsh -ArgumentList "-NoExit","-Command",$frontendCmd

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Backend  : http://localhost:$BackendPort" -ForegroundColor Yellow
Write-Host "  Frontend : http://localhost:$FrontendPort" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Close each window to stop services." -ForegroundColor Gray
