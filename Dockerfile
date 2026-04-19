# =============================================================================
# PINDROP BACKEND - PRODUCTION DOCKERFILE
# =============================================================================
# This is a multi-stage Dockerfile that creates a minimal, production-ready
# image for the Node.js/Express backend API.
#
# Why multi-stage?
# - Stage 1 (builder): Installs ALL dependencies in a full environment
# - Stage 2 (production): Creates a minimal image with only what's needed to run
# - Result: Smaller image size, fewer security vulnerabilities, faster deploys
#
# Usage:
#   docker build -t pindrop-backend:latest .
#   docker run -p 3001:3001 --env-file .env pindrop-backend:latest
# =============================================================================

# -----------------------------------------------------------------------------
# STAGE 1: Builder
# -----------------------------------------------------------------------------
# Purpose: Install all dependencies (including devDependencies if needed for
# any build steps). We use the full node:20-alpine as our base.
FROM node:20-alpine AS builder

# Set working directory inside the container
WORKDIR /app

# Copy package files first (before source code)
# Why? Docker caches layers. If package.json hasn't changed, npm install
# is skipped on rebuilds, making builds much faster.
COPY package*.json ./

# Install ALL dependencies (including devDependencies)
# Using npm ci instead of npm install because:
# - npm ci is faster (skips some checks)
# - npm ci ensures reproducible builds (uses exact versions from package-lock.json)
# - npm ci fails if package-lock.json is out of sync (catches errors early)
RUN npm ci

# Copy the rest of the application code
# Note: .dockerignore should exclude node_modules, .env, .git, etc.
COPY . .

# -----------------------------------------------------------------------------
# STAGE 2: Production
# -----------------------------------------------------------------------------
# Purpose: Create a minimal image that only contains what's needed to RUN
# the application (not build it).
FROM node:20-alpine AS production

# Set working directory
WORKDIR /app

# Set NODE_ENV to production
# This tells Express to:
# - Disable verbose error messages
# - Enable view template caching
# - Enable other production optimizations
ENV NODE_ENV=production

# Copy package files
COPY package*.json ./

# Install ONLY production dependencies (skip devDependencies)
# The --omit=dev flag excludes devDependencies like nodemon, jest, etc.
# This makes the image smaller and more secure.
RUN npm ci --omit=dev

# Copy application code from builder stage
# We copy from builder to ensure we have the exact same code
COPY --from=builder /app/backend ./backend

# Create a non-root user for security
# Running as root in containers is a security risk - if the container is
# compromised, the attacker has root access. Running as a non-root user
# limits the damage they can do.
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership of the app directory to the non-root user
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Document which port the application uses
# Note: EXPOSE doesn't actually publish the port - it's documentation
# You still need -p 3001:3001 when running the container
EXPOSE 3001

# Health check - allows Docker/Kubernetes to know if the app is healthy
# Kubernetes uses this for readiness/liveness probes
# Docker Compose uses this for depends_on with condition: service_healthy
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

# Start the application
# Using npm start which runs "node backend/server.js" (defined in package.json)
# NOT npm run dev (which uses nodemon for hot-reload - wasteful in production)
CMD ["npm", "start"]