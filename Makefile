# ==============================================
# AI Expense Tracker - Makefile
# ==============================================
# Convenience commands for development & deployment
# Usage: make <target>
# ==============================================

.PHONY: help build up down logs test lint clean deploy

# ---- Variables ----
DOCKER_COMPOSE = docker compose
DOCKER_COMPOSE_PROD = docker compose -f docker-compose.prod.yml
KUBECTL = kubectl
NAMESPACE = expense-tracker

# ---- Default ----
help: ## Show this help message
	@echo "========================================"
	@echo " AI Expense Tracker - Available Commands"
	@echo "========================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ---- Development ----
build: ## Build all Docker images
	$(DOCKER_COMPOSE) build

up: ## Start all services in development mode
	$(DOCKER_COMPOSE) up -d

down: ## Stop all services
	$(DOCKER_COMPOSE) down

restart: ## Restart all services
	$(DOCKER_COMPOSE) restart

logs: ## View logs from all services
	$(DOCKER_COMPOSE) logs -f

logs-backend: ## View backend logs
	$(DOCKER_COMPOSE) logs -f backend

logs-frontend: ## View frontend logs
	$(DOCKER_COMPOSE) logs -f frontend

# ---- Testing ----
test: ## Run backend tests
	cd backend && python -m pytest tests/ -v

test-coverage: ## Run tests with coverage report
	cd backend && python -m pytest tests/ -v --cov=app --cov-report=html

lint: ## Run linting on backend code
	cd backend && python -m flake8 app/ --max-line-length=120
	cd backend && python -m mypy app/

# ---- Docker ----
docker-build-frontend: ## Build frontend Docker image
	docker build -t adeshbusari20/expense-tracker-frontend:latest ./frontend

docker-build-backend: ## Build backend Docker image
	docker build -t adeshbusari20/expense-tracker-backend:latest ./backend

docker-push: ## Push images to Docker Hub
	docker push adeshbusari20/expense-tracker-frontend:latest
	docker push adeshbusari20/expense-tracker-backend:latest

# ---- Production ----
prod-up: ## Start production stack
	$(DOCKER_COMPOSE_PROD) up -d

prod-down: ## Stop production stack
	$(DOCKER_COMPOSE_PROD) down

# ---- Kubernetes ----
k8s-deploy: ## Deploy to Kubernetes
	$(KUBECTL) apply -f kubernetes/namespace.yaml
	$(KUBECTL) apply -f kubernetes/configmap.yaml
	$(KUBECTL) apply -f kubernetes/secrets.yaml
	$(KUBECTL) apply -f kubernetes/pv.yaml
	$(KUBECTL) apply -f kubernetes/pvc.yaml
	$(KUBECTL) apply -f kubernetes/postgres-statefulset.yaml
	$(KUBECTL) apply -f kubernetes/backend-deployment.yaml
	$(KUBECTL) apply -f kubernetes/frontend-deployment.yaml
	$(KUBECTL) apply -f kubernetes/ingress.yaml
	$(KUBECTL) apply -f kubernetes/hpa.yaml

k8s-delete: ## Delete Kubernetes deployment
	$(KUBECTL) delete namespace $(NAMESPACE) --ignore-not-found

k8s-status: ## Check Kubernetes deployment status
	$(KUBECTL) get all -n $(NAMESPACE)

k8s-logs-backend: ## View backend pod logs
	$(KUBECTL) logs -f deployment/backend -n $(NAMESPACE)

# ---- Monitoring ----
monitoring-up: ## Start monitoring stack
	$(DOCKER_COMPOSE) -f monitoring/docker-compose.monitoring.yml up -d

monitoring-down: ## Stop monitoring stack
	$(DOCKER_COMPOSE) -f monitoring/docker-compose.monitoring.yml down

# ---- Terraform ----
tf-init: ## Initialize Terraform
	cd terraform && terraform init

tf-plan: ## Plan Terraform changes
	cd terraform && terraform plan

tf-apply: ## Apply Terraform infrastructure
	cd terraform && terraform apply -auto-approve

tf-destroy: ## Destroy Terraform infrastructure
	cd terraform && terraform destroy -auto-approve

# ---- Database ----
db-backup: ## Backup PostgreSQL database
	bash scripts/backup-db.sh

db-migrate: ## Run database migrations
	cd backend && alembic upgrade head

# ---- Cleanup ----
clean: ## Remove all containers, images, and volumes
	$(DOCKER_COMPOSE) down -v --rmi all
	docker system prune -f

# ---- Health Check ----
health: ## Check application health
	bash scripts/health-check.sh
