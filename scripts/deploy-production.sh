#!/bin/bash
# ==============================================
# Production Deployment Script
# ==============================================
# Single-command deployment for EC2 + Docker Compose
# Deploys the entire AI Expense Tracker stack:
#   - PostgreSQL, Backend, Frontend, Nginx
#   - Prometheus, Grafana, AlertManager
#
# Usage: sudo bash scripts/deploy-production.sh
# ==============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

APP_DIR="/opt/expense-tracker"
REPO_URL="https://github.com/AdeshBusari20/DevOps_main_project.git"
COMPOSE_FILE="docker-compose.prod.single.yml"

echo ""
echo -e "${CYAN}${BOLD}=============================================="
echo "  🚀 AI Expense Tracker - Production Deploy"
echo "==============================================${NC}"
echo ""

# ---- Step 1: Check prerequisites ----
echo -e "${YELLOW}[1/8] Checking prerequisites...${NC}"

check_cmd() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}✅ $1${NC}"
}

check_cmd docker
check_cmd git

# Verify Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running. Start Docker first.${NC}"
    exit 1
fi
echo -e "  ${GREEN}✅ Docker daemon running${NC}"

# ---- Step 2: Clone or update repository ----
echo ""
echo -e "${YELLOW}[2/8] Setting up application directory...${NC}"

if [ -d "$APP_DIR/.git" ]; then
    echo -e "  ${GREEN}Repository exists. Pulling latest changes...${NC}"
    cd "$APP_DIR"
    git pull origin main
else
    echo -e "  ${YELLOW}Cloning repository...${NC}"
    mkdir -p "$APP_DIR"
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
fi

echo -e "  ${GREEN}✅ Repository ready at ${APP_DIR}${NC}"

# ---- Step 3: Create production .env ----
echo ""
echo -e "${YELLOW}[3/8] Configuring environment...${NC}"

if [ ! -f "$APP_DIR/.env" ]; then
    # Detect public IP
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com || curl -s http://ifconfig.me || echo "localhost")
    NIP_DOMAIN="${PUBLIC_IP//./-}.nip.io"

    # Generate strong random password
    DB_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 32)
    SECRET_KEY=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | head -c 64)
    GRAFANA_PASS=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 20)

    cat > "$APP_DIR/.env" << ENVEOF
# ==============================================
# Production Environment - Auto-Generated
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Server: ${PUBLIC_IP}
# ==============================================

# ---- Application ----
APP_NAME=ai-expense-tracker
APP_ENV=production
DEBUG=false

# ---- Backend ----
BACKEND_PORT=8000
SECRET_KEY=${SECRET_KEY}
ALGORITHM=HS256

# ---- Database ----
POSTGRES_USER=expense_user
POSTGRES_PASSWORD=${DB_PASSWORD}
POSTGRES_DB=expense_tracker
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
DATABASE_URL=postgresql+asyncpg://expense_user:${DB_PASSWORD}@postgres:5432/expense_tracker

# ---- Frontend ----
REACT_APP_API_URL=http://${PUBLIC_IP}/api/v1
FRONTEND_PORT=3000

# ---- Docker Hub ----
DOCKERHUB_USERNAME=adeshbusari20

# ---- Monitoring ----
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=${GRAFANA_PASS}
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001

# ---- Server ----
PUBLIC_IP=${PUBLIC_IP}
DOMAIN=${NIP_DOMAIN}
ENVEOF

    chmod 600 "$APP_DIR/.env"
    echo -e "  ${GREEN}✅ Production .env created with secure random passwords${NC}"
    echo -e "  ${CYAN}  Grafana password: ${GRAFANA_PASS}${NC}"
    echo -e "  ${CYAN}  DB password: [hidden - see .env file]${NC}"
else
    echo -e "  ${GREEN}✅ .env file already exists${NC}"
fi

# ---- Step 4: Pull Docker images ----
echo ""
echo -e "${YELLOW}[4/8] Pulling Docker images...${NC}"

docker pull adeshbusari20/expense-tracker-backend:latest
docker pull adeshbusari20/expense-tracker-frontend:latest
docker pull postgres:16-alpine
docker pull nginx:1.27-alpine
docker pull prom/prometheus:v2.53.0
docker pull grafana/grafana:11.0.0
docker pull prom/node-exporter:v1.8.1
docker pull prom/alertmanager:v0.27.0
docker pull gcr.io/cadvisor/cadvisor:v0.49.1

echo -e "  ${GREEN}✅ All Docker images pulled${NC}"

# ---- Step 5: Create required directories ----
echo ""
echo -e "${YELLOW}[5/8] Creating directories...${NC}"

mkdir -p "$APP_DIR/nginx/ssl"
mkdir -p "$APP_DIR/nginx/conf.d"
mkdir -p "$APP_DIR/backups"

