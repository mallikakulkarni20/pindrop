#!/bin/bash
# Deploy Kubernetes manifests for Pindrop

set -e  # Stop on first error

echo "=============================================="
echo "  Pindrop - Deploy to Kubernetes"
echo "=============================================="

# Resolve project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFESTS_DIR="$PROJECT_ROOT/k8s/manifests"

# Prerequisite checks
echo ""
echo "[1/6] Checking prerequisites..."

# Ensure Minikube is running
if ! minikube status | grep -q "Running"; then
    echo "ERROR: Minikube is not running."
    echo "Start it with: ./scripts/minikube-setup.sh"
    exit 1
fi
echo "✓ Minikube is running"

# Ensure images exist in Minikube docker daemon
eval $(minikube docker-env)
if ! docker images | grep -q "pindrop-backend"; then
    echo "ERROR: pindrop-backend image not found."
    echo "Build it with: ./scripts/build-images.sh"
    exit 1
fi
if ! docker images | grep -q "pindrop-frontend"; then
    echo "ERROR: pindrop-frontend image not found."
    echo "Build it with: ./scripts/build-images.sh"
    exit 1
fi
echo "✓ Docker images exist"

# Apply namespace
echo ""
echo "[2/6] Applying namespace..."

kubectl apply -f "$MANIFESTS_DIR/namespace.yaml"
echo "✓ Namespace applied"

# Apply config
echo ""
echo "[3/6] Applying ConfigMap..."

kubectl apply -f "$MANIFESTS_DIR/configmap.yaml"
echo "✓ ConfigMap applied"

# Check secrets
echo ""
echo "[4/6] Checking secrets..."

if kubectl get secret pindrop-secrets -n pindrop &> /dev/null; then
    echo "✓ Secrets exist"
else
    echo "WARNING: Secrets not found!"
    echo "Create them with: ./scripts/create-secrets.sh"
    echo ""
    read -p "Continue without secrets? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Apply deployments/services
echo ""
echo "[5/6] Applying Deployments and Services..."

kubectl apply -f "$MANIFESTS_DIR/backend-deployment.yaml"
kubectl apply -f "$MANIFESTS_DIR/backend-service.yaml"
echo "✓ Backend deployed"

kubectl apply -f "$MANIFESTS_DIR/frontend-deployment.yaml"
kubectl apply -f "$MANIFESTS_DIR/frontend-service.yaml"
echo "✓ Frontend deployed"

# Apply ingress
echo ""
echo "[6/6] Applying Ingress..."

kubectl apply -f "$MANIFESTS_DIR/ingress.yaml"
echo "✓ Ingress applied"

# Wait for pods
echo ""
echo "Waiting for pods to be ready..."

kubectl wait --for=condition=ready pod \
    --selector=app=pindrop \
    --namespace=pindrop \
    --timeout=120s

# Print status and access info
echo ""
echo "=============================================="
echo "  Deployment Complete!"
echo "=============================================="
echo ""
echo "Resource Status:"
echo "----------------"
kubectl get all -n pindrop
echo ""
echo "Ingress Status:"
echo "---------------"
kubectl get ingress -n pindrop
echo ""
echo "=============================================="
echo "  Access the Application"
echo "=============================================="
echo ""
echo "Make sure you've added this to /etc/hosts:"
MINIKUBE_IP=$(minikube ip)
echo "  $MINIKUBE_IP pindrop.local"
echo ""
echo "Then open in your browser:"
echo "  http://pindrop.local"
echo ""
echo "Useful commands:"
echo "  kubectl logs -l component=backend -n pindrop    # Backend logs"
echo "  kubectl logs -l component=frontend -n pindrop   # Frontend logs"
echo "  kubectl get pods -n pindrop                     # Pod status"
echo "  kubectl describe pod <pod-name> -n pindrop      # Pod details"
echo ""
