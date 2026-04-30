# Pindrop: DevOps Final Project, Spring 2026
### Anjana Begur and Mallika Kulkarni


Pindrop is a full-stack travel planning app that was one of our senior design projects that we packaged and deployed using a complete DevOps workflow. The app includes a React frontend, a Node/Express backend, and PostgreSQL/Supabase for data.

For this project, we focused on making deployment reproducible and environment-aware:
- Docker multi-stage images for frontend and backend
- Kubernetes manifests for app orchestration
- Helm chart for templated deployments (dev/prod values)
- Scripts for repeatable setup, build, and deploy

## What we Accomplished

### 1) Containerized the application
- Added production-ready multi-stage Dockerfiles:
  - `Dockerfile` for backend
  - `frontend/Dockerfile` for frontend with nginx
- Added local compose files for development and production-style local testing.

### 2) Deployed with Kubernetes
- Created core resources in `k8s/manifests/`:
  - Deployments + Services (frontend/backend)
  - ConfigMap for non-secret config
  - Secret template and secret creation flow
  - Ingress for route split (`/api` -> backend, `/` -> frontend)
- Added health probes and resource requests/limits.

### 3) Converted to Helm
- Built chart at `k8s/pindrop-chart/` with reusable templates.
- Added:
  - `values.yaml` for default/dev settings
  - `values-prod.yaml` for production overrides
- Added helper scripts for templating, diffing values, and deployment.

## Relevant Code / Documentation Notes


important files to review:
- `Dockerfile`: backend multi-stage image and non-root runtime user
- `frontend/Dockerfile`: static frontend build + nginx runtime image
- `frontend/nginx.conf`: SPA fallback and API proxy behavior
- `k8s/manifests/ingress.yaml`: routing rules for backend/frontend
- `k8s/pindrop-chart/templates/_helpers.tpl`: shared Helm naming/label helpers
- `k8s/pindrop-chart/values.yaml` and `k8s/pindrop-chart/values-prod.yaml`: environment config differences
- `scripts/helm-deploy.sh`: one-command deploy flow for Minikube

## How To Test / View The Project

## Prerequisites
- Minikube
- kubectl
- Helm
- Docker Desktop running

Install on macOS:

```bash
brew install minikube kubectl helm
```

## Quick Start (Recommended)

From project root:

```bash
./scripts/minikube-setup.sh
./scripts/build-images.sh
./scripts/create-secrets.sh
./scripts/helm-deploy.sh
```

Then access locally (macOS-friendly):

```bash
kubectl port-forward svc/pindrop-frontend 8080:80 -n pindrop
```

Open `http://localhost:8080`.

If you want backend direct access too:

```bash
kubectl port-forward svc/pindrop-backend 3001:3001 -n pindrop
curl http://localhost:3001/health
```

## Verification Commands

```bash
helm list -n pindrop
kubectl get pods -n pindrop
kubectl get svc -n pindrop
kubectl get ingress -n pindrop
```

Expected: frontend/backend pods running, services present, ingress created.

## Helm-Specific Checks

Preview generated YAML without deploying:

```bash
./scripts/helm-template.sh
./scripts/helm-template.sh prod
```

Compare dev vs prod values:

```bash
./scripts/helm-diff.sh
```

Deploy with production overrides:

```bash
./scripts/helm-deploy.sh prod
```

Show release history / rollback:

```bash
helm history pindrop -n pindrop
helm rollback pindrop 1 -n pindrop
```

## Presentation/Demo Flow

1. Check chart values difference: `./scripts/helm-diff.sh`
2. Deploy: `./scripts/helm-deploy.sh`
3. Verify resources: `kubectl get all -n pindrop`
4. Port-forward and open app
5. Check Helm history / rollback quickly

## Cleanup

```bash
helm uninstall pindrop -n pindrop
kubectl delete namespace pindrop
minikube stop
```
