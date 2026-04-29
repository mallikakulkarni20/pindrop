# Frontend production image
# Build with Node, serve with nginx

# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy lock/package first for better cache hits
COPY package*.json ./

# Build tools are in devDependencies, so install all
RUN npm ci

COPY . .

# Build-time args used by Vite
ARG VITE_API_URL=/api
ARG VITE_GOOGLE_MAPS_API_KEY=""

ENV VITE_API_URL=$VITE_API_URL
ENV VITE_GOOGLE_MAPS_API_KEY=$VITE_GOOGLE_MAPS_API_KEY

# Generates static files in /app/dist
RUN npm run build

# Runtime stage
FROM nginx:1.25-alpine AS production

# SPA-friendly nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

# Quick health check for nginx
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Keep nginx in foreground for Docker
CMD ["nginx", "-g", "daemon off;"]
