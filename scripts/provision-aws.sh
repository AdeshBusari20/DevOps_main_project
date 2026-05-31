#!/bin/bash
# ==============================================
# AWS Infrastructure Provisioning Script
# ==============================================
# Automates the complete AWS provisioning flow:
#   1. Creates EC2 key pair
#   2. Runs Terraform init/plan/apply
#   3. Waits for server to be ready
#   4. Runs Ansible playbooks
#   5. Deploys the application
#
# Prerequisites:
#   - AWS CLI configured (aws configure)
#   - Terraform >= 1.5.0
#   - Ansible >= 2.15 (optional, for automated config)
#
# Usage: bash scripts/provision-aws.sh
# ==============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

TERRAFORM_DIR="terraform"
ANSIBLE_DIR="ansible"
KEY_NAME="expense-tracker-key"
REGION="ap-south-1"

echo ""
echo -e "${CYAN}${BOLD}=============================================="
echo "  ☁️  AWS Infrastructure Provisioning"
echo "  AI Expense Tracker - Option A (Single EC2)"
echo "==============================================${NC}"
echo ""

# ---- Step 1: Check prerequisites ----
echo -e "${YELLOW}[1/7] Checking prerequisites...${NC}"

check_cmd() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed. Please install it first.${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}✅ $1 $(${1} --version 2>&1 | head -1)${NC}"
}

check_cmd aws
check_cmd terraform

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Run 'aws configure' first.${NC}"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo -e "  ${GREEN}✅ AWS Account: ${AWS_ACCOUNT}${NC}"
echo -e "  ${GREEN}✅ Region: ${REGION}${NC}"

# ---- Step 2: Create EC2 Key Pair ----
echo ""
echo -e "${YELLOW}[2/7] Creating EC2 Key Pair...${NC}"

KEY_FILE="${HOME}/.ssh/${KEY_NAME}.pem"

if [ -f "$KEY_FILE" ]; then
    echo -e "  ${GREEN}✅ Key pair file already exists: ${KEY_FILE}${NC}"
else
    # Check if key pair exists in AWS
    if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &> /dev/null; then
        echo -e "  ${YELLOW}⚠️  Key pair exists in AWS but local .pem file is missing.${NC}"
        echo -e "  ${YELLOW}   Delete the AWS key pair and re-run, or provide the .pem file.${NC}"
        echo -e "  ${YELLOW}   To delete: aws ec2 delete-key-pair --key-name ${KEY_NAME} --region ${REGION}${NC}"
        exit 1
    fi

    # Create new key pair
    mkdir -p "${HOME}/.ssh"
    aws ec2 create-key-pair \
        --key-name "$KEY_NAME" \
        --region "$REGION" \
        --query 'KeyMaterial' \
        --output text > "$KEY_FILE"

    chmod 400 "$KEY_FILE"
    echo -e "  ${GREEN}✅ Key pair created: ${KEY_FILE}${NC}"
fi

# ---- Step 3: Get user's public IP for SSH restriction ----
echo ""
echo -e "${YELLOW}[3/7] Detecting your public IP for SSH access...${NC}"

