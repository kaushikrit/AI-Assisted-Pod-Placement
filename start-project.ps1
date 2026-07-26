# ============================================
# PROJECT STARTUP SCRIPT
# ============================================

Write-Host "========================================"
Write-Host " Starting Project..."
Write-Host "========================================"


# --------------------------------------------
# STEP 0: Start Docker Desktop
# --------------------------------------------

Write-Host ""
Write-Host "[0/7] Starting Docker Desktop..."

$dockerDesktop = "$Env:ProgramFiles\Docker\Docker\Docker Desktop.exe"

if (-not (Get-Process "Docker Desktop" -ErrorAction SilentlyContinue) -and
    -not (Get-Process "Docker Desktop Backend" -ErrorAction SilentlyContinue)) {

    Start-Process $dockerDesktop

    Write-Host "Waiting for Docker Desktop..."

    do {
        Start-Sleep -Seconds 5
        docker info *> $null
    } until ($LASTEXITCODE -eq 0)
}

Write-Host "Docker Desktop is ready."


# --------------------------------------------
# STEP 1: Start Minikube
# --------------------------------------------

Write-Host ""
Write-Host "[1/7] Starting Minikube..."

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
Write-Host "[2/7] Waiting for Kubernetes..."

kubectl wait --for=condition=Ready nodes --all --timeout=120s

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Kubernetes node is not ready."
    exit 1
}

Write-Host "Kubernetes is ready."


# --------------------------------------------
# STEP 3: Start MinIO
# --------------------------------------------

Write-Host ""
Write-Host "[3/7] Starting MinIO..."

$exists = docker ps -a --filter "name=minio" --format "{{.Names}}"

if (-not $exists) {
    Write-Host "WARNING: No container named 'minio' was found."
}
else {
    $running = docker ps --filter "name=minio" --format "{{.Names}}"

    if (-not $running) {
        docker start minio | Out-Null
        Write-Host "MinIO started."
    }
    else {
        Write-Host "MinIO already running."
    }
}


# --------------------------------------------
# STEP 4: Scenario Service
# --------------------------------------------

Write-Host ""
Write-Host "[4/7] Starting Scenario Service..."

Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "& '.\venv\Scripts\Activate.ps1'; uvicorn scenario_service.main:app --reload"


# --------------------------------------------
# STEP 5: Advisor API
# --------------------------------------------

Write-Host "[5/7] Starting Advisor API..."

Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "& '.\venv\Scripts\Activate.ps1'; uvicorn advisor_api.main:app --reload --port 8001"


# --------------------------------------------
# STEP 6: Kubernetes Port Forwards
# --------------------------------------------

Write-Host "[6/7] Starting Port Forwards..."

Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "kubectl port-forward -n kubeflow svc/ml-pipeline-ui 8081:80"

Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "kubectl port-forward -n kuberay svc/raycluster-head-svc 8265:8265"

Start-Process powershell -ArgumentList `
    "-NoExit", `
    "-Command", `
    "kubectl port-forward -n kuberay svc/raycluster-head-svc 10001:10001"


# --------------------------------------------
# STEP 7: Frontend
# --------------------------------------------

Write-Host "[7/7] Starting Frontend..."

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
Write-Host "MinIO Console    : http://localhost:9001"
Write-Host ""