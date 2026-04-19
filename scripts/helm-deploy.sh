#!/bin/bash
# =============================================================================
# HELM DEPLOYMENT SCRIPT
# =============================================================================
# Deploys Pindrop using Helm chart with development or production values.
#
# What this script does:
# 1. Validates prerequisites (Minikube, Helm, images)
# 2. Creates namespace if needed
# 3. Creates Kubernetes secrets from .env file
# 4. Deploys using Helm
#
# Usage:
#   ./scripts/helm-deploy.sh          # Deploy with dev values (default)
#   ./scripts/helm-deploy.sh dev      # Deploy with dev values
#   ./scripts/helm-deploy.sh prod     # Deploy with prod values
# =============================================================================

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CHART_DIR="$PROJECT_ROOT/k8s/pindrop-chart"
RELEASE_NAME="pindrop"
NAMESPACE="pindrop"

# Get environment (default: dev)
ENVIRONMENT="${1:-dev}"

echo "=============================================="
echo "  Pindrop - Helm Deployment"
echo "=============================================="
echo "Environment: $ENVIRONMENT"
echo ""

# -----------------------------------------------------------------------------
# Check Prerequisites
# -----------------------------------------------------------------------------
echo "[1/5] Checking prerequisites..."

# Check Minikube
if ! minikube status | grep -q "Running"; then
    echo "ERROR: Minikube is not running."
    echo "Start it with: ./scripts/minikube-setup.sh"
    exit 1
fi
echo "✓ Minikube is running"

# Check Helm
if ! command -v helm &> /dev/null; then
    echo "ERROR: Helm is not installed."
    echo "Install with: brew install helm"
    exit 1
fi
echo "✓ Helm is installed: $(helm version --short)"

# Check Docker images
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

# Check chart exists
if [ ! -f "$CHART_DIR/Chart.yaml" ]; then
    echo "ERROR: Helm chart not found at $CHART_DIR"
    exit 1
fi
echo "✓ Helm chart found"

# -----------------------------------------------------------------------------
# Create Namespace
# -----------------------------------------------------------------------------
echo ""
echo "[2/5] Creating namespace..."

kubectl create namespace $NAMESPACE 2>/dev/null || echo "Namespace '$NAMESPACE' already exists"
echo "✓ Namespace ready"

# -----------------------------------------------------------------------------
# Create Secrets (from .env file)
# -----------------------------------------------------------------------------
echo ""
echo "[3/5] Creating secrets..."

# Check if secrets exist
if kubectl get secret pindrop-secrets -n $NAMESPACE &> /dev/null; then
    echo "✓ Secrets already exist"
else
    echo "Creating secrets from .env file..."
    if [ -f "$PROJECT_ROOT/.env" ]; then
        source "$PROJECT_ROOT/.env"
        kubectl create secret generic pindrop-secrets \
            --namespace=$NAMESPACE \
            --from-literal=SUPABASE_URL="${SUPABASE_URL:-}" \
            --from-literal=SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-}" \
            --from-literal=JWT_SECRET="${JWT_SECRET:-}" \
            --from-literal=JWT_REFRESH_SECRET="${JWT_REFRESH_SECRET:-}" \
            --from-literal=OPENAI_API_KEY="${OPENAI_API_KEY:-}" \
            --from-literal=OPENAI_MODEL="${OPENAI_MODEL:-gpt-3.5-turbo}" \
            --from-literal=GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-}" \
            --from-literal=GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET:-}"
        echo "✓ Secrets created from .env"
    else
        echo "WARNING: .env file not found. Secrets must be created manually."
    fi
fi

# -----------------------------------------------------------------------------
# Lint Chart (validate)
# -----------------------------------------------------------------------------
echo ""
echo "[4/5] Validating Helm chart..."

helm lint "$CHART_DIR"
echo "✓ Chart validation passed"

# -----------------------------------------------------------------------------
# Deploy with Helm
# -----------------------------------------------------------------------------
echo ""
echo "[5/5] Deploying with Helm..."

# Determine values file
if [ "$ENVIRONMENT" = "prod" ]; then
    VALUES_FILE="$CHART_DIR/values-prod.yaml"
    echo "Using production values: $VALUES_FILE"
else
    VALUES_FILE="$CHART_DIR/values.yaml"
    echo "Using development values: $VALUES_FILE"
fi

# Deploy or upgrade
# helm upgrade --install: Install if not exists, upgrade if exists
helm upgrade --install $RELEASE_NAME "$CHART_DIR" \
    --namespace $NAMESPACE \
    --values "$VALUES_FILE" \
    --wait \
    --timeout 5m

echo ""
echo "=============================================="
echo "  Deployment Complete!"
echo "=============================================="
echo ""

# Show status
helm status $RELEASE_NAME -n $NAMESPACE

echo ""
echo "Quick access (for macOS):"
echo "  kubectl port-forward svc/$RELEASE_NAME-frontend 8080:80 -n $NAMESPACE &"
echo "  open http://localhost:8080"
echo ""
