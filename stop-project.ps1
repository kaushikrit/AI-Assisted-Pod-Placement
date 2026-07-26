# ============================================
# PROJECT STOP SCRIPT
# ============================================

Write-Host "========================================"
Write-Host " Stopping Project..."
Write-Host "========================================"


# --------------------------------------------
# STEP 1: Stop Uvicorn services
# --------------------------------------------

Write-Host ""
Write-Host "[1/5] Stopping Uvicorn services..."

Get-CimInstance Win32_Process |
Where-Object {
    $_.Name -match "python|uvicorn" -and
    $_.CommandLine -match "scenario_service|advisor_api"
} |
ForEach-Object {
    Write-Host "Stopping process $($_.ProcessId)"
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

Write-Host "Uvicorn services stopped."


# --------------------------------------------
# STEP 2: Stop kubectl port-forwards
# --------------------------------------------

Write-Host ""
Write-Host "[2/5] Stopping Kubernetes port forwards..."

Get-CimInstance Win32_Process |
Where-Object {
    $_.Name -match "kubectl" -and
    $_.CommandLine -match "port-forward"
} |
ForEach-Object {
    Write-Host "Stopping port-forward process $($_.ProcessId)"
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

Write-Host "Port forwards stopped."


# --------------------------------------------
# STEP 3: Stop frontend
# --------------------------------------------

Write-Host ""
Write-Host "[3/5] Stopping frontend..."

Get-CimInstance Win32_Process |
Where-Object {
    $_.Name -match "node|npm" -and
    $_.CommandLine -match "dev"
} |
ForEach-Object {
    Write-Host "Stopping frontend process $($_.ProcessId)"
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

Write-Host "Frontend stopped."


# --------------------------------------------
# STEP 4: Stop MinIO
# --------------------------------------------

Write-Host ""
Write-Host "[4/5] Stopping MinIO..."

$running = docker ps --filter "name=minio" --format "{{.Names}}"

if ($running) {
    docker stop minio | Out-Null
    Write-Host "MinIO stopped."
}
else {
    Write-Host "MinIO already stopped."
}


# --------------------------------------------
# STEP 5: Stop Minikube
# --------------------------------------------

Write-Host ""
Write-Host "[5/5] Stopping Minikube..."

minikube stop

if ($LASTEXITCODE -eq 0) {
    Write-Host "Minikube stopped successfully."
}
else {
    Write-Host "WARNING: Minikube may not have stopped correctly."
}


Write-Host ""
Write-Host "========================================"
Write-Host " Project stopped!"
Write-Host "========================================"