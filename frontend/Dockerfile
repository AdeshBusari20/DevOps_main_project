# ==============================================
# Frontend Dockerfile - Multi-Stage Build
# ==============================================
# Stage 1: Build the React app with Node.js
# Stage 2: Serve static files with NGINX
# Final image is ~25MB instead of ~1GB
# ==============================================

# ---- Stage 1: Build ----
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files first for layer caching
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm ci --silent

# Copy source code
COPY . .

# Build the production React app
RUN npm run build

# ---- Stage 2: Serve with NGINX ----
FROM nginx:1.27-alpine AS runtime

# Remove default NGINX config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom NGINX config for React SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built React app from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Start NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]
