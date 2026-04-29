#!/bin/bash
# Setup Minikube for this project

set -e  # Stop on first error

echo "=============================================="
echo "  Pindrop - Minikube Setup"
echo "=============================================="

# Check required tools
echo ""
echo "[1/5] Checking prerequisites..."

if ! command -v minikube &> /dev/null; then
    echo "ERROR: minikube is not installed."
    echo "Install it from: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl is not installed."
    echo "Install it from: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

echo "✓ minikube found: $(minikube version --short)"
echo "✓ kubectl found: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

# Start Minikube
echo ""
echo "[2/5] Starting Minikube..."

# Skip start if already running
if minikube status | grep -q "Running"; then
    echo "✓ Minikube is already running"
else
    # Start with enough resources for both services
    minikube start \
        --cpus=4 \
        --memory=4096 \
        --driver=docker
    echo "✓ Minikube started"
fi

# Enable ingress addon
echo ""
echo "[3/5] Enabling Ingress addon..."

minikube addons enable ingress

# Wait for ingress controller
echo "Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=120s 2>/dev/null || echo "Ingress controller starting..."

echo "✓ Ingress addon enabled"

# Print Minikube IP
echo ""
echo "[4/5] Getting Minikube IP..."

MINIKUBE_IP=$(minikube ip)
echo "✓ Minikube IP: $MINIKUBE_IP"

# Final instructions
echo ""
echo "[5/5] Setup Complete!"
echo ""
echo "=============================================="
echo "  IMPORTANT: Add this to your /etc/hosts file"
echo "=============================================="
echo ""
echo "Run this command (requires sudo):"
echo ""
echo "  echo \"$MINIKUBE_IP pindrop.local\" | sudo tee -a /etc/hosts"
echo ""
echo "Or manually add this line to /etc/hosts:"
echo ""
echo "  $MINIKUBE_IP pindrop.local"
echo ""
echo "=============================================="
echo "  Next Steps"
echo "=============================================="
echo ""
echo "1. Build Docker images for Minikube:"
echo "   ./scripts/build-images.sh"
echo ""
echo "2. Create secrets from your .env file:"
echo "   ./scripts/create-secrets.sh"
echo ""
echo "3. Deploy to Kubernetes:"
echo "   ./scripts/deploy.sh"
echo ""
echo "4. Access the application:"
echo "   http://pindrop.local"
echo ""
