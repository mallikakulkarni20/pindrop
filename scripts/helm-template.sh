#!/bin/bash
# =============================================================================
# HELM TEMPLATE PREVIEW SCRIPT
# =============================================================================
# Shows what Kubernetes manifests Helm will generate WITHOUT deploying.
#
# This is useful for:
# - Debugging: See the actual YAML that would be applied
# - Review: Check what changes before deploying
# - Learning: Understand how values become manifests
#
# Usage:
#   ./scripts/helm-template.sh          # Preview with dev values
#   ./scripts/helm-template.sh prod     # Preview with prod values
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CHART_DIR="$PROJECT_ROOT/k8s/pindrop-chart"
RELEASE_NAME="pindrop"
NAMESPACE="pindrop"

ENVIRONMENT="${1:-dev}"

echo "=============================================="
echo "  Helm Template Preview"
echo "=============================================="
echo "Environment: $ENVIRONMENT"
echo ""
echo "This shows what YAML would be generated (not applied)."
echo "=============================================="
echo ""

# Determine values file
if [ "$ENVIRONMENT" = "prod" ]; then
    VALUES_FILE="$CHART_DIR/values-prod.yaml"
else
    VALUES_FILE="$CHART_DIR/values.yaml"
fi

# Render templates
helm template $RELEASE_NAME "$CHART_DIR" \
    --namespace $NAMESPACE \
    --values "$VALUES_FILE"