echo -e "  ${GREEN}✅ Directories created${NC}"

# ---- Step 6: Deploy the stack ----
echo ""
echo -e "${YELLOW}[6/8] Deploying application stack...${NC}"

cd "$APP_DIR"

# Use the all-in-one compose file
docker compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true
docker compose -f "$COMPOSE_FILE" up -d

echo -e "  ${GREEN}✅ Stack deployed${NC}"

# ---- Step 7: Wait for services ----
echo ""
echo -e "${YELLOW}[7/8] Waiting for services to be healthy...${NC}"

# Wait for PostgreSQL
echo -n "  PostgreSQL: "
for i in $(seq 1 30); do
    if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U expense_user > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Ready${NC}"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo -e "${RED}❌ Timeout${NC}"
    fi
    sleep 2
done

# Wait for Backend
echo -n "  Backend:    "
for i in $(seq 1 30); do
    if curl -sf http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Healthy${NC}"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo -e "${YELLOW}⚠️  Still starting (check logs)${NC}"
    fi
    sleep 3
done

# Wait for Frontend
echo -n "  Frontend:   "
for i in $(seq 1 15); do
    if curl -sf http://localhost:3000 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Running${NC}"
        break
    fi
    if [ "$i" -eq 15 ]; then
        echo -e "${YELLOW}⚠️  Still starting${NC}"
    fi
    sleep 2
done

# Wait for Nginx
echo -n "  Nginx:      "
for i in $(seq 1 10); do
    if curl -sf http://localhost > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Running${NC}"
        break
    fi
    if [ "$i" -eq 10 ]; then
        echo -e "${YELLOW}⚠️  Still starting${NC}"
    fi
    sleep 2
done

# Wait for Grafana
echo -n "  Grafana:    "
for i in $(seq 1 20); do
    if curl -sf http://localhost:3001/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Running${NC}"
        break
    fi
    if [ "$i" -eq 20 ]; then
        echo -e "${YELLOW}⚠️  Still starting${NC}"
    fi
    sleep 3
done

# Wait for Prometheus
echo -n "  Prometheus: "
for i in $(seq 1 15); do
    if curl -sf http://localhost:9090/-/ready > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Running${NC}"
        break
    fi
    if [ "$i" -eq 15 ]; then
        echo -e "${YELLOW}⚠️  Still starting${NC}"
    fi
    sleep 2
done

# ---- Step 8: Display results ----
echo ""
echo -e "${CYAN}${BOLD}=============================================="
echo "  🎉 Deployment Complete!"
echo "==============================================${NC}"
echo ""

# Get public IP
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com || echo "YOUR_SERVER_IP")
NIP_DOMAIN="${PUBLIC_IP//./-}.nip.io"

echo -e "  ${BOLD}Application URLs:${NC}"
echo -e "  ─────────────────────────────────────────"
echo -e "  Frontend:     ${GREEN}http://${PUBLIC_IP}${NC}"
echo -e "  API Docs:     ${GREEN}http://${PUBLIC_IP}/docs${NC}"
echo -e "  Health Check: ${GREEN}http://${PUBLIC_IP}/health${NC}"
echo -e ""
echo -e "  ${BOLD}nip.io URLs (shareable):${NC}"
echo -e "  ─────────────────────────────────────────"
echo -e "  Frontend:     ${GREEN}http://${NIP_DOMAIN}${NC}"
echo -e "  API Docs:     ${GREEN}http://${NIP_DOMAIN}/docs${NC}"
echo -e ""
echo -e "  ${BOLD}Monitoring URLs:${NC}"
echo -e "  ─────────────────────────────────────────"
echo -e "  Grafana:      ${GREEN}http://${PUBLIC_IP}:3001${NC}"
echo -e "  Prometheus:   ${GREEN}http://${PUBLIC_IP}:9090${NC}"
echo -e "  AlertManager: ${GREEN}http://${PUBLIC_IP}:9093${NC}"
echo -e ""
echo -e "  ${BOLD}Credentials:${NC}"
echo -e "  ─────────────────────────────────────────"
echo -e "  Grafana:      admin / $(grep GRAFANA_ADMIN_PASSWORD .env | cut -d= -f2)"
echo -e ""
echo -e "  ${BOLD}Next Steps:${NC}"
echo -e "  ─────────────────────────────────────────"
echo -e "  1. Set up SSL: ${CYAN}sudo bash scripts/setup-ssl.sh${NC}"
echo -e "  2. View logs:  ${CYAN}docker compose -f ${COMPOSE_FILE} logs -f${NC}"
echo -e "  3. Backup DB:  ${CYAN}bash scripts/backup-db.sh${NC}"
echo -e ""
echo -e "${CYAN}==============================================${NC}"
