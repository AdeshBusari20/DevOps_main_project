# Architecture Documentation

## System Architecture

The AI Expense Tracker follows a **microservices-inspired architecture** with clear separation between frontend, backend, database, and infrastructure layers.

### Components

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Frontend | React 18 | User interface with charts and forms |
| Backend | FastAPI | REST API with AI categorization |
| Database | PostgreSQL 16 | Persistent data storage |
| Reverse Proxy | NGINX | Load balancing, SSL termination |
| CI/CD | Jenkins + GitHub Actions | Automated build/test/deploy |
| Container Runtime | Docker | Application containerization |
| Orchestration | Kubernetes | Container orchestration & scaling |
| IaC | Terraform | AWS infrastructure provisioning |
| Config Mgmt | Ansible | Server configuration automation |
| Monitoring | Prometheus + Grafana | Metrics, dashboards, alerting |
| Security | SonarQube + Trivy + OWASP | Code quality & vulnerability scanning |

### Data Flow

```
User → NGINX (port 80/443)
       ├── / → Frontend (React SPA)
       └── /api/* → Backend (FastAPI)
                     └── PostgreSQL (Data)

Prometheus → scrapes /metrics from Backend
          → Node Exporter (system metrics)
          → Grafana (visualization)
          → AlertManager → Slack/Email
```

### Deployment Architecture

```
Developer Machine
    │
    ├── git push → GitHub
    │                │
    │                ├── Webhook → Jenkins
    │                │              ├── Build
    │                │              ├── Test
    │                │              ├── Scan (SonarQube + Trivy)
    │                │              ├── Docker Build
    │                │              ├── Push to Docker Hub
    │                │              └── Deploy to K8s
    │                │
    │                └── GitHub Actions (backup CI)
    │
    └── terraform apply → AWS
                          ├── VPC + Subnets
                          ├── EC2 (App Server)
                          ├── EC2 (Jenkins Server)
                          └── EC2 (Monitoring Server)
                                └── ansible → Configure servers
```

### Network Architecture

- **VPC CIDR**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (across 2 AZs)
- **Private Subnets**: 10.0.3.0/24, 10.0.4.0/24
- **NAT Gateway**: For private subnet internet access
- **Internet Gateway**: For public subnet access

### Security Layers

1. **Network**: VPC, Security Groups, NAT Gateway
2. **Application**: CORS, rate limiting, input validation
3. **Container**: Non-root users, minimal base images, Trivy scanning
4. **CI/CD**: SonarQube code analysis, OWASP dependency check
5. **Data**: Encrypted EBS volumes, K8s Secrets, env variables
6. **Access**: IAM roles, SSH key pairs, SSM
