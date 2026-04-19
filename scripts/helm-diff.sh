#!/bin/bash
# =============================================================================
# HELM VALUES COMPARISON SCRIPT
# =============================================================================
# Compares dev vs prod Helm values to show the differences.
#
# Usage:
#   ./scripts/helm-diff.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CHART_DIR="$PROJECT_ROOT/k8s/pindrop-chart"

echo "=============================================="
echo "  Helm Values: Dev vs Prod Comparison"
echo "=============================================="
echo ""
echo "Differences between values.yaml and values-prod.yaml:"
echo "(< = dev only, > = prod only, different lines shown)"
echo "----------------------------------------------"
echo ""

# Use diff to show differences
# -y: side by side
# --suppress-common-lines: only show differences
diff -y --suppress-common-lines \
    "$CHART_DIR/values.yaml" \
    "$CHART_DIR/values-prod.yaml" || true

echo ""
echo "----------------------------------------------"
echo ""
echo "KEY DIFFERENCES:"
echo "  - Dev: 1 replica each (backend, frontend)"
echo "  - Prod: 3 replicas backend, 2 replicas frontend"
echo "  - Prod: Higher resource limits"
echo "  - Prod: DB_SSL enabled"
echo ""
