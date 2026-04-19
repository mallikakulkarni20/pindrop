# =============================================================================
# PINDROP FRONTEND - PRODUCTION DOCKERFILE
# =============================================================================
# This is a multi-stage Dockerfile that:
# 1. Builds the React/Vite application into static files (HTML, JS, CSS)
# 2. Serves those static files using nginx (a fast, lightweight web server)
#
# Why multi-stage?
# - Stage 1 (builder): Has Node.js, npm, all build tools (~1GB+)
# - Stage 2 (production): Has only nginx + static files (~30MB)
# - Result: 97% smaller image, faster deploys, fewer vulnerabilities
#
# Why nginx instead of serving with Node.js?
# - nginx is optimized for serving static files (much faster)
# - nginx uses less memory than a Node.js process
# - nginx handles concurrent connections more efficiently
# - Industry standard for production SPAs
#
# Usage:
#   # For Kubernetes (API at /api path):
#   docker build -t pindrop-frontend:latest --build-arg VITE_API_URL=/api .
#
#   # For local development (API at localhost:3001):
#   docker build -t pindrop-frontend:local --build-arg VITE_API_URL=http://localhost:3001 .
#
#   docker run -p 8080:80 pindrop-frontend:latest
# =============================================================================

# -----------------------------------------------------------------------------
# STAGE 1: Builder
# -----------------------------------------------------------------------------
# Purpose: Install dependencies and build the React application
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files first for better layer caching
# If package.json hasn't changed, Docker reuses the cached npm install layer
COPY package*.json ./

# Install all dependencies (including devDependencies needed for build)
# Vite, TypeScript, ESLint, etc. are devDependencies but required for building
RUN npm ci

# Copy the rest of the frontend source code
COPY . .

# -----------------------------------------------------------------------------
# Build Arguments
# -----------------------------------------------------------------------------
# ARG defines build-time variables that can be passed with --build-arg
# These are NOT available at runtime (unlike ENV)
#
# VITE_API_URL: Where the frontend should send API requests
# - For Kubernetes with Ingress: /api (relative path, Ingress routes to backend)
# - For local Docker testing: http://localhost:3001 (direct to backend container)
# - For Docker Compose: http://backend:3001 (using Docker network DNS)
#
# IMPORTANT: Vite embeds these values INTO the JavaScript bundle at build time.
# Changing the API URL requires rebuilding the image!
ARG VITE_API_URL=/api
ARG VITE_GOOGLE_MAPS_API_KEY=""

# Convert build arguments to environment variables
# Vite reads import.meta.env.VITE_* from environment during build
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_GOOGLE_MAPS_API_KEY=$VITE_GOOGLE_MAPS_API_KEY

# Build the application
# This runs "vite build" which:
# 1. Compiles TypeScript to JavaScript
# 2. Bundles all JS/CSS into optimized chunks
# 3. Outputs static files to /app/dist
RUN npm run build

# -----------------------------------------------------------------------------
# STAGE 2: Production (nginx)
# -----------------------------------------------------------------------------
# Purpose: Serve the static files with nginx
# nginx:alpine is ~30MB and highly optimized for serving static content
FROM nginx:1.25-alpine AS production

# Copy our custom nginx configuration
# This handles SPA routing (see nginx.conf for details)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the built static files from the builder stage
# /app/dist contains: index.html, assets/js/*.js, assets/css/*.css, etc.
COPY --from=builder /app/dist /usr/share/nginx/html

# nginx runs on port 80 by default
# We document this but don't need to change it
EXPOSE 80

# Health check for nginx
# Kubernetes/Docker can use this to verify the container is serving traffic
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Start nginx in the foreground (not as a daemon)
# The -g 'daemon off;' flag keeps nginx in the foreground so Docker can
# track the process. Without this, nginx would daemonize and Docker would
# think the container exited.
CMD ["nginx", "-g", "daemon off;"]
