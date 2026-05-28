# Deployment Guide

## Prerequisites

- Docker & Docker Compose installed
- AWS CLI configured (`aws configure`)
- Terraform >= 1.5.0
- Ansible >= 2.15
- kubectl installed
- Docker Hub account

## Local Development

```bash
# 1. Clone the repository
git clone https://github.com/adeshbusari20/AI-Expense-Tracker-DevOps.git
cd AI-Expense-Tracker-DevOps

# 2. Create environment file
cp .env.example .env
# Edit .env with your values

# 3. Start all services
docker compose up -d

# 4. Verify
curl http://localhost:8000/health
open http://localhost:3000
```

## AWS Deployment

### Step 1: Provision Infrastructure with Terraform

```bash
cd terraform

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply infrastructure
terraform apply

# Note the output IPs
terraform output
```

### Step 2: Configure Servers with Ansible

```bash
cd ansible

# Update inventory with Terraform output IPs
vim inventory/hosts.ini

# Install Docker on all servers
ansible-playbook -i inventory/hosts.ini playbooks/setup-docker.yml

# Install Jenkins on CI server
ansible-playbook -i inventory/hosts.ini playbooks/setup-jenkins.yml

# Install Kubernetes on app server
ansible-playbook -i inventory/hosts.ini playbooks/setup-kubernetes.yml

# Setup monitoring
ansible-playbook -i inventory/hosts.ini playbooks/setup-monitoring.yml
```

### Step 3: Configure Jenkins

1. Access Jenkins at `http://<jenkins-ip>:8080`
2. Get initial password: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
3. Install suggested plugins
4. Create admin user
5. Add credentials:
   - Docker Hub: `dockerhub-credentials` (username + access token)
   - Kubeconfig: `kubeconfig` (file or secret text)
   - SonarQube: `sonarqube-token`
6. Configure GitHub webhook: `http://<jenkins-ip>:8080/github-webhook/`
7. Create pipeline job pointing to `Jenkinsfile`

### Step 4: Deploy Application

```bash
# Option A: Via Jenkins (automatic on git push)
git push origin main

# Option B: Manual deployment
bash scripts/deploy.sh v1.0.0

# Option C: Direct Kubernetes deployment
make k8s-deploy
```

### Step 5: Verify Deployment

```bash
# Check pods
kubectl get pods -n expense-tracker

# Check services
kubectl get svc -n expense-tracker

# Run health check
bash scripts/health-check.sh
```

## HTTPS Setup (Optional)

```bash
# Install certbot
sudo apt install certbot

# Get SSL certificate (replace with your domain)
sudo certbot certonly --standalone -d your-domain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem nginx/ssl/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem nginx/ssl/

# Uncomment HTTPS block in nginx/conf.d/default.conf
# Restart NGINX
docker compose restart nginx
```

## Rollback

```bash
# Kubernetes rollback to previous version
kubectl rollout undo deployment/backend -n expense-tracker
kubectl rollout undo deployment/frontend -n expense-tracker

# Check rollout history
kubectl rollout history deployment/backend -n expense-tracker
```

## Teardown

```bash
# Remove Kubernetes resources
make k8s-delete

# Destroy AWS infrastructure
cd terraform && terraform destroy

# Stop local services
docker compose down -v
```
