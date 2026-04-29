#!/bin/bash
# Build backend/frontend images in Minikube's Docker daemon

set -e  # Stop on first error

echo "=============================================="
echo "  Pindrop - Build Docker Images for Minikube"
echo "=============================================="

# Resolve project root from this script path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo ""
echo "Project root: $PROJECT_ROOT"

# Point docker CLI at Minikube daemon
echo ""
echo "[1/4] Configuring Docker to use Minikube's daemon..."

# Make sure Minikube is up
if ! minikube status | grep -q "Running"; then
    echo "ERROR: Minikube is not running."
    echo "Start it with: ./scripts/minikube-setup.sh"
    exit 1
fi

# Export docker env vars for Minikube
eval $(minikube docker-env)

echo "✓ Now using Minikube's Docker daemon"
echo "  Docker host: $DOCKER_HOST"

# Build backend image
echo ""
echo "[2/4] Building backend image..."

docker build \
    -t pindrop-backend:latest \
    -f "$PROJECT_ROOT/Dockerfile" \
    "$PROJECT_ROOT"

echo "✓ Backend image built: pindrop-backend:latest"

# Build frontend image
echo ""
echo "[3/4] Building frontend image..."

# Build with relative API path for ingress routing
docker build \
    -t pindrop-frontend:latest \
    --build-arg VITE_API_URL=/api \
    -f "$PROJECT_ROOT/frontend/Dockerfile" \
    "$PROJECT_ROOT/frontend"

echo "✓ Frontend image built: pindrop-frontend:latest"

# Quick image check
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