MY_IP=$(curl -s http://checkip.amazonaws.com)
echo -e "  ${GREEN}✅ Your IP: ${MY_IP}${NC}"

# ---- Step 4: Initialize Terraform ----
echo ""
echo -e "${YELLOW}[4/7] Initializing Terraform...${NC}"

cd "$TERRAFORM_DIR"

# Create tfvars from single-instance template
if [ ! -f "terraform.tfvars" ]; then
    cp terraform.tfvars.single terraform.tfvars
    # Update SSH CIDR with actual IP
    sed -i "s|0.0.0.0/0|${MY_IP}/32|g" terraform.tfvars
    echo -e "  ${GREEN}✅ terraform.tfvars created from single-instance template${NC}"
    echo -e "  ${GREEN}   SSH restricted to your IP: ${MY_IP}/32${NC}"
else
    echo -e "  ${GREEN}✅ terraform.tfvars already exists${NC}"
fi

terraform init

echo -e "  ${GREEN}✅ Terraform initialized${NC}"

# ---- Step 5: Plan and Apply ----
echo ""
echo -e "${YELLOW}[5/7] Planning infrastructure...${NC}"

terraform plan -out=tfplan

echo ""
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${BOLD}Review the plan above.${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo ""
read -p "$(echo -e ${YELLOW}Apply this infrastructure? [y/N]: ${NC})" CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo -e "${RED}❌ Aborted by user.${NC}"
    rm -f tfplan
    exit 0
fi

echo ""
echo -e "${YELLOW}Applying infrastructure...${NC}"
terraform apply tfplan
rm -f tfplan

echo -e "  ${GREEN}✅ Infrastructure provisioned!${NC}"

# ---- Step 6: Get outputs ----
echo ""
echo -e "${YELLOW}[6/7] Retrieving server details...${NC}"

SERVER_IP=$(terraform output -raw single_server_public_ip 2>/dev/null || echo "")

if [ -z "$SERVER_IP" ] || [ "$SERVER_IP" == "N/A (multi-server mode)" ]; then
    # Fallback to multi-server mode outputs
    SERVER_IP=$(terraform output -raw app_server_public_ip 2>/dev/null || echo "UNKNOWN")
fi

echo -e "  ${GREEN}✅ Server IP: ${SERVER_IP}${NC}"

cd ..

# ---- Step 7: Wait for server and deploy ----
echo ""
echo -e "${YELLOW}[7/7] Waiting for server to be ready...${NC}"

echo -n "  Waiting for SSH"
for i in $(seq 1 60); do
    if ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@"$SERVER_IP" "echo ready" &> /dev/null; then
        echo -e " ${GREEN}✅ SSH ready${NC}"
        break
    fi
    echo -n "."
    if [ "$i" -eq 60 ]; then
        echo -e " ${YELLOW}⚠️  Timeout. Server may still be initializing.${NC}"
    fi
    sleep 10
done

# Wait extra time for user-data script to finish
echo -e "  ${YELLOW}Waiting 60s for cloud-init to complete...${NC}"
sleep 60

# ---- Deploy application to server ----
echo ""
echo -e "${CYAN}${BOLD}=============================================="
echo "  📦 Deploying Application to Server"
echo "==============================================${NC}"
echo ""

NIP_DOMAIN="${SERVER_IP//./-}.nip.io"

# Copy deployment files to server
echo -e "${YELLOW}Copying project files to server...${NC}"
scp -i "$KEY_FILE" -o StrictHostKeyChecking=no -r \
    docker-compose.prod.single.yml \
    docker-compose.prod.yml \
    nginx/ \
    monitoring/ \
    scripts/ \
    .env.production.example \
    ubuntu@"$SERVER_IP":/opt/expense-tracker/

# Run deployment script on server
echo -e "${YELLOW}Running deployment script on server...${NC}"
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ubuntu@"$SERVER_IP" \
    "cd /opt/expense-tracker && sudo bash scripts/deploy-production.sh"

# ---- Final output ----
echo ""
echo -e "${CYAN}${BOLD}=============================================="
echo "  🎉 AWS Deployment Complete!"
echo "==============================================${NC}"
echo ""
echo -e "  ${BOLD}Server:${NC}"
echo -e "  ─────────────────────────────────────────"
echo -e "  IP:           ${GREEN}${SERVER_IP}${NC}"
echo -e "  SSH:          ${CYAN}ssh -i ${KEY_FILE} ubuntu@${SERVER_IP}${NC}"
echo -e ""
echo -e "  ${BOLD}Application URLs:${NC}"
echo -e "  ─────────────────────────────────────────"
echo -e "  Frontend:     ${GREEN}http://${SERVER_IP}${NC}"
echo -e "  Frontend:     ${GREEN}http://${NIP_DOMAIN}${NC}"
echo -e "  API Docs:     ${GREEN}http://${SERVER_IP}/docs${NC}"
echo -e ""
echo -e "  ${BOLD}Monitoring:${NC}"
echo -e "  ─────────────────────────────────────────"
echo -e "  Grafana:      ${GREEN}http://${SERVER_IP}:3001${NC}"
echo -e "  Prometheus:   ${GREEN}http://${SERVER_IP}:9090${NC}"
echo -e ""
echo -e "  ${BOLD}Next Steps:${NC}"
echo -e "  ─────────────────────────────────────────"
echo -e "  1. Set up SSL:"
echo -e "     ${CYAN}ssh -i ${KEY_FILE} ubuntu@${SERVER_IP}${NC}"
echo -e "     ${CYAN}sudo bash /opt/expense-tracker/scripts/setup-ssl.sh${NC}"
echo -e ""
echo -e "  2. To destroy infrastructure:"
echo -e "     ${CYAN}cd terraform && terraform destroy${NC}"
echo -e ""
echo -e "${CYAN}==============================================${NC}"
