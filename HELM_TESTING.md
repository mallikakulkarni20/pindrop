# Helm Testing Guide - Week 3

This document explains what Helm does and how to test the Pindrop Helm chart.

## What is Helm?

**Helm is a package manager for Kubernetes** - think of it like `npm` for Node.js or `apt` for Ubuntu, but for Kubernetes applications.

### The Problem Helm Solves

Without Helm, deploying to different environments requires:
- Copying YAML files and manually changing values
- Maintaining separate files for dev/staging/prod
- No easy way to version or rollback deployments

### How Helm Solves It

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           HELM CHART                                     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │
│  │   Chart.yaml    │    │   values.yaml   │    │   templates/    │     │
│  │   (metadata)    │    │   (defaults)    │    │   (YAML with    │     │
│  │                 │    │                 │    │   variables)    │     │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘     │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ helm install
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         KUBERNETES CLUSTER                               │
│                                                                          │
│   templates/backend-deployment.yaml  +  values.yaml                     │
│                  │                           │                           │
│                  ▼                           ▼                           │
│   replicas: {{ .Values.backend.replicas }}  →  replicas: 1              │
│   image: {{ .Values.backend.image.tag }}    →  image: latest            │
│                                                                          │
│   Final YAML applied to cluster                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Key Concepts

| Concept | Description | Example |
|---------|-------------|---------|
| **Chart** | A package containing templates + values | `k8s/pindrop-chart/` |
| **Release** | An instance of a chart deployed to K8s | `helm install pindrop ./chart` |
| **Values** | Configuration that customizes the chart | `values.yaml`, `values-prod.yaml` |
| **Templates** | YAML files with `{{ .Values.x }}` placeholders | `templates/backend-deployment.yaml` |

---

## Files Created

```
k8s/pindrop-chart/
├── Chart.yaml              # Chart metadata (name, version)
├── values.yaml             # Default values (dev environment)
├── values-prod.yaml        # Production overrides
└── templates/
    ├── _helpers.tpl        # Reusable template functions
    ├── NOTES.txt           # Post-install instructions
    ├── configmap.yaml      # ConfigMap template
    ├── secrets.yaml        # Secrets template
    ├── backend-deployment.yaml
    ├── backend-service.yaml
    ├── frontend-deployment.yaml
    ├── frontend-service.yaml
    └── ingress.yaml

scripts/
├── helm-deploy.sh          # Deploy with Helm
├── helm-template.sh        # Preview generated YAML
└── helm-diff.sh            # Compare dev vs prod values
```

---

## Prerequisites

Install Helm if you haven't already:

```bash
# macOS
brew install helm

# Verify
helm version
```

---

## Testing Step by Step

### Step 1: Preview the Generated YAML (No Deployment)

Before deploying, see what Kubernetes YAML Helm will generate:

```bash
cd /Users/mallikakulkarni/CIS1912-DevOps/pindrop

# Preview with development values
./scripts/helm-template.sh

# Preview with production values
./scripts/helm-template.sh prod
```

**What you'll see:** The actual Kubernetes YAML that would be applied, with all `{{ .Values.xxx }}` replaced with actual values.

**Example output:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pindrop-backend
spec:
  replicas: 1              # From values.yaml: backend.replicas: 1
  ...
```

### Step 2: Compare Dev vs Prod Values

See the differences between environments:

```bash
./scripts/helm-diff.sh
```

**Key differences:**
| Setting | Dev | Prod |
|---------|-----|------|
| `backend.replicas` | 1 | 3 |
| `frontend.replicas` | 1 | 2 |
| `backend.resources.limits.memory` | 512Mi | 1Gi |
| `backend.env.DB_SSL` | false | true |

### Step 3: Clean Up Old Deployment (If Exists)

If you deployed with `kubectl apply` earlier, clean it up first:

```bash
# Delete the old namespace (removes everything)
kubectl delete namespace pindrop

# Wait for deletion
kubectl get namespace pindrop  # Should say "not found"
```

### Step 4: Deploy with Helm (Development)

```bash
# Deploy with development values
./scripts/helm-deploy.sh
```

**What happens:**
1. Creates namespace `pindrop`
2. Creates secrets from your `.env` file
3. Validates the Helm chart
4. Deploys all resources using `helm upgrade --install`

**Expected output:**
```
✓ Minikube is running
✓ Helm is installed
✓ Docker images exist
✓ Helm chart found
✓ Namespace ready
✓ Secrets created
✓ Chart validation passed
Release "pindrop" has been deployed!
```

### Step 5: Verify Deployment

```bash
# Check Helm release
helm list -n pindrop

