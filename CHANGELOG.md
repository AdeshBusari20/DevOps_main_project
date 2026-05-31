# Changelog

All notable changes to the AI Expense Tracker project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-31

### Added

#### Application
- Full-stack expense tracking with React 18 frontend and FastAPI backend
- AI-powered expense auto-categorization across 14 categories
- Spending analytics with interactive Chart.js dashboards
- RESTful API with Swagger/OpenAPI documentation
- Pagination, filtering, and sorting for expense lists
- Responsive dark-mode UI with glassmorphism design
- Health check (`/health`) and readiness (`/ready`) endpoints
- Prometheus metrics endpoint (`/metrics`)

#### Containerization
- Multi-stage Docker builds for frontend (Node → NGINX) and backend (Python builder → slim runtime)
- Non-root container users for security
- Docker Compose for development environment (4 services)
- Docker Compose for production environment (with resource limits and replicas)
- Docker health checks on all services
- Optimized `.dockerignore` files

#### CI/CD
- GitHub Actions pipeline with 5 jobs: Backend Tests → Frontend Build → Security Scan → Docker Build & Push → K8s Deploy
- Jenkins pipeline with 11 stages including parallel execution
- Trivy filesystem vulnerability scanning
- Kubeconform manifest validation
- Docker Hub image push with SHA and `latest` tags

#### Kubernetes
- Complete manifest set (10 files) for production deployment
- Namespace isolation (`expense-tracker`)
- Backend and Frontend Deployments with rolling update strategy
- PostgreSQL StatefulSet with persistent storage
- ConfigMap for application configuration
- Secrets for database credentials
- NGINX Ingress with rate limiting and CORS
- Horizontal Pod Autoscaler (CPU + memory based)
- PersistentVolume and PersistentVolumeClaim (10Gi)
- Network policies for pod-to-pod traffic control
- Pod Disruption Budgets for high availability

#### Infrastructure as Code
- Terraform AWS infrastructure: VPC, public/private subnets, EC2 instances, Security Groups, IAM roles
- Ansible playbooks for server provisioning: Docker, Jenkins, Kubernetes, Monitoring
- Ansible roles for reusable configuration

#### Monitoring & Observability
- Prometheus metrics collection (scrape interval: 15s)
- Grafana dashboards with pre-configured panels
- AlertManager with 7 alert rules (error rate, latency, CPU, memory, disk, restarts)
- Node Exporter for system metrics
- cAdvisor for container metrics

#### Security (DevSecOps)
- SonarQube static code analysis integration
- Trivy container image vulnerability scanning
- OWASP Dependency Check for known CVEs
- NGINX reverse proxy with rate limiting and security headers
- AWS Security Groups with least-privilege rules
- IAM roles with minimal permissions

#### Documentation
- Comprehensive README with architecture diagrams
- API documentation with request/response examples
- Deployment guide (local, Docker, Kubernetes, AWS)
- Monitoring guide with dashboard setup
- Security practices documentation
- Troubleshooting guide with common issues and fixes

### Infrastructure
- NGINX reverse proxy with SSL-ready configuration
- Database backup scripts
- Health check scripts
- Setup and deployment automation scripts

[1.0.0]: https://github.com/AdeshBusari20/DevOps_main_project/releases/tag/v1.0.0
