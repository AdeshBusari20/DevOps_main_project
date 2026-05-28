# Monitoring Guide

## Overview

The monitoring stack provides full observability:

| Tool | Port | Purpose |
|------|------|---------|
| Prometheus | 9090 | Metrics collection & alerting |
| Grafana | 3001 | Dashboards & visualization |
| Node Exporter | 9100 | System metrics (CPU, RAM, disk) |
| cAdvisor | 8081 | Container metrics |
| AlertManager | 9093 | Alert routing & notifications |

## Quick Start

```bash
# Start the monitoring stack
cd monitoring
docker compose -f docker-compose.monitoring.yml up -d

# Or use Makefile
make monitoring-up
```

## Access Dashboards

- **Grafana**: http://localhost:3001 (admin/admin)
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093

## Metrics Collected

### Application Metrics (from FastAPI `/metrics`)
- `http_requests_total` — Total HTTP requests by method, endpoint, status
- `http_request_duration_seconds` — Request latency histogram

### System Metrics (from Node Exporter)
- CPU usage, load average
- Memory usage, swap
- Disk I/O, filesystem usage
- Network traffic

### Container Metrics (from cAdvisor)
- Container CPU/memory usage
- Container restart count
- Network I/O per container

## Grafana Dashboards

### Pre-configured Dashboard
The **Application Dashboard** (`app-dashboard.json`) includes:
1. Total HTTP Requests (24h)
2. Error Rate percentage
3. p95 Response Time
4. Active Services count
5. Request Rate by Endpoint (time series)
6. Response Time Distribution (p50/p90/p99)
7. HTTP Status Codes (pie chart)
8. CPU Usage (time series)
9. Memory Usage (time series)

### Recommended Community Dashboards
Import these from [Grafana.com](https://grafana.com/grafana/dashboards/):
- **Node Exporter Full** — ID: `1860`
- **Docker & System** — ID: `893`
- **NGINX** — ID: `12708`

## Alert Rules

Alerts are defined in `monitoring/prometheus/alert-rules.yml`:

| Alert | Condition | Severity |
|-------|-----------|----------|
| HighErrorRate | >5% 5xx errors for 5min | Critical |
| SlowResponseTime | p95 > 2s for 5min | Warning |
| ServiceDown | Target unreachable for 1min | Critical |
| HighCPUUsage | >80% for 10min | Warning |
| HighMemoryUsage | >85% for 5min | Warning |
| DiskSpaceLow | >85% full for 5min | Critical |
| ContainerRestarting | >3 restarts in 10min | Warning |

## Configure Notifications

Edit `monitoring/alertmanager/alertmanager.yml` to enable:

### Email
```yaml
receivers:
  - name: 'email'
    email_configs:
      - to: 'your-email@example.com'
        from: 'alertmanager@example.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'your-email@gmail.com'
        auth_password: 'app-specific-password'
```

### Slack
```yaml
receivers:
  - name: 'slack'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#devops-alerts'
```
