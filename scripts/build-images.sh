#!/bin/bash
# =============================================================================
# BUILD DOCKER IMAGES FOR MINIKUBE
# =============================================================================
# This script builds Docker images inside Minikube's Docker environment.
#
# Why build inside Minikube?
# - Minikube runs its own Docker daemon (separate from your host)
# - Images built on your host machine aren't visible to Minikube
# - By pointing to Minikube's Docker, images are immediately available
#
# What it does:
# 1. Points your terminal to Minikube's Docker daemon
# 2. Builds the backend image with production Dockerfile
# 3. Builds the frontend image with VITE_API_URL=/api
#
# Usage:
#   chmod +x scripts/build-images.sh
#   ./scripts/build-images.sh
# =============================================================================

set -e  # Exit on any error

echo "=============================================="
echo "  Pindrop - Build Docker Images for Minikube"
echo "=============================================="

# -----------------------------------------------------------------------------
# Get Project Root Directory
# -----------------------------------------------------------------------------
# Script might be called from different directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo ""
echo "Project root: $PROJECT_ROOT"

# -----------------------------------------------------------------------------
# Point to Minikube's Docker Daemon
# -----------------------------------------------------------------------------
echo ""
echo "[1/4] Configuring Docker to use Minikube's daemon..."

# Check if Minikube is running
if ! minikube status | grep -q "Running"; then
    echo "ERROR: Minikube is not running."
    echo "Start it with: ./scripts/minikube-setup.sh"
    exit 1
fi

# Configure shell to use Minikube's Docker
# This sets DOCKER_HOST, DOCKER_CERT_PATH, etc.
eval $(minikube docker-env)

echo "✓ Now using Minikube's Docker daemon"
echo "  Docker host: $DOCKER_HOST"

# -----------------------------------------------------------------------------
# Build Backend Image
# -----------------------------------------------------------------------------
echo ""
echo "[2/4] Building backend image..."

docker build \
    -t pindrop-backend:latest \
    -f "$PROJECT_ROOT/Dockerfile" \
    "$PROJECT_ROOT"

echo "✓ Backend image built: pindrop-backend:latest"

# -----------------------------------------------------------------------------
# Build Frontend Image
# -----------------------------------------------------------------------------
echo ""
echo "[3/4] Building frontend image..."

# Build with VITE_API_URL=/api so frontend makes relative API calls
# The Ingress will route /api/* to the backend service
docker build \
    -t pindrop-frontend:latest \
    --build-arg VITE_API_URL=/api \
    -f "$PROJECT_ROOT/frontend/Dockerfile" \
    "$PROJECT_ROOT/frontend"

echo "✓ Frontend image built: pindrop-frontend:latest"

# -----------------------------------------------------------------------------
# List Images
# -----------------------------------------------------------------------------
echo ""
echo "[4/4] Verifying images..."
echo ""

docker images | grep pindrop

echo ""
echo "=============================================="
echo "  Build Complete!"
echo "=============================================="
echo ""
echo "Images are now available in Minikube's Docker."
echo ""
echo "Next steps:"
echo "1. Create secrets: ./scripts/create-secrets.sh"
echo "2. Deploy: ./scripts/deploy.sh"
echo ""
