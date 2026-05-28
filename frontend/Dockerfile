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

# Copy only package.json (no lockfile to avoid desync issues)
COPY package.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build the production React app
# CI=false  → prevents warnings from failing the build
# DISABLE_ESLINT_PLUGIN=true → skips broken eslint-plugin-react-hooks v7
ENV CI=false
ENV DISABLE_ESLINT_PLUGIN=true
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
