#!/bin/bash
# Deploy Pindrop with Helm (dev by default, prod optional)

set -e  # Stop on first error

# Paths/config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CHART_DIR="$PROJECT_ROOT/k8s/pindrop-chart"
RELEASE_NAME="pindrop"
NAMESPACE="pindrop"

# Env arg: dev (default) or prod
ENVIRONMENT="${1:-dev}"

echo "=============================================="
echo "  Pindrop - Helm Deployment"
echo "=============================================="
echo "Environment: $ENVIRONMENT"
echo ""

# Prerequisites
echo "[1/5] Checking prerequisites..."

# Minikube must be running
if ! minikube status | grep -q "Running"; then
    echo "ERROR: Minikube is not running."
    echo "Start it with: ./scripts/minikube-setup.sh"
    exit 1
fi
echo "✓ Minikube is running"

# Helm CLI check
if ! command -v helm &> /dev/null; then
    echo "ERROR: Helm is not installed."
    echo "Install with: brew install helm"
    exit 1
fi
echo "✓ Helm is installed: $(helm version --short)"

# Ensure local images exist in Minikube daemon
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

# Chart presence check
if [ ! -f "$CHART_DIR/Chart.yaml" ]; then
    echo "ERROR: Helm chart not found at $CHART_DIR"
    exit 1
fi
echo "✓ Helm chart found"

# Namespace
echo ""
echo "[2/5] Creating namespace..."

kubectl create namespace $NAMESPACE 2>/dev/null || echo "Namespace '$NAMESPACE' already exists"
echo "✓ Namespace ready"

# Secrets
echo ""
echo "[3/5] Creating secrets..."

if kubectl get secret pindrop-secrets -n $NAMESPACE &> /dev/null; then
    echo "✓ Secrets already exist"
else
    echo "Creating secrets from .env file..."
    if [ -f "$PROJECT_ROOT/.env" ]; then
        source "$PROJECT_ROOT/.env"
        kubectl create secret generic pindrop-secrets             --namespace=$NAMESPACE             --from-literal=SUPABASE_URL="${SUPABASE_URL:-}"             --from-literal=SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"             --from-literal=JWT_SECRET="${JWT_SECRET:-}"             --from-literal=JWT_REFRESH_SECRET="${JWT_REFRESH_SECRET:-}"             --from-literal=OPENAI_API_KEY="${OPENAI_API_KEY:-}"             --from-literal=OPENAI_MODEL="${OPENAI_MODEL:-gpt-3.5-turbo}"             --from-literal=GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-}"             --from-literal=GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET:-}"
        echo "✓ Secrets created from .env"
    else
        echo "WARNING: .env file not found. Secrets must be created manually."
    fi
fi

# Lint
echo ""
echo "[4/5] Validating Helm chart..."

helm lint "$CHART_DIR"
echo "✓ Chart validation passed"

# Deploy
echo ""
echo "[5/5] Deploying with Helm..."

if [ "$ENVIRONMENT" = "prod" ]; then
    VALUES_FILE="$CHART_DIR/values-prod.yaml"
    echo "Using production values: $VALUES_FILE"
else
    VALUES_FILE="$CHART_DIR/values.yaml"
    echo "Using development values: $VALUES_FILE"
fi

# Install if missing, otherwise upgrade
helm upgrade --install $RELEASE_NAME "$CHART_DIR"     --namespace $NAMESPACE     --values "$VALUES_FILE"     --wait     --timeout 5m

echo ""
echo "=============================================="
echo "  Deployment Complete!"
echo "=============================================="
echo ""

helm status $RELEASE_NAME -n $NAMESPACE

echo ""
echo "Quick access (for macOS):"
echo "  kubectl port-forward svc/$RELEASE_NAME-frontend 8080:80 -n $NAMESPACE &"
echo "  open http://localhost:8080"
echo ""
