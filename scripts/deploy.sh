#!/bin/bash
# ==============================================
# Deployment Script
# ==============================================
# Builds, pushes, and deploys to Kubernetes
# Usage: bash scripts/deploy.sh [tag]
# ==============================================

set -e

IMAGE_TAG=${1:-latest}
DOCKERHUB_USERNAME="adeshbusari20"
NAMESPACE="expense-tracker"

echo "=============================================="
echo "  Deploying AI Expense Tracker v${IMAGE_TAG}"
echo "=============================================="

# Build images
echo "🔨 Building Docker images..."
docker build -t ${DOCKERHUB_USERNAME}/expense-tracker-frontend:${IMAGE_TAG} ./frontend
docker build -t ${DOCKERHUB_USERNAME}/expense-tracker-backend:${IMAGE_TAG} ./backend

# Tag as latest
docker tag ${DOCKERHUB_USERNAME}/expense-tracker-frontend:${IMAGE_TAG} ${DOCKERHUB_USERNAME}/expense-tracker-frontend:latest
docker tag ${DOCKERHUB_USERNAME}/expense-tracker-backend:${IMAGE_TAG} ${DOCKERHUB_USERNAME}/expense-tracker-backend:latest

# Push to Docker Hub
echo "📤 Pushing to Docker Hub..."
docker push ${DOCKERHUB_USERNAME}/expense-tracker-frontend:${IMAGE_TAG}
docker push ${DOCKERHUB_USERNAME}/expense-tracker-frontend:latest
docker push ${DOCKERHUB_USERNAME}/expense-tracker-backend:${IMAGE_TAG}
docker push ${DOCKERHUB_USERNAME}/expense-tracker-backend:latest

# Deploy to Kubernetes
echo "☸️  Deploying to Kubernetes..."
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/pv.yaml
kubectl apply -f kubernetes/pvc.yaml
kubectl apply -f kubernetes/postgres-statefulset.yaml
kubectl apply -f kubernetes/backend-deployment.yaml
kubectl apply -f kubernetes/frontend-deployment.yaml
kubectl apply -f kubernetes/ingress.yaml
kubectl apply -f kubernetes/hpa.yaml

# Wait for rollout
echo "⏳ Waiting for rollout..."
kubectl rollout status deployment/backend -n ${NAMESPACE} --timeout=120s
kubectl rollout status deployment/frontend -n ${NAMESPACE} --timeout=120s

# Show status
echo ""
echo "=============================================="
echo "  ✅ Deployment Complete!"
echo "=============================================="
kubectl get all -n ${NAMESPACE}
