# ============================================
# PROJECT STARTUP SCRIPT
# ============================================

Write-Host "========================================"
Write-Host " Starting Project..."
Write-Host "========================================"


# --------------------------------------------
# STEP 1: Start Minikube
# This MUST complete before anything else
# --------------------------------------------

Write-Host ""
Write-Host "[1/6] Starting Minikube..."

minikube start

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Minikube failed to start."
    exit 1
}

Write-Host "Minikube started successfully."


# --------------------------------------------
# STEP 2: Wait for Kubernetes
# --------------------------------------------

Write-Host ""
Write-Host "[2/6] Waiting for Kubernetes..."

kubectl wait --for=condition=Ready nodes --all --timeout=120s

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Kubernetes node is not ready."
    exit 1
}

Write-Host "Kubernetes is ready."


# --------------------------------------------
# STEP 3: Scenario Service
# Runs inside Python virtual environment
# --------------------------------------------

Write-Host ""
Write-Host "[3/6] Starting Scenario Service..."

Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "& '.\venv\Scripts\Activate.ps1'; uvicorn scenario_service.main:app --reload"


# --------------------------------------------
# STEP 4: Advisor API
# Runs inside Python virtual environment
# --------------------------------------------

Write-Host "[4/6] Starting Advisor API..."

Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "& '.\venv\Scripts\Activate.ps1'; uvicorn advisor_api.main:app --reload --port 8001"


# --------------------------------------------
# STEP 5: Kubernetes Port Forwards
# --------------------------------------------

Write-Host "[5/6] Starting Port Forwards..."

# Kubeflow UI
Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "kubectl port-forward -n kubeflow svc/ml-pipeline-ui 8081:80"


# Ray Dashboard
Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "kubectl port-forward -n kuberay svc/raycluster-head-svc 8265:8265"


# Ray Client
Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "kubectl port-forward -n kuberay svc/raycluster-head-svc 10001:10001"


# --------------------------------------------
# STEP 6: Start Frontend
# --------------------------------------------

Write-Host "[6/6] Starting Frontend..."

Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "cd '.\frontend'; npm run dev"


Write-Host ""
Write-Host "========================================"
Write-Host " All services launched!"
Write-Host "========================================"
Write-Host ""
Write-Host "Scenario Service : http://localhost:8000"
Write-Host "Advisor API      : http://localhost:8001"
Write-Host "Kubeflow UI      : http://localhost:8081"
Write-Host "Ray Dashboard    : http://localhost:8265"
Write-Host "Frontend         : http://localhost:5173"
Write-Host ""