# PowerShell script to build and push all Discord bot Docker images to local k3s registry
# This is the Windows version of build-all.sh

param(
    [string]$Registry = "localhost:5000"
)

# Function to print colored output
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Cyan
}

# Function to build and push a Docker image
function Build-AndPush {
    param(
        [string]$BotDir,
        [string]$BotName
    )

    $ImageName = $BotName.ToLower()
    Write-Info "Building ${BotName}..."

    if (-not (Test-Path $BotDir)) {
        Write-Error "Directory not found: $BotDir"
        return $false
    }

    if (-not (Test-Path "$BotDir\Dockerfile")) {
        Write-Error "Dockerfile not found in $BotDir"
        return $false
    }

    # Build the image
    try {
        docker build -t "${Registry}/${ImageName}:latest" $BotDir
        Write-Info "Successfully built ${ImageName}"

        # Push to registry
        Write-Info "Pushing ${ImageName} to registry..."
        docker push "${Registry}/${ImageName}:latest"
        Write-Info "Successfully pushed ${ImageName}"
        return $true
    }
    catch {
        Write-Error "Failed to build/push ${ImageName}: $_"
        return $false
    }
}

# Check if Docker is running
Write-Info "Checking if Docker is running..."
try {
    docker info | Out-Null
}
catch {
    Write-Error "Docker is not running. Please start Docker Desktop and try again."
    exit 1
}

# Check if registry is accessible
Write-Info "Checking registry accessibility at ${Registry}..."
try {
    $response = Invoke-WebRequest -Uri "http://${Registry}/v2/" -UseBasicParsing -ErrorAction SilentlyContinue
}
catch {
    Write-Warning "Registry at ${Registry} may not be accessible."
    Write-Warning "For k3s, you may need to set up a local registry first:"
    Write-Warning "  docker run -d -p 5000:5000 --restart=always --name registry registry:2"
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        exit 1
    }
}

Write-Info "Starting build process for all Discord bots..."
Write-Host ""

# Track success/failure
$Total = 0
$Success = 0
$Failed = 0
$FailedBots = @()

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Go Bots
Write-Info "=== Building Go Bots ==="
foreach ($bot in @("AndyBot", "PirateBot", "WSB")) {
    $Total++
    if (Build-AndPush -BotDir "$ScriptDir\$bot" -BotName $bot) {
        $Success++
    }
    else {
        $Failed++
        $FailedBots += $bot
    }
    Write-Host ""
}

# C# Bots
Write-Info "=== Building C# Bots ==="
foreach ($bot in @("BrainCellBot", "DickJohnson", "HouseMog", "MangaNotifier", "MovieNightBot")) {
    $Total++
    if (Build-AndPush -BotDir "$ScriptDir\$bot" -BotName $bot) {
        $Success++
    }
    else {
        $Failed++
        $FailedBots += $bot
    }
    Write-Host ""
}

# Node.js Bots
Write-Info "=== Building Node.js Bots ==="
foreach ($bot in @("OwOBot", "OyVeyBot", "RedditSimBot", "TarotBot", "UwUBot", "JailBot", "JonTronBot", "TerryDavisBot")) {
    $Total++
    if (Build-AndPush -BotDir "$ScriptDir\$bot" -BotName $bot) {
        $Success++
    }
    else {
        $Failed++
        $FailedBots += $bot
    }
    Write-Host ""
}

# Python Bots
Write-Info "=== Building Python Bots ==="
foreach ($bot in @("ScribeBot", "PurpleHaroBot")) {
    $Total++
    if (Build-AndPush -BotDir "$ScriptDir\$bot" -BotName $bot) {
        $Success++
    }
    else {
        $Failed++
        $FailedBots += $bot
    }
    Write-Host ""
}

# Summary
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Info "Build Summary"
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Total bots: $Total"
Write-Host "Successful: $Success" -ForegroundColor Green
Write-Host "Failed: $Failed" -ForegroundColor Red

if ($Failed -gt 0) {
    Write-Host ""
    Write-Error "Failed bots:"
    foreach ($bot in $FailedBots) {
        Write-Host "  - $bot" -ForegroundColor Red
    }
    exit 1
}
else {
    Write-Host ""
    Write-Success "All bots built and pushed successfully!"
    Write-Info "You can now deploy them to your k3s cluster using:"
    Write-Info "  cd kubernetes"
    Write-Info "  .\deploy-all.ps1"
}
