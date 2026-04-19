# Kubernetes Testing Guide - Week 2

This document provides step-by-step instructions for deploying and testing Pindrop on Kubernetes using Minikube.

## Prerequisites

### Install Required Tools

1. **Minikube** - Local Kubernetes cluster
   ```bash
   # macOS with Homebrew
   brew install minikube
   ```

2. **kubectl** - Kubernetes command-line tool
   ```bash
   # macOS with Homebrew
   brew install kubectl
   ```

3. **Docker Desktop** - Container runtime
   - Download from: https://www.docker.com/products/docker-desktop/
   - Make sure it's running before starting Minikube

### Verify Installation
```bash
minikube version
kubectl version --client
docker --version
```

---

## Files Created

```
pindrop/
├── k8s/
│   └── manifests/
│       ├── namespace.yaml           # Kubernetes namespace
│       ├── configmap.yaml           # Non-sensitive configuration
│       ├── secrets.yaml.template    # Template for secrets (DO NOT commit actual secrets)
│       ├── backend-deployment.yaml  # Backend pod specification
│       ├── backend-service.yaml     # Backend network endpoint
│       ├── frontend-deployment.yaml # Frontend pod specification
│       ├── frontend-service.yaml    # Frontend network endpoint
│       └── ingress.yaml             # External access routing
└── scripts/
    ├── minikube-setup.sh            # Initialize Minikube
    ├── build-images.sh              # Build Docker images for Minikube
    ├── create-secrets.sh            # Create K8s secrets from .env
    └── deploy.sh                    # Deploy all manifests
```

---

## Step-by-Step Deployment

### Step 1: Start Minikube

```bash
# Navigate to project directory
cd /Users/mallikakulkarni/CIS1912-DevOps/pindrop

# Run the setup script
./scripts/minikube-setup.sh
```

**What this does:**
- Starts Minikube with 4 CPUs and 4GB RAM
- Enables the nginx Ingress controller
- Displays the Minikube IP address

**Expected output:**
```
✓ Minikube started
✓ Ingress addon enabled
✓ Minikube IP: 192.168.49.2   (your IP may differ)
```

### Step 2: Configure /etc/hosts

Add the Minikube IP to your hosts file so `pindrop.local` resolves to Minikube:

```bash
# Get Minikube IP
minikube ip

# Add to /etc/hosts (replace IP with yours)
echo "$(minikube ip) pindrop.local" | sudo tee -a /etc/hosts
```

**Verify:**
```bash
ping pindrop.local
# Should show responses from Minikube IP
```

### Step 3: Build Docker Images

```bash
./scripts/build-images.sh
```

**What this does:**
- Configures Docker to use Minikube's Docker daemon
- Builds `pindrop-backend:latest` using the production Dockerfile
- Builds `pindrop-frontend:latest` with `VITE_API_URL=/api`

**Expected output:**
```
✓ Backend image built: pindrop-backend:latest
✓ Frontend image built: pindrop-frontend:latest

REPOSITORY          TAG       SIZE
pindrop-backend     latest    ~250MB
pindrop-frontend    latest    ~40MB
```

### Step 4: Create Kubernetes Secrets

```bash
./scripts/create-secrets.sh
```

**What this does:**
- Reads your `.env` file
- Creates a Kubernetes Secret with all required values
- kubectl handles base64 encoding automatically

**Expected output:**
```
✓ All required variables found
✓ Secret 'pindrop-secrets' created
```

**If you get errors about missing variables**, ensure your `.env` file has:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `JWT_SECRET`
- `JWT_REFRESH_SECRET`
- `OPENAI_API_KEY`

### Step 5: Deploy to Kubernetes

```bash
./scripts/deploy.sh
```

**What this does:**
- Applies all Kubernetes manifests in order
- Waits for pods to be ready
- Displays deployment status

**Expected output:**
```
✓ Namespace applied
✓ ConfigMap applied
✓ Secrets exist
✓ Backend deployed
✓ Frontend deployed
✓ Ingress applied

Waiting for pods to be ready...
pod/backend-xxxxx condition met
pod/frontend-xxxxx condition met

Resource Status:
----------------
NAME                            READY   STATUS    RESTARTS   AGE
pod/backend-xxxxx-xxxxx         1/1     Running   0          30s
pod/frontend-xxxxx-xxxxx        1/1     Running   0          30s
```

---

## Testing the Deployment

### Test 1: Check Pod Status

```bash
kubectl get pods -n pindrop
```

**Expected:** All pods show `Running` status with `1/1` ready.

**If pods are not ready:**
```bash
# Check pod details
kubectl describe pod <pod-name> -n pindrop

# Check logs
kubectl logs <pod-name> -n pindrop
```

### Test 2: Check Services

```bash
kubectl get services -n pindrop
```

