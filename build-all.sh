#!/bin/bash

# Script to build and push all Discord bot Docker images to local k3s registry
# This assumes you have a local registry running at localhost:5000

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY="${REGISTRY:-localhost:5000}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Function to build and push a Docker image
build_and_push() {
    local BOT_DIR=$1
    local BOT_NAME=$2
    local IMAGE_NAME=$(echo "$BOT_NAME" | tr '[:upper:]' '[:lower:]')

    print_info "Building ${BOT_NAME}..."

    if [ ! -d "$SCRIPT_DIR/$BOT_DIR" ]; then
        print_error "Directory not found: $BOT_DIR"
        return 1
    fi

    if [ ! -f "$SCRIPT_DIR/$BOT_DIR/Dockerfile" ]; then
        print_error "Dockerfile not found in $BOT_DIR"
        return 1
    fi

    # Build the image
    if docker build -t "${REGISTRY}/${IMAGE_NAME}:latest" "$SCRIPT_DIR/$BOT_DIR"; then
        print_info "Successfully built ${IMAGE_NAME}"

        # Push to registry
        print_info "Pushing ${IMAGE_NAME} to registry..."
        if docker push "${REGISTRY}/${IMAGE_NAME}:latest"; then
            print_info "Successfully pushed ${IMAGE_NAME}"
            return 0
        else
            print_error "Failed to push ${IMAGE_NAME}"
            return 1
        fi
    else
        print_error "Failed to build ${IMAGE_NAME}"
        return 1
    fi
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if registry is accessible
print_info "Checking registry accessibility at ${REGISTRY}..."
if ! curl -s "http://${REGISTRY}/v2/" > /dev/null; then
    print_warning "Registry at ${REGISTRY} may not be accessible."
    print_warning "For k3s, you may need to set up a local registry first:"
    print_warning "  docker run -d -p 5000:5000 --restart=always --name registry registry:2"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_info "Starting build process for all Discord bots..."
echo ""

# Track success/failure
TOTAL=0
SUCCESS=0
FAILED=0
FAILED_BOTS=()

# Go Bots
print_info "=== Building Go Bots ==="
for bot in "AndyBot" "PirateBot" "WSB"; do
    TOTAL=$((TOTAL + 1))
    if build_and_push "$bot" "$bot"; then
        SUCCESS=$((SUCCESS + 1))
    else
        FAILED=$((FAILED + 1))
        FAILED_BOTS+=("$bot")
    fi
    echo ""
done

# C# Bots
print_info "=== Building C# Bots ==="
for bot in "BrainCellBot" "DickJohnson" "HouseMog" "MangaNotifier" "MovieNightBot"; do
    TOTAL=$((TOTAL + 1))
    if build_and_push "$bot" "$bot"; then
        SUCCESS=$((SUCCESS + 1))
    else
        FAILED=$((FAILED + 1))
        FAILED_BOTS+=("$bot")
    fi
    echo ""
done

# Node.js Bots
print_info "=== Building Node.js Bots ==="
for bot in "OwOBot" "OyVeyBot" "RedditSimBot" "TarotBot" "UwUBot" "JailBot" "JonTronBot" "TerryDavisBot"; do
    TOTAL=$((TOTAL + 1))
    if build_and_push "$bot" "$bot"; then
        SUCCESS=$((SUCCESS + 1))
    else
        FAILED=$((FAILED + 1))
        FAILED_BOTS+=("$bot")
    fi
    echo ""
done

# Python Bots
print_info "=== Building Python Bots ==="
for bot in "ScribeBot" "PurpleHaroBot"; do
    TOTAL=$((TOTAL + 1))
    if build_and_push "$bot" "$bot"; then
        SUCCESS=$((SUCCESS + 1))
    else
        FAILED=$((FAILED + 1))
        FAILED_BOTS+=("$bot")
    fi
    echo ""
done

# Summary
echo ""
echo "========================================="
print_info "Build Summary"
echo "========================================="
echo "Total bots: $TOTAL"
echo -e "${GREEN}Successful: $SUCCESS${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -gt 0 ]; then
    echo ""
    print_error "Failed bots:"
    for bot in "${FAILED_BOTS[@]}"; do
        echo "  - $bot"
    done
    exit 1
else
    echo ""
    print_info "All bots built and pushed successfully!"
    print_info "You can now deploy them to your k3s cluster using:"
    print_info "  cd kubernetes"
    print_info "  ./deploy-all.sh"
fi
