# 🚀 Production Deployment Guide

> Complete guide to deploying the AI Expense Tracker to a **real AWS cloud environment** with a public URL, HTTPS, and monitoring.

---

## 📋 Table of Contents

- [Prerequisites](#-prerequisites)
- [Deployment Options](#-deployment-options)
- [Option A: EC2 + Docker Compose (Recommended)](#-option-a-ec2--docker-compose-recommended)
- [Option B: EC2 + K3s](#-option-b-ec2--k3s)
- [Option C: AWS EKS](#-option-c-aws-eks)
- [SSL/HTTPS Setup](#-sslhttps-setup)
- [DNS Configuration](#-dns-configuration)
- [Monitoring Deployment](#-monitoring-deployment)
- [Security Hardening](#-security-hardening)
- [Backup & Recovery](#-backup--recovery)
- [Cost Analysis](#-cost-analysis)
- [Architecture Diagram](#-architecture-diagram)
- [Public URL Structure](#-public-url-structure)
- [Deployment Checklist](#-deployment-checklist)
- [Production Readiness Score](#-production-readiness-score)
- [Troubleshooting](#-troubleshooting)

---

## 🔧 Prerequisites

### Required Tools

| Tool | Version | Installation |
|------|---------|-------------|
| AWS CLI | v2.x | `curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install` |
| Terraform | >= 1.5.0 | `sudo apt install -y gnupg software-properties-common && wget -O- https://apt.releases.hashicorp.com/gpg \| sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \| sudo tee /etc/apt/sources.list.d/hashicorp.list && sudo apt update && sudo apt install terraform` |
| Ansible | >= 2.15 | `pip install ansible` |
| Docker | 24.x | Already on your machine |
| Git | Latest | Already on your machine |

### AWS Account Setup

```bash
# 1. Create AWS account at https://aws.amazon.com (if you don't have one)
# 2. Create an IAM user with programmatic access
# 3. Attach these policies:
#    - AmazonEC2FullAccess
#    - AmazonVPCFullAccess
#    - IAMFullAccess

# 4. Configure AWS CLI
aws configure
# Enter:
#   AWS Access Key ID:     YOUR_ACCESS_KEY
#   AWS Secret Access Key: YOUR_SECRET_KEY
#   Default region:        ap-south-1
#   Default output format: json

# 5. Verify
aws sts get-caller-identity
```

---

## 📊 Deployment Options

| Factor | **Option A: EC2 + Docker Compose** | **Option B: EC2 + K3s** | **Option C: AWS EKS** |
|--------|------|------|------|
| Complexity | 🟢 Low | 🟡 Medium | 🔴 High |
| Monthly Cost | **$0** (free-tier) / $18 | ~$36 | ~$123 |
| Setup Time | 30 min | 1 hour | 2-3 hours |
| Free Tier | ✅ Yes | ⚠️ Partial | ❌ No |
| Best For | Portfolio/Demo | Learning K8s | Enterprise |

**⭐ Recommendation: Option A** — Free, fast, and still demonstrates Docker, CI/CD, monitoring, and cloud deployment.

---

## ⭐ Option A: EC2 + Docker Compose (Recommended)

### Automated Deployment (One Command)

```bash
# From your local machine, run the provisioning script:
bash scripts/provision-aws.sh
```

This single command will:
1. ✅ Create an EC2 key pair
2. ✅ Provision AWS infrastructure via Terraform
3. ✅ Wait for the server to initialize
4. ✅ Deploy the full application stack
5. ✅ Output the public URL

### Manual Step-by-Step Deployment

#### Step 1: Create EC2 Key Pair

```bash
# Create SSH key pair
aws ec2 create-key-pair \
  --key-name expense-tracker-key \
  --region ap-south-1 \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/expense-tracker-key.pem

chmod 400 ~/.ssh/expense-tracker-key.pem
```

#### Step 2: Provision Infrastructure with Terraform

```bash
cd terraform

# Use single-instance configuration
cp terraform.tfvars.single terraform.tfvars

# Edit with your IP for SSH security (optional)
# Find your IP: curl http://checkip.amazonaws.com
# sed -i 's|0.0.0.0/0|YOUR_IP/32|g' terraform.tfvars

# Initialize Terraform
terraform init

# Preview what will be created
terraform plan

# Create infrastructure (takes ~2-3 minutes)
terraform apply -auto-approve

# Save the outputs
terraform output

# Note these values:
#   single_server_public_ip  = "54.xxx.xxx.xxx"
#   single_server_ssh        = "ssh -i expense-tracker-key.pem ubuntu@54.xxx.xxx.xxx"
#   single_server_nip_url    = "http://54-xxx-xxx-xxx.nip.io"
```

#### Step 3: Wait for Server Initialization

```bash
# Get the server IP from Terraform output
SERVER_IP=$(cd terraform && terraform output -raw single_server_public_ip)

# Wait for cloud-init to complete (usually 2-3 minutes)
ssh -i ~/.ssh/expense-tracker-key.pem -o StrictHostKeyChecking=no ubuntu@$SERVER_IP \
  "cloud-init status --wait"
```

#### Step 4: Deploy Application

**Option 4a: Using Ansible (Recommended)**

```bash
cd ansible

# Update inventory with your server IP
SERVER_IP=$(cd ../terraform && terraform output -raw single_server_public_ip)
sed -i "s/YOUR_APP_SERVER_IP/$SERVER_IP/g" inventory/hosts.ini

# Install Docker
ansible-playbook -i inventory/hosts.ini playbooks/setup-docker.yml

# Deploy application + monitoring
ansible-playbook -i inventory/hosts.ini playbooks/deploy-production.yml
```

**Option 4b: Direct SSH Deployment**

```bash
SERVER_IP=$(cd terraform && terraform output -raw single_server_public_ip)

# SSH into the server
ssh -i ~/.ssh/expense-tracker-key.pem ubuntu@$SERVER_IP

# On the server:
git clone https://github.com/AdeshBusari20/DevOps_main_project.git /opt/expense-tracker
cd /opt/expense-tracker
sudo bash scripts/deploy-production.sh
```

#### Step 5: Verify Deployment

```bash
SERVER_IP=$(cd terraform && terraform output -raw single_server_public_ip)

# Test health endpoint
curl http://$SERVER_IP/health

# Test API
curl http://$SERVER_IP/api/v1/expenses/

# Open in browser
echo "Frontend:   http://$SERVER_IP"
echo "API Docs:   http://$SERVER_IP/docs"
echo "Grafana:    http://$SERVER_IP:3001"
echo "Prometheus: http://$SERVER_IP:9090"

# nip.io URL (shareable)
NIP_DOMAIN="${SERVER_IP//./-}.nip.io"
echo "Shareable:  http://$NIP_DOMAIN"
```

#### Step 6: Setup HTTPS (Optional but Recommended)

```bash
# SSH into server
ssh -i ~/.ssh/expense-tracker-key.pem ubuntu@$SERVER_IP

# Run SSL setup (auto-detects IP and uses nip.io)
sudo bash /opt/expense-tracker/scripts/setup-ssl.sh

# Or with a custom domain:
sudo bash /opt/expense-tracker/scripts/setup-ssl.sh your-domain.com
```

---

## 🔧 Option B: EC2 + K3s

K3s is a lightweight Kubernetes distribution perfect for single-node deployments.

### Step 1: Provision EC2 (t2.medium required)

```bash
cd terraform

# Edit terraform.tfvars.single
# Change: single_instance_type = "t2.medium"
cp terraform.tfvars.single terraform.tfvars
sed -i 's/t2.small/t2.medium/g' terraform.tfvars

terraform init && terraform apply -auto-approve
SERVER_IP=$(terraform output -raw single_server_public_ip)
```

### Step 2: Install K3s

```bash
ssh -i ~/.ssh/expense-tracker-key.pem ubuntu@$SERVER_IP

# Install K3s (lightweight Kubernetes)
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# Verify
kubectl get nodes
# NAME            STATUS   ROLES                  AGE   VERSION
# ip-10-0-1-xxx   Ready    control-plane,master   30s   v1.30.x+k3s1
```

### Step 3: Deploy Application to K3s

```bash
# Clone repo
git clone https://github.com/AdeshBusari20/DevOps_main_project.git /opt/expense-tracker
cd /opt/expense-tracker

# Deploy all Kubernetes resources
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

# Wait for pods
kubectl get pods -n expense-tracker -w

# Check services
kubectl get svc -n expense-tracker
```

### Step 4: Install NGINX Ingress Controller

```bash
# K3s comes with Traefik by default, but you can use NGINX Ingress:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### Step 5: Access Application

```bash
# Application is available on port 80 via ingress
curl http://$SERVER_IP/health
echo "Frontend: http://$SERVER_IP"
```

---

## ☁️ Option C: AWS EKS

### Step 1: Install eksctl

```bash
# Install eksctl
curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

### Step 2: Create EKS Cluster

```bash
# Create cluster (takes 15-20 minutes)
eksctl create cluster \
  --name expense-tracker \
  --region ap-south-1 \
  --version 1.30 \
  --nodegroup-name workers \
  --node-type t3.small \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed

# Verify
kubectl get nodes
```

### Step 3: Deploy Application

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/aws/deploy.yaml

# Wait for the Load Balancer
kubectl get svc -n ingress-nginx
# Note the EXTERNAL-IP (AWS ALB DNS name)

# Deploy application
kubectl apply -f kubernetes/

# Get the public URL
kubectl get ingress -n expense-tracker
```

### Step 4: Cleanup (Important — EKS costs money!)

```bash
# Delete cluster when done
eksctl delete cluster --name expense-tracker --region ap-south-1
```

---

## 🔐 SSL/HTTPS Setup

### Automated (Recommended)

```bash
# SSH into your server
ssh -i ~/.ssh/expense-tracker-key.pem ubuntu@YOUR_SERVER_IP

# Auto-detect IP and setup with nip.io
sudo bash /opt/expense-tracker/scripts/setup-ssl.sh

# Or with custom domain
sudo bash /opt/expense-tracker/scripts/setup-ssl.sh your-domain.com
```

### Using Ansible

```bash
# From your local machine
cd ansible

# Auto-detect domain (nip.io)
ansible-playbook -i inventory/hosts.ini playbooks/setup-ssl.yml

# With custom domain
ansible-playbook -i inventory/hosts.ini playbooks/setup-ssl.yml -e "domain=your-domain.com"
```

### What the SSL Setup Does

1. Installs Certbot (Let's Encrypt client)
2. Temporarily stops Nginx
3. Obtains SSL certificate via HTTP-01 challenge
4. Copies certificates to `nginx/ssl/`
5. Swaps Nginx config to HTTPS (production.conf → default.conf)
6. Restarts Nginx with SSL
7. Sets up auto-renewal cron job (runs twice daily)

### Certificate Renewal

Certificates auto-renew. To manually test renewal:

```bash
sudo certbot renew --dry-run
```

---

## 🌐 DNS Configuration

### Option 1: nip.io (Free, No Configuration)

nip.io is a wildcard DNS service. Any IP address works:

```
http://54-123-45-67.nip.io  →  resolves to 54.123.45.67
```

No DNS configuration needed! SSL with Let's Encrypt works with nip.io.

### Option 2: Custom Domain

1. **Buy a domain** (~$1-3/year for `.xyz`, `.tech`, `.site`)
   - [Namecheap](https://www.namecheap.com)
   - [GoDaddy](https://www.godaddy.com)
   - [Cloudflare Registrar](https://www.cloudflare.com/products/registrar/)

2. **Configure DNS records:**

```
Type    Name    Value               TTL
A       @       YOUR_SERVER_IP      300
A       www     YOUR_SERVER_IP      300
CNAME   api     YOUR_SERVER_IP      300
```

3. **Or use AWS Route 53:**

```bash
# Create hosted zone
aws route53 create-hosted-zone --name your-domain.com --caller-reference $(date +%s)

# Add A record
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "your-domain.com",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "YOUR_SERVER_IP"}]
      }
    }]
  }'
```

4. **Update Nginx and get SSL:**

```bash
# SSH into server
ssh -i ~/.ssh/expense-tracker-key.pem ubuntu@YOUR_SERVER_IP

# Get SSL certificate for your domain
sudo bash /opt/expense-tracker/scripts/setup-ssl.sh your-domain.com
```

---

## 📡 Monitoring Deployment

### Access URLs

After deployment, monitoring is available at:

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Grafana | `http://YOUR_IP:3001` | admin / (from .env) |
| Prometheus | `http://YOUR_IP:9090` | No auth |
| AlertManager | `http://YOUR_IP:9093` | No auth |
| Node Exporter | `http://YOUR_IP:9100/metrics` | No auth |
| cAdvisor | `http://YOUR_IP:8081` | No auth |

### Grafana First Login

1. Open `http://YOUR_SERVER_IP:3001`
2. Login with credentials from `.env` file
3. Prometheus datasource is auto-provisioned
4. Dashboard is pre-loaded at Dashboards → Browse → App Dashboard

### Verify Prometheus Targets

1. Open `http://YOUR_SERVER_IP:9090/targets`
2. All targets should show **UP**:
   - `expense-tracker-backend` (backend:8000)
   - `node-exporter` (node-exporter:9100)
   - `cadvisor` (cadvisor:8080)
   - `prometheus` (localhost:9090)

### AlertManager Configuration

Edit `monitoring/alertmanager/alertmanager.yml` to configure notifications:

```yaml
# Email notifications
receivers:
  - name: 'default-receiver'
    email_configs:
      - to: 'your-email@gmail.com'
        from: 'alertmanager@your-domain.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your-email@gmail.com'
        auth_password: 'your-app-password'
```

---

## 🛡️ Security Hardening

The deployment scripts automatically configure:

| Security Measure | Status |
|-----------------|--------|
| UFW Firewall | ✅ Only ports 22, 80, 443, 3001, 9090 open |
| Fail2Ban | ✅ Brute-force protection |
| Non-root Docker containers | ✅ Backend runs as `appuser` |
| HTTPS/TLS 1.2+ | ✅ Via Let's Encrypt |
| Security headers | ✅ HSTS, X-Frame-Options, CSP |
| Rate limiting | ✅ 20 req/s API, 5 req/s login |
| Nginx version hidden | ✅ `server_tokens off` |
| Database not exposed | ✅ Only accessible within Docker network |
| Strong passwords | ✅ Auto-generated 32-char random |
| SSH key-only auth | ✅ Via EC2 key pair |

### Additional Hardening (Optional)

```bash
# Disable password SSH login
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Install and configure automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## 💾 Backup & Recovery

### Database Backup

```bash
# Manual backup
ssh -i ~/.ssh/expense-tracker-key.pem ubuntu@YOUR_SERVER_IP
cd /opt/expense-tracker
bash scripts/backup-db.sh

# Automated daily backups (add to crontab)
crontab -e
# Add: 0 2 * * * cd /opt/expense-tracker && bash scripts/backup-db.sh >> /var/log/db-backup.log 2>&1
```

### Disaster Recovery

```bash
# Restore from backup
gunzip backups/expense_tracker_YYYYMMDD_HHMMSS.sql.gz
docker exec -i expense-postgres-prod psql -U expense_user -d expense_tracker < backups/expense_tracker_YYYYMMDD_HHMMSS.sql
```

---

## 💰 Cost Analysis

### Option A (Recommended) — AWS Free Tier

| Resource | Specification | Monthly Cost |
|----------|--------------|-------------|
| EC2 Instance | t2.micro (free-tier) | **$0.00** |
| EBS Volume | 30GB gp3 | **$2.40** |
| Elastic IP | 1x (attached to running instance) | **$0.00** |
| Data Transfer | First 100GB/month free | **$0.00** |
| **Total** | | **~$2.40/month** |

> After 12-month free-tier expires, upgrade to t2.small (~$18/month total)

### Option A — Post Free-Tier

| Resource | Specification | Monthly Cost |
|----------|--------------|-------------|
| EC2 Instance | t2.small (2GB RAM) | $18.40 |
| EBS Volume | 30GB gp3 | $2.40 |
| Elastic IP | 1x | $0.00 |
| **Total** | | **~$21/month** |

### Cost Optimization Tips

1. **Use free-tier t2.micro** with 2GB swap file (configured automatically)
2. **Stop the instance** when not in use: `aws ec2 stop-instances --instance-ids i-xxxxx`
3. **Use Spot Instances** for up to 90% savings (not recommended for portfolio demos)
4. **Schedule start/stop** with AWS Lambda + CloudWatch Events

---

## 🏗️ Architecture Diagram

### Production Architecture (Option A)

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud (ap-south-1)                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                      │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │              Public Subnet (10.0.1.0/24)            │  │  │
│  │  │                                                     │  │  │
│  │  │  ┌──────────────────────────────────────────────┐   │  │  │
│  │  │  │         EC2 Instance (t2.small)              │   │  │  │
│  │  │  │         Elastic IP: 54.x.x.x                │   │  │  │
│  │  │  │                                              │   │  │  │
│  │  │  │  ┌──── Docker Compose ────────────────────┐  │   │  │  │
│  │  │  │  │                                        │  │   │  │  │
│  │  │  │  │  ┌──────┐  ┌─────────┐  ┌──────────┐  │  │   │  │  │
│  │  │  │  │  │Nginx │→ │Frontend │  │ Backend  │  │  │   │  │  │
│  │  │  │  │  │:80   │  │ React   │  │ FastAPI  │  │  │   │  │  │
│  │  │  │  │  │:443  │→ │ :80     │  │ :8000    │  │  │   │  │  │
│  │  │  │  │  └──────┘  └─────────┘  └────┬─────┘  │  │   │  │  │
│  │  │  │  │                               │        │  │   │  │  │
│  │  │  │  │                          ┌────▼─────┐  │  │   │  │  │
│  │  │  │  │                          │PostgreSQL│  │  │   │  │  │
│  │  │  │  │                          │ :5432    │  │  │   │  │  │
│  │  │  │  │                          └──────────┘  │  │   │  │  │
│  │  │  │  │                                        │  │   │  │  │
│  │  │  │  │  ┌──────────┐ ┌───────┐ ┌──────────┐  │  │   │  │  │
│  │  │  │  │  │Prometheus│ │Grafana│ │AlertMgr  │  │  │   │  │  │
│  │  │  │  │  │ :9090    │ │:3001  │ │:9093     │  │  │   │  │  │
│  │  │  │  │  └──────────┘ └───────┘ └──────────┘  │  │   │  │  │
│  │  │  │  │                                        │  │   │  │  │
│  │  │  │  │  ┌──────────┐ ┌───────────┐            │  │   │  │  │
│  │  │  │  │  │NodeExport│ │ cAdvisor  │            │  │   │  │  │
│  │  │  │  │  │ :9100    │ │ :8081     │            │  │   │  │  │
│  │  │  │  │  └──────────┘ └───────────┘            │  │   │  │  │
│  │  │  │  └────────────────────────────────────────┘  │   │  │  │
│  │  │  └──────────────────────────────────────────────┘   │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Security Group: SSH(22), HTTP(80), HTTPS(443),                 │
│                  Grafana(3001), Prometheus(9090)                 │
└─────────────────────────────────────────────────────────────────┘

Internet → Elastic IP → Nginx(:80/:443) → Frontend/Backend → PostgreSQL
                                        → Prometheus → Grafana
```

### Request Flow

```
User Browser
    │
    ▼
Nginx (port 80/443)
    │
    ├── /           → Frontend (React SPA)
    ├── /api/*      → Backend (FastAPI)
    ├── /docs       → Backend (Swagger UI)
    ├── /health     → Backend (Health Check)
    └── /metrics    → Backend (Prometheus metrics)

Prometheus (port 9090)
    │
    ├── Scrapes backend:8000/metrics every 10s
    ├── Scrapes node-exporter:9100 every 15s
    ├── Scrapes cadvisor:8080 every 15s
    └── Fires alerts → AlertManager:9093

Grafana (port 3001)
    │
    └── Queries Prometheus for dashboards
```

---

## 🌐 Public URL Structure

### Using nip.io (No Domain Required)

If your server IP is `54.123.45.67`:

| Service | URL |
|---------|-----|
| **Frontend** | `http://54-123-45-67.nip.io` |
| **API** | `http://54-123-45-67.nip.io/api/v1/expenses/` |
| **API Docs** | `http://54-123-45-67.nip.io/docs` |
| **Health** | `http://54-123-45-67.nip.io/health` |
| **Grafana** | `http://54-123-45-67.nip.io:3001` |
| **Prometheus** | `http://54-123-45-67.nip.io:9090` |

### With HTTPS (After SSL Setup)

| Service | URL |
|---------|-----|
| **Frontend** | `https://54-123-45-67.nip.io` |
| **API** | `https://54-123-45-67.nip.io/api/v1/expenses/` |
| **API Docs** | `https://54-123-45-67.nip.io/docs` |

### With Custom Domain

| Service | URL |
|---------|-----|
| **Frontend** | `https://expense-tracker.yourdomain.com` |
| **API** | `https://expense-tracker.yourdomain.com/api/v1/expenses/` |
| **API Docs** | `https://expense-tracker.yourdomain.com/docs` |

---

## ✅ Deployment Checklist

### Pre-Deployment

- [ ] AWS account created and configured (`aws configure`)
- [ ] AWS CLI installed and verified (`aws sts get-caller-identity`)
- [ ] Terraform installed (`terraform --version`)
- [ ] SSH key pair created or available
- [ ] Docker images built and pushed to Docker Hub
- [ ] `.env.production.example` reviewed

### Infrastructure

- [ ] Terraform initialized (`terraform init`)
- [ ] Terraform plan reviewed (`terraform plan`)
- [ ] Terraform applied (`terraform apply`)
- [ ] EC2 instance is running
- [ ] Elastic IP assigned
- [ ] Security groups configured
- [ ] Server is SSH-accessible

### Application

- [ ] Repository cloned to `/opt/expense-tracker`
- [ ] Production `.env` created with strong passwords
- [ ] Docker images pulled successfully
- [ ] All containers running (`docker compose ps`)
- [ ] PostgreSQL is healthy
- [ ] Backend responds to `/health`
- [ ] Frontend loads in browser
- [ ] API Docs accessible at `/docs`
- [ ] Nginx reverse proxy working

### SSL/HTTPS

- [ ] Certbot installed
- [ ] SSL certificate obtained
- [ ] HTTPS redirect working (HTTP → HTTPS)
- [ ] Certificate auto-renewal configured
- [ ] HSTS header present

### Monitoring

- [ ] Prometheus running and scraping targets
- [ ] Grafana accessible with dashboard loaded
- [ ] AlertManager configured
- [ ] Node Exporter providing system metrics
- [ ] cAdvisor providing container metrics

### Security

- [ ] UFW firewall enabled
- [ ] Fail2Ban running
- [ ] SSH key-only authentication
- [ ] Database not exposed to internet
- [ ] Strong passwords in `.env`
- [ ] Nginx security headers present

### Post-Deployment

- [ ] Public URL accessible and functional
- [ ] Can create/read/update/delete expenses
- [ ] AI categorization working
- [ ] Monitoring dashboards showing data
- [ ] Database backup script tested
- [ ] Deployment documented

---

## 📊 Production Readiness Score

Rate your deployment against these criteria:

| Category | Criteria | Points | Score |
|----------|----------|--------|-------|
| **Availability** | Application accessible via public URL | 10 | /10 |
| **Security** | HTTPS enabled with valid certificate | 10 | /10 |
| **Security** | Firewall configured (UFW) | 5 | /5 |
| **Security** | Non-root containers | 5 | /5 |
| **Security** | Strong passwords (auto-generated) | 5 | /5 |
| **Monitoring** | Prometheus collecting metrics | 10 | /10 |
| **Monitoring** | Grafana dashboards operational | 10 | /10 |
| **Monitoring** | Alerting configured | 5 | /5 |
| **Reliability** | Health checks passing | 5 | /5 |
| **Reliability** | Container restart policies (always) | 5 | /5 |
| **Reliability** | Database persistence (volumes) | 5 | /5 |
| **Operations** | Backup script tested | 5 | /5 |
| **Operations** | SSL auto-renewal configured | 5 | /5 |
| **IaC** | Infrastructure as Code (Terraform) | 10 | /10 |
| **Automation** | Configuration Management (Ansible) | 5 | /5 |
| **TOTAL** | | **100** | **/100** |

**Rating:**
- 90-100: 🏆 Production-Grade
- 75-89: ✅ Portfolio-Ready
- 60-74: ⚠️ Needs Improvement
- Below 60: ❌ Not Ready

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Terraform Apply Fails

```bash
# Check AWS credentials
aws sts get-caller-identity

# Check Terraform state
terraform state list

# Force recreation of problematic resource
terraform taint aws_instance.single_server[0]
terraform apply
```

#### 2. Docker Compose Fails to Start

```bash
# Check logs
docker compose -f docker-compose.prod.single.yml logs

# Check specific service
docker compose -f docker-compose.prod.single.yml logs backend

# Restart everything
docker compose -f docker-compose.prod.single.yml down
docker compose -f docker-compose.prod.single.yml up -d
```

#### 3. Backend Can't Connect to Database

```bash
# Check if PostgreSQL is healthy
docker exec expense-postgres-prod pg_isready -U expense_user

# Check environment variables
docker exec expense-backend-prod env | grep DATABASE

# Check logs
docker logs expense-backend-prod
```

#### 4. SSL Certificate Fails

```bash
# Ensure port 80 is open
sudo ufw status
curl http://YOUR_IP

# Check DNS resolution
nslookup YOUR-IP.nip.io

# Try with verbose output
sudo certbot certonly --standalone -d YOUR-IP.nip.io --verbose
```

#### 5. Out of Memory (t2.micro)

```bash
# Check memory
free -h

# Verify swap is enabled
swapon --show

# If no swap, create one
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### 6. Can't Access from Browser

```bash
# Check security group allows HTTP/HTTPS
aws ec2 describe-security-groups --group-ids YOUR_SG_ID

# Check UFW
sudo ufw status

# Check if containers are running
docker compose -f docker-compose.prod.single.yml ps

# Check nginx
docker logs expense-nginx-prod
```

### Teardown / Cleanup

```bash
# Stop application
ssh -i ~/.ssh/expense-tracker-key.pem ubuntu@YOUR_SERVER_IP
cd /opt/expense-tracker
docker compose -f docker-compose.prod.single.yml down -v

# Destroy AWS infrastructure
cd terraform
terraform destroy -auto-approve

# Delete key pair
aws ec2 delete-key-pair --key-name expense-tracker-key --region ap-south-1
rm ~/.ssh/expense-tracker-key.pem
```

---

## 📎 Quick Reference — All Commands

```bash
# ===== PROVISION =====
bash scripts/provision-aws.sh                    # One-command AWS setup

# ===== TERRAFORM =====
cd terraform
cp terraform.tfvars.single terraform.tfvars
terraform init
terraform plan
terraform apply -auto-approve
terraform output                                  # Get server IP
terraform destroy -auto-approve                   # Teardown

# ===== ANSIBLE =====
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/setup-docker.yml
ansible-playbook -i inventory/hosts.ini playbooks/deploy-production.yml
ansible-playbook -i inventory/hosts.ini playbooks/setup-ssl.yml

# ===== DIRECT DEPLOYMENT =====
ssh -i ~/.ssh/expense-tracker-key.pem ubuntu@SERVER_IP
sudo bash /opt/expense-tracker/scripts/deploy-production.sh
sudo bash /opt/expense-tracker/scripts/setup-ssl.sh

# ===== MONITORING =====
# Grafana:      http://SERVER_IP:3001
# Prometheus:   http://SERVER_IP:9090
# AlertManager: http://SERVER_IP:9093

# ===== MAINTENANCE =====
docker compose -f docker-compose.prod.single.yml logs -f
docker compose -f docker-compose.prod.single.yml restart
bash scripts/health-check.sh
bash scripts/backup-db.sh
```
