"""
Unit Tests - Health Check Endpoints
=====================================
Tests for the /health and /ready endpoints used by Kubernetes probes.
"""

import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.mark.asyncio
async def test_health_check():
    """Test that /health returns 200 with correct status."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "ai-expense-tracker-api"


@pytest.mark.asyncio
async def test_root_endpoint():
    """Test that / returns service info."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "AI Expense Tracker API"
    assert data["version"] == "1.0.0"
    assert "docs" in data


@pytest.mark.asyncio
async def test_metrics_endpoint():
    """Test that /metrics returns Prometheus metrics."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        response = await client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text or "python_info" in response.text