**Expected:**
```
NAME       TYPE        CLUSTER-IP      PORT(S)
backend    ClusterIP   10.x.x.x        3001/TCP
frontend   ClusterIP   10.x.x.x        80/TCP
```

### Test 3: Check Ingress

```bash
kubectl get ingress -n pindrop
```

**Expected:**
```
NAME              CLASS   HOSTS           ADDRESS        PORTS
pindrop-ingress   nginx   *               192.168.49.2   80
```

### Test 4: Access the Application

#### Option A: Port Forwarding (Recommended for macOS)

On macOS with Docker driver, the Minikube IP isn't directly accessible. Use port-forwarding:

```bash
# Forward frontend to localhost:8080
kubectl port-forward svc/frontend 8080:80 -n pindrop &

# Forward backend to localhost:3001  
kubectl port-forward svc/backend 3001:3001 -n pindrop &

# Open in browser
open http://localhost:8080
```

**Expected:** The Pindrop React application loads at `http://localhost:8080`.

#### Option B: Via Ingress (Linux or cloud environments)

On Linux or in cloud Kubernetes (EKS, GKE), the Ingress works directly:

```
http://pindrop.local
```

**Note:** On macOS with Docker driver, `pindrop.local` won't work due to Docker network isolation. This is a known limitation - the Ingress configuration is correct and would work in production cloud environments.

### Test 5: Test API Routing

```bash
# Test backend health endpoint through Ingress
curl http://pindrop.local/health

# Test API endpoint
curl http://pindrop.local/api

# Direct pod test (bypass Ingress)
kubectl port-forward -n pindrop svc/backend 3001:3001 &
curl http://localhost:3001/health
```

### Test 6: Test Frontend SPA Routing

```bash
# All these should return the React app (HTML)
curl http://pindrop.local/
curl http://pindrop.local/dashboard
curl http://pindrop.local/trips/123
```

---

## Troubleshooting

### Problem: Pods stuck in "Pending"

**Check:** Are there resource issues?
```bash
kubectl describe pod <pod-name> -n pindrop
# Look for "Events" section at the bottom
```

**Common causes:**
- Insufficient cluster resources → Increase Minikube resources
- Image not found → Run `./scripts/build-images.sh`

### Problem: Pods in "CrashLoopBackOff"

**Check:** View pod logs
```bash
kubectl logs <pod-name> -n pindrop
kubectl logs <pod-name> -n pindrop --previous  # Previous crash logs
```

**Common causes:**
- Missing secrets → Run `./scripts/create-secrets.sh`
- Application error → Check logs for specific error

### Problem: Ingress not working (connection refused)

**Check 1:** Is Ingress controller running?
```bash
kubectl get pods -n ingress-nginx
```

**Check 2:** Is Ingress configured correctly?
```bash
kubectl describe ingress pindrop-ingress -n pindrop
```

**Check 3:** Verify /etc/hosts entry
```bash
cat /etc/hosts | grep pindrop
ping pindrop.local
```

### Problem: "ImagePullBackOff" error

**Cause:** Kubernetes is trying to pull image from registry instead of using local.

**Fix:** Ensure `imagePullPolicy: Never` is set in deployments (already configured).

**Verify images are in Minikube:**
```bash
eval $(minikube docker-env)
docker images | grep pindrop
```

### Problem: Frontend can't reach backend API

**Check 1:** Is the frontend built with correct API URL?
```bash
# The frontend should be making requests to /api/*
# Check browser Network tab - API calls should go to /api/...
```

**Check 2:** Is backend responding?
```bash
curl http://pindrop.local/api
curl http://pindrop.local/health
```

**Check 3:** Check Ingress routing
```bash
kubectl describe ingress pindrop-ingress -n pindrop
# Verify /api routes to backend:3001
```

---

## Useful Commands Reference

```bash
# View all resources in pindrop namespace
kubectl get all -n pindrop

# View pod logs (live)
kubectl logs -f -l component=backend -n pindrop

# Execute shell in a pod
kubectl exec -it <pod-name> -n pindrop -- /bin/sh

# Port forward for direct access
kubectl port-forward svc/backend 3001:3001 -n pindrop

# Delete everything and start fresh
kubectl delete namespace pindrop
./scripts/deploy.sh

# Restart deployments (after image rebuild)
kubectl rollout restart deployment/backend -n pindrop
kubectl rollout restart deployment/frontend -n pindrop

# View Minikube dashboard (visual UI)
minikube dashboard
```

---

## Cleanup

```bash
# Delete all pindrop resources
kubectl delete namespace pindrop

# Stop Minikube (preserves state)
minikube stop

# Delete Minikube cluster entirely
minikube delete
```

---

## Next Steps

After verifying the Kubernetes deployment works:

1. **Week 3**: Convert manifests to Helm charts with templating
2. **Week 4**: Documentation, presentation preparation, demo
