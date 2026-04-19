# Pindrop - DevOps Final Project

A travel planning application transformed into a production-ready, Kubernetes-deployable system using modern DevOps practices.

## Project Overview

This project takes an existing full-stack application (Pindrop - a travel planning app) and implements a complete DevOps pipeline including:

- **Docker**: Multi-stage production builds for frontend and backend
- **Kubernetes**: Container orchestration with Deployments, Services, ConfigMaps, Secrets, and Ingress
- **Helm**: Package management with environment-specific configurations
- **Minikube**: Local Kubernetes testing environment

### Application Stack

| Component | Technology |
|-----------|------------|
| Frontend | React, Vite, TypeScript, Tailwind CSS |
| Backend | Node.js, Express |
| Database | PostgreSQL (Supabase) |
| Container Runtime | Docker |
| Orchestration | Kubernetes |
| Package Manager | Helm |

---

## What Was Accomplished

### Week 1: Docker Containerization

- Created multi-stage `Dockerfile` for backend (210MB production image)
- Created multi-stage `Dockerfile` for frontend with nginx (55MB production image)
- Configured nginx for SPA routing
- Created `docker-compose.prod.yml` for local testing

### Week 2: Kubernetes Manifests

- Backend Deployment and Service
- Frontend Deployment and Service
- ConfigMap for non-sensitive configuration
- Secrets template for sensitive data
- Ingress for path-based routing (/api/* → backend, /* → frontend)
- Health checks (liveness and readiness probes)

### Week 3: Helm Charts

- Converted all manifests to Helm templates
- Created `values.yaml` with development defaults
- Created `values-prod.yaml` with production overrides
- Implemented helper templates for DRY code
- Created deployment scripts for one-command deploys

---

## Project Structure

```
pindrop/
├── Dockerfile                      # Backend production image
├── docker-compose.yml              # Development setup
├── docker-compose.prod.yml         # Production testing
├── frontend/
│   ├── Dockerfile                  # Frontend production image (nginx)
│   └── nginx.conf                  # SPA routing configuration
├── backend/
│   └── server.js                   # Express API server
├── k8s/
│   ├── manifests/                  # Raw Kubernetes YAML (Week 2)
│   │   ├── namespace.yaml
│   │   ├── configmap.yaml
│   │   ├── secrets.yaml.template
│   │   ├── backend-deployment.yaml
│   │   ├── backend-service.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── frontend-service.yaml
│   │   └── ingress.yaml
│   └── pindrop-chart/              # Helm chart (Week 3)
│       ├── Chart.yaml
│       ├── values.yaml             # Dev configuration
│       ├── values-prod.yaml        # Prod configuration
│       └── templates/
│           ├── _helpers.tpl
│           ├── configmap.yaml
│           ├── secrets.yaml
│           ├── backend-deployment.yaml
│           ├── backend-service.yaml
│           ├── frontend-deployment.yaml
│           ├── frontend-service.yaml
│           └── ingress.yaml
├── scripts/
│   ├── minikube-setup.sh           # Initialize Minikube
│   ├── build-images.sh             # Build Docker images
│   ├── create-secrets.sh           # Create K8s secrets
│   ├── deploy.sh                   # Deploy with kubectl
│   ├── helm-deploy.sh              # Deploy with Helm
│   ├── helm-template.sh            # Preview Helm output
│   └── helm-diff.sh                # Compare dev vs prod
├── DOCKER_TESTING.md               # Docker testing guide
├── KUBERNETES_TESTING.md           # Kubernetes testing guide
├── HELM_TESTING.md                 # Helm testing guide
└── DEMO_SCRIPT.md                  # Presentation demo script
```

---

## Technologies & Philosophies Applied

### Technologies (from course)

| Technology | How It's Used |
|------------|---------------|
| **Docker** | Multi-stage builds, production images, docker-compose |
| **Kubernetes** | Deployments, Services, ConfigMaps, Secrets, Ingress |
| **Helm** | Templating, values files, releases, rollbacks |
| **Minikube** | Local Kubernetes cluster for testing |

### DevOps Philosophies (from course)

| Philosophy | How It's Applied |
|------------|------------------|
| **Reproducibility** | Same Helm chart produces identical deployments |
| **Portability** | Containerized app runs on any Kubernetes cluster |
| **Declarative Configuration** | Desired state defined in YAML, K8s maintains it |
| **Environment Parity** | Dev/prod use same templates, different values |
| **Separation of Concerns** | Config (values.yaml) separate from templates |
| **Infrastructure as Code** | All configuration version-controlled in Git |

---

## How to Test/View What Was Built

### Prerequisites

```bash
# Install required tools (macOS)
brew install minikube kubectl helm

# Verify installations
minikube version
kubectl version --client
helm version
```

### Quick Start

```bash
# 1. Clone and navigate to project
cd pindrop

# 2. Start Minikube
./scripts/minikube-setup.sh

# 3. Add to /etc/hosts (use the Minikube IP shown)
echo "$(minikube ip) pindrop.local" | sudo tee -a /etc/hosts

# 4. Build Docker images
./scripts/build-images.sh

# 5. Create secrets from .env
./scripts/create-secrets.sh

# 6. Deploy with Helm
./scripts/helm-deploy.sh

# 7. Access the application
kubectl port-forward svc/pindrop-frontend 8080:80 -n pindrop &
open http://localhost:8080
```

### Testing Different Scenarios

```bash
# Preview what Helm will generate (without deploying)
./scripts/helm-template.sh

# Compare dev vs prod configuration
./scripts/helm-diff.sh

# Deploy with production values (more replicas)
./scripts/helm-deploy.sh prod

# Scale without editing files
helm upgrade pindrop ./k8s/pindrop-chart -n pindrop --set backend.replicas=5

# View deployment history
helm history pindrop -n pindrop

# Rollback to previous version
helm rollback pindrop 1 -n pindrop

# Clean up
helm uninstall pindrop -n pindrop
```

---

## Key DevOps Concepts Demonstrated

### 1. Multi-Stage Docker Builds

```dockerfile
# Stage 1: Build with all dependencies
FROM node:20-alpine AS builder
RUN npm ci
COPY . .

# Stage 2: Production with only runtime dependencies
FROM node:20-alpine AS production
RUN npm ci --omit=dev
CMD ["npm", "start"]
```

**Result:** Smaller, more secure images (210MB vs 500MB+)

### 2. Kubernetes Resource Management

```yaml
# Deployment ensures desired number of pods are running
spec:
  replicas: 3
  template:
    spec:
      containers:
        - name: backend
          resources:
            limits:
              memory: "512Mi"
              cpu: "500m"
```

### 3. Helm Templating

```yaml
# Template (with variables)
replicas: {{ .Values.backend.replicas }}

# values.yaml (dev)
backend:
  replicas: 1

# values-prod.yaml
backend:
  replicas: 3
```

**Result:** Same chart, different environments

### 4. Path-Based Ingress Routing

```yaml
rules:
  - http:
      paths:
        - path: /api
          backend:
            service:
              name: pindrop-backend
        - path: /
          backend:
            service:
              name: pindrop-frontend
```

**Result:** Single entry point, intelligent routing

---

## Inline Documentation

All configuration files include extensive comments explaining:
- What each section does
- Why it's configured that way
- How to modify it

See especially:
- `Dockerfile` - Explains multi-stage build process
- `k8s/pindrop-chart/templates/_helpers.tpl` - Explains Helm templating
- `k8s/pindrop-chart/values.yaml` - Explains all configuration options

---

## Challenges & Solutions

### Challenge 1: Frontend API URL Configuration
**Problem:** Frontend needs different API URLs for different environments.  
**Solution:** Use Docker build arguments (`VITE_API_URL`) to bake the correct URL at build time.

### Challenge 2: macOS Minikube Networking
**Problem:** Minikube IP not accessible on macOS with Docker driver.  
**Solution:** Use `kubectl port-forward` for local testing; Ingress works correctly in cloud environments.

### Challenge 3: Secrets Management
**Problem:** Keep credentials secure while enabling deployment.  
**Solution:** Template file in git, actual secrets created via script from `.env` file.

---

## Useful Commands Reference

```bash
# Minikube
minikube start/stop/status
minikube dashboard              # Visual UI

# Kubernetes
kubectl get pods -n pindrop
kubectl logs -l app.kubernetes.io/component=backend -n pindrop
kubectl describe pod <pod-name> -n pindrop
kubectl port-forward svc/pindrop-frontend 8080:80 -n pindrop

# Helm
helm install pindrop ./k8s/pindrop-chart -n pindrop
helm upgrade pindrop ./k8s/pindrop-chart -n pindrop
helm list -n pindrop
helm history pindrop -n pindrop
helm rollback pindrop 1 -n pindrop
helm uninstall pindrop -n pindrop
```

---

## Author

Mallika Kulkarni  
CIS 1912 - DevOps  
Spring 2026
