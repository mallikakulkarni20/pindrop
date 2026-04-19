# Pindrop DevOps Project - Demo Script

**Presentation Time:** 5-8 minutes  
**Demo Time:** ~3-4 minutes of the presentation

---

## Presentation Outline

### Part 1: Introduction (1 minute)

**Slide content / Talking points:**

> "My project takes an existing full-stack application called Pindrop - a travel planning app with a React frontend and Node.js backend - and transforms it into a production-ready, Kubernetes-deployable application using DevOps best practices."

**What I built:**
- Production Docker images (multi-stage builds)
- Kubernetes manifests for container orchestration
- Helm charts for environment-specific deployments
- Automated deployment scripts

**Technologies used:**
- Docker (containerization)
- Kubernetes (orchestration)
- Helm (package management)
- Minikube (local testing)

**DevOps philosophies applied:**
- Reproducibility (same Helm chart deploys identically anywhere)
- Portability (containerized app runs on any K8s cluster)
- Declarative configuration (desired state in YAML)
- Environment parity (dev/prod use same templates)

---

### Part 2: Architecture Overview (1 minute)

**Show this diagram:**

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              BEFORE                                      │
│                                                                          │
│   Developer Machine                                                      │
│   ├── npm run dev (backend)                                             │
│   ├── npm run dev (frontend)                                            │
│   └── Manual setup, works on my machine...                              │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                              AFTER                                       │
│                                                                          │
│   Kubernetes Cluster (Minikube / EKS / GKE)                             │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                         INGRESS                                  │   │
│   │                    (Traffic Routing)                             │   │
│   │         /api/* → Backend    /* → Frontend                       │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│              │                              │                            │
│              ▼                              ▼                            │
│   ┌──────────────────┐          ┌──────────────────┐                    │
│   │  Backend Pods    │          │  Frontend Pods   │                    │
│   │  (Node.js)       │          │  (nginx)         │                    │
│   │  Replicas: 1-3   │          │  Replicas: 1-2   │                    │
│   └──────────────────┘          └──────────────────┘                    │
│              │                                                           │
│              ▼                                                           │
│        Supabase (Database)                                              │
└─────────────────────────────────────────────────────────────────────────┘
│                                                                          │
│   Deployed with ONE command:                                             │
│   $ helm install pindrop ./k8s/pindrop-chart -f values-prod.yaml        │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### Part 3: Implementation Roadmap (1 minute)

**Week 1: Docker**
- Created multi-stage Dockerfiles (smaller, secure images)
- Backend: 210MB production image
- Frontend: 55MB nginx image

**Week 2: Kubernetes**
- Deployments, Services, ConfigMaps, Secrets, Ingress
- Tested on Minikube

**Week 3: Helm**
- Converted manifests to templates
- Environment-specific values (dev vs prod)
- One-command deployments

**Week 4: Documentation & Demo**

---

### Part 4: Challenges (1 minute)

**Challenge 1: Frontend API URL Configuration**
> "The frontend needs to know where the backend API is. In development it's localhost:3001, but in Kubernetes it's /api through the Ingress. Solution: Build-time configuration with Docker build arguments."

**Challenge 2: macOS Networking with Minikube**
> "On macOS, the Minikube IP isn't directly accessible due to Docker networking. Solution: Use port-forwarding for local testing, which still demonstrates the Kubernetes deployment working correctly."

**Challenge 3: Secrets Management**
> "Keeping API keys and credentials secure while still being able to deploy. Solution: Secrets stored in Kubernetes Secrets, created from .env file via script, never committed to git."

---

### Part 5: Live Demo (3-4 minutes)

**See detailed demo steps below**

---

## Live Demo Script

### Pre-Demo Setup (Do Before Presentation)

Run these commands before your presentation to ensure everything is ready:

```bash
# Navigate to project
cd /Users/mallikakulkarni/CIS1912-DevOps/pindrop

# Make sure Minikube is running
minikube status

# If not running, start it
./scripts/minikube-setup.sh

# Build images (takes 1-2 minutes)
./scripts/build-images.sh

# Create secrets
./scripts/create-secrets.sh

# Clean any existing deployment
helm uninstall pindrop -n pindrop 2>/dev/null || true
kubectl delete namespace pindrop 2>/dev/null || true
```

---

### Demo Step 1: Show the Problem (30 seconds)

**Say:** "Let me show you what we're starting with - a travel planning application with separate frontend and backend."

```bash
# Show project structure
ls -la

# Show the application has frontend and backend
ls frontend/
ls backend/
```

**Say:** "Without DevOps practices, deploying this requires manual setup on each server."

---

### Demo Step 2: Show Docker Images (30 seconds)

**Say:** "First, I containerized both applications using multi-stage Docker builds."

```bash
# Show Dockerfile
head -30 Dockerfile

# Show the images we built
eval $(minikube docker-env)
docker images | grep pindrop
```

**Say:** "Notice the frontend is only 55MB because we use nginx to serve static files, not the full Node.js runtime."

---

### Demo Step 3: Show Helm Chart Structure (30 seconds)

**Say:** "I created a Helm chart that packages all Kubernetes resources together."

```bash
# Show chart structure
ls -la k8s/pindrop-chart/
ls -la k8s/pindrop-chart/templates/
```

**Say:** "The templates folder contains Kubernetes manifests with variables. The values.yaml provides the configuration."

---

### Demo Step 4: Compare Dev vs Prod Values (30 seconds)

**Say:** "One of Helm's key benefits is environment-specific configuration."

```bash
# Show the difference between dev and prod
./scripts/helm-diff.sh
```

**Say:** "Dev uses 1 replica with minimal resources. Production uses 3 backend replicas and higher resource limits. Same templates, different values."

---

### Demo Step 5: Deploy with Helm (1 minute)

**Say:** "Now let's deploy the application to Kubernetes with a single command."

```bash
# Deploy with development values
./scripts/helm-deploy.sh
```

**While it's deploying, explain:**
> "This script validates prerequisites, creates the namespace, sets up secrets from my .env file, and uses Helm to deploy all resources. In a real production environment, this same chart would deploy to AWS EKS or Google GKE."

---

### Demo Step 6: Show Running Application (1 minute)

**Say:** "Let's verify everything is running."

```bash
# Show pods
kubectl get pods -n pindrop

# Show all resources
kubectl get all -n pindrop

# Show the Helm release
helm list -n pindrop
```

**Say:** "We have our backend and frontend pods running, services for networking, and an Ingress configured for routing."

---

### Demo Step 7: Access the Application (30 seconds)

**Say:** "Let's access the running application."

```bash
# Set up port forwarding
kubectl port-forward svc/pindrop-frontend 8080:80 -n pindrop &
kubectl port-forward svc/pindrop-backend 3001:3001 -n pindrop &

# Open in browser
open http://localhost:8080
```

**Show the application loading in the browser.**

**Say:** "The React frontend is being served by nginx inside Kubernetes, and API calls go to the backend pods."

---

### Demo Step 8: Show Helm's Power - Scaling (30 seconds)

**Say:** "Now let me demonstrate Helm's power. I can scale the backend without editing any files."

```bash
# Scale to 3 replicas
helm upgrade pindrop ./k8s/pindrop-chart -n pindrop --set backend.replicas=3

# Watch pods scale up
kubectl get pods -n pindrop -w
```

**Say:** "With one command, Kubernetes creates 2 more backend pods. This is the power of declarative configuration."

Press Ctrl+C to stop watching.

---

### Demo Step 9: Show Rollback Capability (30 seconds)

**Say:** "Helm also tracks deployment history, allowing easy rollbacks."

```bash
# Show history
helm history pindrop -n pindrop

# Rollback to previous version
helm rollback pindrop 1 -n pindrop

# Verify we're back to 1 replica
kubectl get pods -n pindrop
```

**Say:** "In production, if a deployment causes issues, you can rollback in seconds."

---

### Closing (30 seconds)

**Say:** 
> "To summarize: I took an existing application and made it production-ready using Docker for containerization, Kubernetes for orchestration, and Helm for package management. 
>
> The entire deployment is reproducible - anyone can clone this repo and run the same commands to get an identical environment. That's the power of DevOps practices."

---

## Backup Demo Commands

If something goes wrong during the live demo, here are recovery commands:

```bash
# If Minikube isn't running
minikube start

# If images don't exist
./scripts/build-images.sh

# If secrets don't exist
./scripts/create-secrets.sh

# If deployment failed, clean and retry
helm uninstall pindrop -n pindrop
kubectl delete namespace pindrop
./scripts/helm-deploy.sh

# If port-forward isn't working
pkill -f "kubectl port-forward"
kubectl port-forward svc/pindrop-frontend 8080:80 -n pindrop &
```

---

## Quick Reference - Key Points to Mention

### Technologies Used
- **Docker**: Multi-stage builds, production images
- **Kubernetes**: Deployments, Services, ConfigMaps, Secrets, Ingress
- **Helm**: Templating, values files, releases, rollbacks
- **Minikube**: Local Kubernetes cluster

### DevOps Philosophies Demonstrated
- **Reproducibility**: Same chart = same deployment
- **Portability**: Containers run anywhere
- **Declarative**: Describe desired state, K8s maintains it
- **Environment Parity**: Dev/prod same templates, different values
- **Infrastructure as Code**: All configuration in version control

### Key Files to Reference
- `Dockerfile` - Multi-stage backend build
- `frontend/Dockerfile` - Multi-stage frontend build with nginx
- `k8s/pindrop-chart/values.yaml` - Dev configuration
- `k8s/pindrop-chart/values-prod.yaml` - Prod configuration
- `k8s/pindrop-chart/templates/` - Helm templates

---

## Presentation Checklist

Before presentation:
- [ ] Minikube running (`minikube status`)
- [ ] Images built (`docker images | grep pindrop`)
- [ ] Secrets created
- [ ] No existing deployment (clean slate for demo)
- [ ] Terminal font size increased for visibility
- [ ] Browser ready with localhost:8080 tab

During presentation:
- [ ] Speak slowly during demo commands
- [ ] Explain what each command does before running
- [ ] If error occurs, acknowledge and use backup commands
- [ ] Show the application actually loading in browser
