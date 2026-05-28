# ==============================================
# Backend Dockerfile - Multi-Stage Build
# ==============================================
# Stage 1: Install dependencies in a builder stage
# Stage 2: Copy only what's needed to a slim runtime image
# This reduces the final image size significantly
# ==============================================

# ---- Stage 1: Builder ----
FROM python:3.12-slim AS builder

# Set working directory
WORKDIR /app

# Install system dependencies needed for building Python packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy only requirements first (Docker layer caching optimization)
# This layer is cached unless requirements.txt changes
COPY requirements.txt .

# Install Python dependencies into a virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ---- Stage 2: Runtime ----
FROM python:3.12-slim AS runtime

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Install runtime-only system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq5 curl && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv

# Copy application code
COPY . .

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose the application port
EXPOSE 8000

# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the application with Uvicorn
# --host 0.0.0.0: Listen on all interfaces (required in containers)
# --workers 4: Number of worker processes (adjust based on CPU cores)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