# Check pods
kubectl get pods -n pindrop

# Check all resources
kubectl get all -n pindrop
```

**Expected:**
```
NAME                                READY   STATUS    RESTARTS
pod/pindrop-backend-xxx             1/1     Running   0
pod/pindrop-frontend-xxx            1/1     Running   0
```

### Step 6: Access the Application

```bash
# Port forward (for macOS)
kubectl port-forward svc/pindrop-frontend 8080:80 -n pindrop &
kubectl port-forward svc/pindrop-backend 3001:3001 -n pindrop &

# Open in browser
open http://localhost:8080

# Test backend
curl http://localhost:3001/health
```

---

## Demonstrating Helm's Power

### Demo 1: Change Replicas Without Editing Files

```bash
# Scale backend to 3 replicas using --set
helm upgrade pindrop ./k8s/pindrop-chart \
  -n pindrop \
  --set backend.replicas=3

# Verify
kubectl get pods -n pindrop
# You should now see 3 backend pods!
```

### Demo 2: Deploy to "Production"

```bash
# Deploy with production values
./scripts/helm-deploy.sh prod

# Verify more replicas
kubectl get pods -n pindrop
# backend: 3 pods, frontend: 2 pods
```

### Demo 3: View Release History

```bash
# See deployment history
helm history pindrop -n pindrop
```

**Output:**
```
REVISION    STATUS      DESCRIPTION
1           superseded  Install complete
2           deployed    Upgrade complete
```

### Demo 4: Rollback to Previous Version

```bash
# Rollback to revision 1
helm rollback pindrop 1 -n pindrop

# Verify
kubectl get pods -n pindrop
# Back to 1 replica each
```

---

## Understanding the Templates

### Example: How values.yaml Becomes Deployment YAML

**values.yaml:**
```yaml
backend:
  replicas: 1
  image:
    repository: pindrop-backend
    tag: latest
  resources:
    limits:
      memory: "512Mi"
```

**templates/backend-deployment.yaml:**
```yaml
spec:
  replicas: {{ .Values.backend.replicas }}
  template:
    spec:
      containers:
        - image: {{ .Values.backend.image.repository }}:{{ .Values.backend.image.tag }}
          resources:
            limits:
              memory: {{ .Values.backend.resources.limits.memory }}
```

**Generated YAML (after `helm template`):**
```yaml
spec:
  replicas: 1
  template:
    spec:
      containers:
        - image: pindrop-backend:latest
          resources:
            limits:
              memory: "512Mi"
```

---

## Useful Helm Commands

```bash
# List all releases
helm list -n pindrop

# Get release status
helm status pindrop -n pindrop

# Get values used in a release
helm get values pindrop -n pindrop

# Get all generated manifests
helm get manifest pindrop -n pindrop

# Uninstall release
helm uninstall pindrop -n pindrop

# Lint chart (check for errors)
helm lint ./k8s/pindrop-chart
```

---

## Troubleshooting

### "Error: INSTALLATION FAILED: cannot re-use a name that is still in use"

The release already exists. Use upgrade instead:
```bash
helm upgrade pindrop ./k8s/pindrop-chart -n pindrop
```

### "Error: secrets not found"

Create secrets first:
```bash
./scripts/create-secrets.sh
```

### "ImagePullBackOff" error

Images not in Minikube's Docker. Rebuild:
```bash
./scripts/build-images.sh
kubectl rollout restart deployment -n pindrop
```

---

## Summary: Why Helm Matters for DevOps

| Without Helm | With Helm |
|--------------|-----------|
| Edit YAML files for each environment | `helm install -f values-prod.yaml` |
| Copy-paste manifests | Single chart, multiple configurations |
| Manual rollback (scary) | `helm rollback pindrop 1` |
| No version history | `helm history pindrop` |
| Hard to share | Package and share charts |

**For your DevOps class:** Helm demonstrates the principles of:
- **Reproducibility**: Same chart, predictable results
- **Separation of Concerns**: Templates separate from configuration
- **Environment Parity**: Dev/prod use same templates, different values
