"""
AI Expense Tracker - FastAPI Application Entry Point
=====================================================
This is the main FastAPI application file that:
- Configures CORS for frontend communication
- Mounts API routers for expenses and categories
- Provides health check endpoints for Kubernetes probes
- Exposes Prometheus metrics for monitoring
"""

import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from prometheus_client import (
    Counter,
    Histogram,
    generate_latest,
    CONTENT_TYPE_LATEST,
)
from starlette.responses import Response

from app.database import engine, Base
from app.routers import expenses, categories

# ========================
# Prometheus Metrics
# ========================
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status_code"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"],
)


# ========================
# Application Lifespan
# ========================
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Create database tables on startup."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


# ========================
# FastAPI App Instance
# ========================
app = FastAPI(
    title="AI Expense Tracker API",
    description=(
        "A production-grade expense tracking API with AI-powered categorization. "
        "Built with FastAPI, PostgreSQL, and a complete DevOps pipeline."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# ========================
# CORS Middleware
# ========================
# Allow the React frontend to communicate with the backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",      # Local React dev server
        "http://frontend:3000",       # Docker service name
        "http://localhost",           # NGINX reverse proxy
        "*",                          # Allow all in dev (restrict in prod)
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ========================
# Prometheus Middleware
# ========================
@app.middleware("http")
async def prometheus_middleware(request: Request, call_next):
    """Track request count and latency for Prometheus."""
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time

    # Skip metrics endpoint to avoid recursion
    if request.url.path != "/metrics":
        REQUEST_COUNT.labels(
            method=request.method,
            endpoint=request.url.path,
            status_code=response.status_code,
        ).inc()
        REQUEST_LATENCY.labels(
            method=request.method,
            endpoint=request.url.path,
        ).observe(duration)

    return response


# ========================
# Include Routers
# ========================
app.include_router(
    expenses.router,
    prefix="/api/v1/expenses",
    tags=["Expenses"],
)
app.include_router(
    categories.router,
    prefix="/api/v1/categories",
    tags=["Categories"],
)


# ========================
# Health Check Endpoints
# ========================
@app.get("/health", tags=["Health"])
async def health_check():
    """
    Health check endpoint for Kubernetes liveness probe.
    Returns 200 OK if the application is running.
    """
    return {"status": "healthy", "service": "ai-expense-tracker-api"}


@app.get("/ready", tags=["Health"])
async def readiness_check():
    """
    Readiness check endpoint for Kubernetes readiness probe.
    Verifies database connectivity before accepting traffic.
    """
    try:
        async with engine.begin() as conn:
            await conn.execute(
                Base.metadata.tables.get("expenses", Base.metadata).select().limit(1)
                if "expenses" in Base.metadata.tables
                else conn.run_sync(lambda _: None)
            )
        return {"status": "ready", "database": "connected"}
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={"status": "not ready", "database": str(e)},
        )


# ========================
# Prometheus Metrics Endpoint
# ========================
@app.get("/metrics", tags=["Monitoring"])
async def metrics():
    """Expose Prometheus metrics for scraping."""
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST,
    )


# ========================
# Root Endpoint
# ========================
@app.get("/", tags=["Root"])
async def root():
    """API root - returns basic service info."""
    return {
        "service": "AI Expense Tracker API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
        "metrics": "/metrics",
    }
