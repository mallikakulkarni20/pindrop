# Backend production image
# Multi-stage build keeps runtime image small

# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy deps first so Docker layer cache works better
COPY package*.json ./

# Install all deps for build/runtime parity
RUN npm ci

# Copy app source
COPY . .

# Runtime stage
FROM node:20-alpine AS production

WORKDIR /app

ENV NODE_ENV=production

COPY package*.json ./

# Only production deps in final image
RUN npm ci --omit=dev

# Bring backend code from builder
COPY --from=builder /app/backend ./backend

# Run as non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

RUN chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3001

# Basic health endpoint check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

CMD ["npm", "start"]
