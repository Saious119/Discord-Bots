#!/bin/bash

# Quick script to apply build fixes for ScribeBot and PurpleHaroBot
# Run this on your Raspberry Pi after pulling the latest code

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo "Applying Build Fixes"
echo "======================================"
echo ""

# Check if we're in the right directory
if [ ! -f "$SCRIPT_DIR/build-all.sh" ]; then
    echo "ERROR: Please run this script from the Discord-Bots directory"
    exit 1
fi

# Create ScribeBot minimal requirements
echo "[1/2] Creating ScribeBot minimal requirements..."
cat > "$SCRIPT_DIR/ScribeBot/requirements-minimal.txt" <<'EOF'
discord.py==2.3.2
requests==2.31.0
aiohttp==3.12.14
EOF
echo "✓ Created ScribeBot/requirements-minimal.txt"
echo ""

# Backup original Dockerfiles
echo "[2/2] Backing up original Dockerfiles..."
if [ -f "$SCRIPT_DIR/ScribeBot/Dockerfile" ]; then
    cp "$SCRIPT_DIR/ScribeBot/Dockerfile" "$SCRIPT_DIR/ScribeBot/Dockerfile.backup"
    echo "✓ Backed up ScribeBot/Dockerfile"
fi

if [ -f "$SCRIPT_DIR/PurpleHaroBot/Dockerfile" ]; then
    cp "$SCRIPT_DIR/PurpleHaroBot/Dockerfile" "$SCRIPT_DIR/PurpleHaroBot/Dockerfile.backup"
    echo "✓ Backed up PurpleHaroBot/Dockerfile"
fi
echo ""

echo "======================================"
echo "Build Fixes Applied Successfully!"
echo "======================================"
echo ""
echo "Next steps:"
echo "  1. Test individual builds:"
echo "     docker build -t localhost:5000/scribebot:latest ScribeBot/"
echo "     docker build -t localhost:5000/purpleharobot:latest PurpleHaroBot/"
echo ""
echo "  2. If tests pass, run full build:"
echo "     ./build-all.sh"
echo ""
echo "Note: Original Dockerfiles backed up as *.backup"
echo ""
