# Security Practices (DevSecOps)

## Security Tools Integrated

| Tool | Purpose | Stage |
|------|---------|-------|
| SonarQube | Static code analysis, code smells, bugs | CI Pipeline |
| Trivy | Container image vulnerability scanning | CI Pipeline |
| OWASP Dependency Check | Known vulnerability detection in dependencies | CI Pipeline |

## SonarQube Integration

### Setup
```bash
# Run SonarQube locally
docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community

# Access: http://localhost:9000 (admin/admin)
# Generate token: My Account → Security → Generate Token

# Run scanner
sonar-scanner \
  -Dsonar.projectKey=ai-expense-tracker \
  -Dsonar.sources=backend/app,frontend/src \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=YOUR_TOKEN
```

### Quality Gates
- No new critical/blocker bugs
- Code coverage > 60%
- Duplicated lines < 5%
- No new security hotspots

## Trivy Scanning

```bash
# Scan filesystem
trivy fs --severity HIGH,CRITICAL backend/

# Scan Docker image
trivy image adeshbusari20/expense-tracker-backend:latest

# Scan with JSON output
trivy image --format json --output results.json adeshbusari20/expense-tracker-backend:latest
```

## OWASP Dependency Check

```bash
# Scan Python dependencies
dependency-check --project "expense-tracker" \
                 --scan backend/requirements.txt \
                 --format HTML \
                 --out reports/
```

## Security Best Practices Applied

### Container Security
- Multi-stage Docker builds (minimal attack surface)
- Non-root user in containers (`USER appuser`)
- Slim base images (`python:3.12-slim`, `node:20-alpine`)
- No secrets in Docker images
- `.dockerignore` to prevent sensitive file inclusion

### Kubernetes Security
- Secrets management via K8s Secrets (base64)
- Resource limits on all pods
- Network policies for pod isolation
- RBAC with minimal permissions
- Readiness/liveness probes

### Network Security
- VPC with public/private subnet separation
- Security groups with least-privilege rules
- Database only accessible from app security group
- NGINX rate limiting (20 req/s API, 5 req/s login)
- Security headers (X-Frame-Options, CSP, etc.)

### Application Security
- CORS configuration (restrict origins in production)
- Input validation with Pydantic schemas
- SQL injection prevention via SQLAlchemy ORM
- Environment variables for secrets (never hardcoded)
- HTTPS ready (SSL config prepared)

### CI/CD Security
- Credentials stored in Jenkins/GitHub Secrets
- No secrets in Jenkinsfile or code
- Security scanning as pipeline gate
- Docker Hub access token (not password)
- Kubeconfig via encrypted secret
