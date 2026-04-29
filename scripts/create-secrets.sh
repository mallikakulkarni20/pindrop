#!/bin/bash
# Create Kubernetes secret values from local .env

set -e  # Stop on first error

echo "=============================================="
echo "  Pindrop - Create Kubernetes Secrets"
echo "=============================================="

# Resolve project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

# Validate prerequisites
echo ""
echo "[1/4] Checking prerequisites..."

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: .env file not found at $ENV_FILE"
    echo "Please create a .env file with your secrets."
    exit 1
fi

echo "✓ Found .env file"

# Create namespace if missing
if ! kubectl get namespace pindrop &> /dev/null; then
    echo "Creating namespace 'pindrop'..."
    kubectl apply -f "$PROJECT_ROOT/k8s/manifests/namespace.yaml"
fi

echo "✓ Namespace 'pindrop' exists"

# Load required values from .env
echo ""
echo "[2/4] Reading secrets from .env file..."

# Load env vars
source "$ENV_FILE"

# Validate required env vars
REQUIRED_VARS=(
    "SUPABASE_URL"
    "SUPABASE_SERVICE_ROLE_KEY"
    "JWT_SECRET"
    "JWT_REFRESH_SECRET"
    "OPENAI_API_KEY"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "ERROR: Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Please add these to your .env file."
    exit 1
fi

echo "✓ All required variables found"

# Recreate secret cleanly
echo ""
echo "[3/4] Creating Kubernetes secret..."

kubectl delete secret pindrop-secrets -n pindrop 2>/dev/null || true

# Create secret (kubectl handles encoding)

kubectl create secret generic pindrop-secrets \
    --namespace=pindrop \
    --from-literal=SUPABASE_URL="${SUPABASE_URL}" \
    --from-literal=SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY}" \
    --from-literal=JWT_SECRET="${JWT_SECRET}" \
    --from-literal=JWT_REFRESH_SECRET="${JWT_REFRESH_SECRET}" \
    --from-literal=OPENAI_API_KEY="${OPENAI_API_KEY}" \
    --from-literal=OPENAI_MODEL="${OPENAI_MODEL:-gpt-3.5-turbo}" \
    --from-literal=GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-}" \
    --from-literal=GOOGLE_CLIENT_SECRET="${GOOGLE_CLIENT_SECRET:-}"

echo "✓ Secret 'pindrop-secrets' created"

# Verify secret exists
echo ""
echo "[4/4] Verifying secret..."

kubectl get secret pindrop-secrets -n pindrop

echo ""
echo "=============================================="
echo "  Secrets Created Successfully!"
echo "=============================================="
echo ""
echo "To view secret keys (not values):"
echo "  kubectl describe secret pindrop-secrets -n pindrop"
echo ""
echo "Next step: Deploy the application"
echo "  ./scripts/deploy.sh"
echo ""
