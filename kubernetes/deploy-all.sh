#!/bin/bash

# Script to deploy all Discord bots to k3s cluster
# This script will:
# 1. Create the namespace
# 2. Create secrets from auth files
# 3. Generate deployment manifests
# 4. Deploy all bots to the cluster

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEPLOYMENTS_DIR="$SCRIPT_DIR/deployments"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    print_error "Make sure your k3s cluster is running and kubeconfig is configured"
    exit 1
fi

print_info "Connected to Kubernetes cluster"
echo ""

# Step 1: Create namespace
print_step "Step 1: Creating namespace"
kubectl apply -f "$SCRIPT_DIR/namespace.yaml"
echo ""

# Step 2: Create secrets
print_step "Step 2: Creating secrets from auth files"

create_secret_if_exists() {
    local SECRET_NAME=$1
    local AUTH_FILE=$2
    local BOT_DIR=$3
    local FILE_KEY=$4

    if [ -f "$PROJECT_ROOT/$BOT_DIR/$AUTH_FILE" ]; then
        print_info "Creating secret: $SECRET_NAME"
        kubectl create secret generic "$SECRET_NAME" \
            --from-file=${FILE_KEY}="$PROJECT_ROOT/$BOT_DIR/$AUTH_FILE" \
            --namespace=discord-bots \
            --dry-run=client -o yaml | kubectl apply -f -
    else
        print_warning "Auth file not found: $BOT_DIR/$AUTH_FILE - skipping secret creation"
        print_warning "You'll need to create this secret manually before deploying $SECRET_NAME"
    fi
}

# Go Bots
print_info "=== Creating secrets for Go Bots ==="
create_secret_if_exists "andybot-secret" "auth.txt" "AndyBot" "auth.txt"
create_secret_if_exists "piratebot-secret" "auth.txt" "PirateBot" "auth.txt"
create_secret_if_exists "wsb-secret" "auth.txt" "WSB" "auth.txt"
echo ""

# C# Bots
print_info "=== Creating secrets for C# Bots ==="
create_secret_if_exists "braincellbot-secret" "auth.txt" "BrainCellBot" "auth.txt"
create_secret_if_exists "dickjohnson-secret" "auth.txt" "DickJohnson" "auth.txt"
create_secret_if_exists "housemog-secret" "auth.txt" "HouseMog" "auth.txt"
create_secret_if_exists "manganotifier-secret" "auth.txt" "MangaNotifier" "auth.txt"
create_secret_if_exists "movienightbot-secret" "auth.txt" "MovieNightBot" "auth.txt"
echo ""

# Node.js Bots
print_info "=== Creating secrets for Node.js Bots ==="
create_secret_if_exists "owobot-secret" "auth.json" "OwOBot" "auth.json"
create_secret_if_exists "oyveybot-secret" "auth.json" "OyVeyBot" "auth.json"
create_secret_if_exists "redditsimbot-secret" "auth.json" "RedditSimBot" "auth.json"
create_secret_if_exists "tarotbot-secret" "auth.json" "TarotBot" "auth.json"
create_secret_if_exists "uwubot-secret" "auth.json" "UwUBot" "auth.json"
create_secret_if_exists "jailbot-secret" "auth.json" "JailBot" "auth.json"
create_secret_if_exists "jontronbot-secret" "auth.json" "JonTronBot" "auth.json"
create_secret_if_exists "terrydavisbot-secret" "auth.json" "TerryDavisBot" "auth.json"
echo ""

# Python Bots
print_info "=== Creating secrets for Python Bots ==="
create_secret_if_exists "scribebot-secret" "auth.txt" "ScribeBot" "auth.txt"
create_secret_if_exists "purpleharobot-secret" "auth.txt" "PurpleHaroBot" "auth.txt"
echo ""

# Step 3: Generate deployment manifests
print_step "Step 3: Generating deployment manifests"
if [ -f "$SCRIPT_DIR/generate-deployments.sh" ]; then
    bash "$SCRIPT_DIR/generate-deployments.sh"
else
    print_warning "generate-deployments.sh not found, skipping manifest generation"
fi
echo ""

# Step 4: Deploy bots
print_step "Step 4: Deploying bots to cluster"

if [ ! -d "$DEPLOYMENTS_DIR" ]; then
    print_error "Deployments directory not found: $DEPLOYMENTS_DIR"
    exit 1
fi

TOTAL=0
SUCCESS=0
FAILED=0
FAILED_DEPLOYMENTS=()

# Check for YAML files
YAML_FILES=$(find "$DEPLOYMENTS_DIR" -name "*.yaml" -type f 2>/dev/null || true)

if [ -z "$YAML_FILES" ]; then
    print_error "No deployment YAML files found in $DEPLOYMENTS_DIR"
    print_error "Run generate-deployments.sh first"
    exit 1
fi

# Deploy each bot
for deployment_file in $YAML_FILES; do
    BOT_NAME=$(basename "$deployment_file" .yaml)
    TOTAL=$((TOTAL + 1))

    print_info "Deploying ${BOT_NAME}..."

    if kubectl apply -f "$deployment_file"; then
        SUCCESS=$((SUCCESS + 1))
        print_info "✓ Successfully deployed ${BOT_NAME}"
    else
        FAILED=$((FAILED + 1))
        FAILED_DEPLOYMENTS+=("$BOT_NAME")
        print_error "✗ Failed to deploy ${BOT_NAME}"
    fi
    echo ""
done

# Summary
echo ""
echo "========================================="
print_info "Deployment Summary"
echo "========================================="
echo "Total deployments: $TOTAL"
echo -e "${GREEN}Successful: $SUCCESS${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -gt 0 ]; then
    echo ""
    print_error "Failed deployments:"
    for deployment in "${FAILED_DEPLOYMENTS[@]}"; do
        echo "  - $deployment"
    done
    echo ""
    print_warning "Check the errors above and ensure:"
    print_warning "  1. Docker images are built and pushed to your registry"
    print_warning "  2. Secrets are created with the correct auth files"
    print_warning "  3. Your k3s cluster has sufficient resources"
    exit 1
else
    echo ""
    print_info "All bots deployed successfully!"
    echo ""
    print_info "Useful commands:"
    echo "  # View all pods"
    echo "  kubectl get pods -n discord-bots"
    echo ""
    echo "  # View logs for a specific bot"
    echo "  kubectl logs -n discord-bots -l app=andybot -f"
    echo ""
    echo "  # View all deployments"
    echo "  kubectl get deployments -n discord-bots"
    echo ""
    echo "  # View all services"
    echo "  kubectl get services -n discord-bots"
    echo ""
    echo "  # Delete all resources"
    echo "  kubectl delete namespace discord-bots"
fi
