# Troubleshooting Guide

## Common Issues & Fixes

### Docker Issues

**Problem: `docker compose up` fails with port conflict**
```bash
# Check what's using the port
sudo lsof -i :8000
# or on Windows: netstat -ano | findstr :8000

# Kill the process or change the port in docker-compose.yml
```

**Problem: Backend can't connect to PostgreSQL**
```bash
# Check if PostgreSQL is running
docker compose ps postgres

# Check PostgreSQL logs
docker compose logs postgres

# Verify DATABASE_URL in .env matches postgres service name
# It should be: postgresql+asyncpg://user:pass@postgres:5432/db
# NOT localhost — use the Docker service name "postgres"
```

**Problem: Frontend shows blank page**
```bash
# Check frontend logs
docker compose logs frontend

# Verify REACT_APP_API_URL in .env
# For Docker: http://localhost:8000/api/v1
# Rebuild if env changed: docker compose up -d --build frontend
```

**Problem: Docker build fails with "no space left on device"**
```bash
# Clean unused Docker resources
docker system prune -a --volumes
```

### Kubernetes Issues

**Problem: Pods stuck in CrashLoopBackOff**
```bash
# Check pod logs
kubectl logs <pod-name> -n expense-tracker

# Check pod events
kubectl describe pod <pod-name> -n expense-tracker

# Common causes: wrong image name, missing secrets/configmap, DB not ready
```

**Problem: PersistentVolumeClaim stuck in Pending**
```bash
# Check PV exists
kubectl get pv

# Check StorageClass matches
kubectl get pvc -n expense-tracker

# For local dev, ensure hostPath directory exists on the node
```

**Problem: Ingress not routing traffic**
```bash
# Verify Ingress controller is installed
kubectl get pods -n ingress-nginx

# Check Ingress resource
kubectl describe ingress expense-tracker-ingress -n expense-tracker

# Install NGINX Ingress Controller if missing:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
```

### Jenkins Issues

**Problem: Jenkins can't find Docker**
```bash
# Add Jenkins user to Docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

**Problem: Jenkins pipeline fails at "Push to Docker Hub"**
```
# Verify Docker Hub credentials in Jenkins:
# Manage Jenkins → Credentials → dockerhub-credentials
# Use Access Token, not password
```

### Terraform Issues

**Problem: `terraform init` fails**
```bash
# Clear cache and retry
rm -rf .terraform .terraform.lock.hcl
terraform init
```

**Problem: `terraform apply` fails with "InvalidParameterValue"**
```bash
# Verify your AWS region has the specified AMI
# Check your key pair exists in the target region
aws ec2 describe-key-pairs --region ap-south-1
```

### Monitoring Issues

**Problem: Grafana shows "No data"**
```bash
# Check Prometheus is scraping targets
curl http://localhost:9090/api/v1/targets

# Verify backend /metrics endpoint works
curl http://localhost:8000/metrics

# Check Grafana datasource is configured correctly
# Configuration → Data Sources → Prometheus → URL should be http://prometheus:9090
```

**Problem: Prometheus alerts not firing**
```bash
# Check alert rules are loaded
curl http://localhost:9090/api/v1/rules

# Check AlertManager is receiving alerts
curl http://localhost:9093/api/v1/alerts
```

## Useful Debug Commands

```bash
# Docker
docker compose ps                          # Service status
docker compose logs -f <service>           # Stream logs
docker compose exec backend bash           # Shell into container
docker stats                               # Resource usage

# Kubernetes
kubectl get all -n expense-tracker         # All resources
kubectl top pods -n expense-tracker        # Resource usage
kubectl exec -it <pod> -n expense-tracker -- sh  # Shell into pod
kubectl port-forward svc/backend 8000:8000 -n expense-tracker  # Local access

# Terraform
terraform state list                       # List managed resources
terraform show                             # Current state
terraform plan -destroy                    # Preview destruction
```
