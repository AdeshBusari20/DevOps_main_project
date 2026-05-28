#!/bin/bash
# ==============================================
# One-Click Local Setup Script
# ==============================================
# Sets up the entire development environment locally
# Usage: bash scripts/setup.sh
# ==============================================

set -e

echo "=============================================="
echo "  AI Expense Tracker - Local Setup"
echo "=============================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check prerequisites
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed. Please install it first.${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ $1 is installed${NC}"
    fi
}

echo ""
echo "Checking prerequisites..."
check_command docker
check_command git

# Check Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running. Please start Docker.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker is running${NC}"

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    echo -e "${YELLOW}📋 Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ .env created. Edit it with your values.${NC}"
else
    echo -e "${GREEN}✅ .env file exists${NC}"
fi

# Build and start services
echo ""
echo -e "${YELLOW}🔨 Building Docker images...${NC}"
docker compose build

echo ""
echo -e "${YELLOW}🚀 Starting all services...${NC}"
docker compose up -d

# Wait for services
echo ""
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 10

# Health check
echo ""
echo "Checking service health..."

if curl -s http://localhost:8000/health | grep -q "healthy"; then
    echo -e "${GREEN}✅ Backend is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Backend is still starting up...${NC}"
fi

if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend is running${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend is still starting up...${NC}"
fi

echo ""
echo "=============================================="
echo -e "${GREEN}  🎉 Setup Complete!${NC}"
echo "=============================================="
echo ""
echo "  Frontend:  http://localhost:3000"
echo "  Backend:   http://localhost:8000"
echo "  API Docs:  http://localhost:8000/docs"
echo "  NGINX:     http://localhost"
echo ""
echo "  Run 'docker compose logs -f' to view logs"
echo "  Run 'docker compose down' to stop"
echo "=============================================="
