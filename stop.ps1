# Stop all running services

Write-Host "Stopping services..." -ForegroundColor Yellow

# Kill uvicorn/python processes on port 8000
$pids = (Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue).OwningProcess
foreach ($pid in $pids) {
    Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Stopped process on port 8000 (backend)" -ForegroundColor Green
}

# Kill vite/node processes on port 5173
$pids = (Get-NetTCPConnection -LocalPort 5173 -ErrorAction SilentlyContinue).OwningProcess
foreach ($pid in $pids) {
    Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Stopped process on port 5173 (frontend)" -ForegroundColor Green
}

if (-not $pids) {
    Write-Host "No services found running." -ForegroundColor Gray
}

Write-Host "Done." -ForegroundColor Cyan
