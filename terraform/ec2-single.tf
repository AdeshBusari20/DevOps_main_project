# ==============================================
# EC2 Single Instance - Cost-Optimized Deployment
# ==============================================
# Deploys ALL services (app + monitoring) on a
# single EC2 instance for college portfolio use.
#
# Usage:
#   terraform plan -var-file="terraform.tfvars.single"
#   terraform apply -var-file="terraform.tfvars.single"
#
# Cost: $0/month (free-tier t2.micro) or ~$18/month (t2.small)
# ==============================================

# ---- Single All-in-One Server ----
resource "aws_instance" "single_server" {
  count = var.single_instance_mode ? 1 : 0

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.single_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = var.single_instance_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  # Cloud-init: Install Docker, Docker Compose, and essential tools
  user_data = <<-EOF
    #!/bin/bash
    set -e
    exec > /var/log/user-data.log 2>&1

    echo "=== Starting AI Expense Tracker Server Setup ==="

    # Update system
    apt-get update -y
    apt-get upgrade -y

    # Install essential tools
    apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg \
      lsb-release \
      software-properties-common \
      ufw \
      fail2ban \
      unzip \
      git \
      jq

    # ---- Install Docker ----
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker ubuntu
    systemctl enable docker
    systemctl start docker

    # ---- Install Docker Compose Plugin ----
    apt-get install -y docker-compose-plugin

    # Also install standalone docker-compose for compatibility
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # ---- Install Certbot (Let's Encrypt) ----
    apt-get install -y certbot

    # ---- Configure UFW Firewall ----
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp    # SSH
    ufw allow 80/tcp    # HTTP
    ufw allow 443/tcp   # HTTPS
    ufw allow 8000/tcp  # FastAPI (temporary, remove after nginx is set up)
    ufw allow 3000/tcp  # Frontend (temporary)
    ufw allow 3001/tcp  # Grafana
    ufw allow 9090/tcp  # Prometheus
    ufw --force enable

    # ---- Configure Fail2Ban ----
    systemctl enable fail2ban
    systemctl start fail2ban

    # ---- Create application directory ----
    mkdir -p /opt/expense-tracker
    chown ubuntu:ubuntu /opt/expense-tracker

    # ---- Create swap file (important for t2.micro with 1GB RAM) ----
    if [ ! -f /swapfile ]; then
      fallocate -l 2G /swapfile
      chmod 600 /swapfile
      mkswap /swapfile
      swapon /swapfile
      echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi

    # ---- Set system limits for Docker ----
    cat >> /etc/sysctl.conf <<SYSCTL
    vm.swappiness=10
    vm.max_map_count=262144
    net.core.somaxconn=65535
    SYSCTL
    sysctl -p

    echo "=== Server Setup Complete ==="
    echo "=== Ready for application deployment ==="
  EOF

  tags = {
    Name        = "${var.project_name}-single-server"
    Role        = "all-in-one"
    Environment = var.environment
  }
}

# ---- Elastic IP for the single server ----
resource "aws_eip" "single_server" {
  count    = var.single_instance_mode ? 1 : 0
  instance = aws_instance.single_server[0].id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-single-eip"
  }
}

# ---- Variables for single-instance mode ----
variable "single_instance_mode" {
  description = "Enable single-instance deployment (cost-optimized)"
  type        = bool
  default     = false
}

variable "single_instance_type" {
  description = "Instance type for single-server deployment"
  type        = string
  default     = "t2.small"
}

variable "single_instance_volume_size" {
  description = "Root EBS volume size in GB for single server"
  type        = number
  default     = 30
}

# ---- Outputs for single-instance mode ----
output "single_server_public_ip" {
  description = "Public IP of the single all-in-one server"
  value       = var.single_instance_mode ? aws_eip.single_server[0].public_ip : "N/A (multi-server mode)"
}

output "single_server_ssh" {
  description = "SSH command for the single server"
  value       = var.single_instance_mode ? "ssh -i ${var.key_pair_name}.pem ubuntu@${aws_eip.single_server[0].public_ip}" : "N/A"
}

output "single_server_app_url" {
  description = "Application URL (single-server mode)"
  value       = var.single_instance_mode ? "http://${aws_eip.single_server[0].public_ip}" : "N/A"
}

output "single_server_nip_url" {
  description = "Application URL via nip.io (single-server mode)"
  value       = var.single_instance_mode ? "http://${replace(aws_eip.single_server[0].public_ip, ".", "-")}.nip.io" : "N/A"
}

output "single_server_grafana_url" {
  description = "Grafana URL (single-server mode)"
  value       = var.single_instance_mode ? "http://${aws_eip.single_server[0].public_ip}:3001" : "N/A"
}

output "single_server_prometheus_url" {
  description = "Prometheus URL (single-server mode)"
  value       = var.single_instance_mode ? "http://${aws_eip.single_server[0].public_ip}:9090" : "N/A"
}
