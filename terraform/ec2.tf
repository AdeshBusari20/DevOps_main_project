# ==============================================
# EC2 Instances
# ==============================================

# Get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---- Application Server ----
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  # User data script - runs on first boot
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system
    apt-get update -y
    apt-get upgrade -y

    # Install Docker
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker ubuntu
    systemctl enable docker
    systemctl start docker

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/

    # Install Trivy
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

    echo "=== Setup complete ==="
  EOF

  tags = {
    Name = "${var.project_name}-app-server"
    Role = "application"
  }
}

# ---- Jenkins/CI Server ----
resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y

    # Install Java (Jenkins requirement)
    apt-get install -y fontconfig openjdk-17-jre

    # Install Jenkins
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    apt-get update -y
    apt-get install -y jenkins

    # Install Docker
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker jenkins
    usermod -aG docker ubuntu

    systemctl enable jenkins
    systemctl start jenkins

    echo "=== Jenkins setup complete ==="
  EOF

  tags = {
    Name = "${var.project_name}-jenkins-server"
    Role = "cicd"
  }
}

# ---- Monitoring Server ----
resource "aws_instance" "monitoring_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.small"
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update -y

    # Install Docker
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker ubuntu

    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    echo "=== Monitoring server setup complete ==="
  EOF

  tags = {
    Name = "${var.project_name}-monitoring-server"
    Role = "monitoring"
  }
}
