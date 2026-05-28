#!/bin/bash
# ==============================================
# Health Check Script
# ==============================================
# Checks all services are running and healthy
# Usage: bash scripts/health-check.sh
# ==============================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=============================================="
echo "  AI Expense Tracker - Health Check"
echo "=============================================="
echo ""

ERRORS=0

# Check backend
echo -n "Backend API:     "
if curl -sf http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Healthy${NC}"
else
    echo -e "${RED}❌ Down${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check frontend
echo -n "Frontend:        "
if curl -sf http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Running${NC}"
else
    echo -e "${RED}❌ Down${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check NGINX
echo -n "NGINX Proxy:     "
if curl -sf http://localhost > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Running${NC}"
else
    echo -e "${YELLOW}⚠️  Not running (optional)${NC}"
fi

# Check PostgreSQL
echo -n "PostgreSQL:      "
if docker exec expense-postgres pg_isready -U expense_user > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Ready${NC}"
else
    echo -e "${RED}❌ Not ready${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check Prometheus
echo -n "Prometheus:      "
if curl -sf http://localhost:9090/-/ready > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Running${NC}"
else
    echo -e "${YELLOW}⚠️  Not running (optional)${NC}"
fi

# Check Grafana
echo -n "Grafana:         "
if curl -sf http://localhost:3001/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Running${NC}"
else
    echo -e "${YELLOW}⚠️  Not running (optional)${NC}"
fi

# Check metrics endpoint
echo -n "Metrics:         "
if curl -sf http://localhost:8000/metrics > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Exposing metrics${NC}"
else
    echo -e "${YELLOW}⚠️  Not available${NC}"
fi

echo ""
echo "=============================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}  All core services are healthy! ✅${NC}"
else
    echo -e "${RED}  $ERRORS core service(s) are down! ❌${NC}"
fi
echo "=============================================="

exit $ERRORS
