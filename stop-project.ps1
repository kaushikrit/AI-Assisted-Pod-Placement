# ============================================
# PROJECT STOP SCRIPT
# ============================================

Write-Host "========================================"
Write-Host " Stopping Project..."
Write-Host "========================================"


# --------------------------------------------
# STEP 1: Stop Uvicorn / Python services
# --------------------------------------------

Write-Host ""
Write-Host "[1/4] Stopping Uvicorn services..."

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
# STEP 2: Stop kubectl port-forward processes
# --------------------------------------------

Write-Host ""
Write-Host "[2/4] Stopping Kubernetes port forwards..."

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
# STEP 3: Stop frontend npm dev server
# --------------------------------------------

Write-Host ""
Write-Host "[3/4] Stopping frontend..."

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
# STEP 4: Stop Minikube
# --------------------------------------------

Write-Host ""
Write-Host "[4/4] Stopping Minikube..."

minikube stop

if ($LASTEXITCODE -eq 0) {
    Write-Host "Minikube stopped successfully."
}
else {
    Write-Host "WARNING: Minikube may not have stopped correctly."
}


# --------------------------------------------
# DONE
# --------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host " Project stopped!"
Write-Host "========================================"