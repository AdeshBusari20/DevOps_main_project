#!/bin/bash
# ==============================================
# SSL Certificate Setup - Let's Encrypt
# ==============================================
# Automates SSL certificate provisioning using
# Let's Encrypt Certbot for the Expense Tracker.
#
# Supports:
#   - Custom domain: ./setup-ssl.sh example.com
#   - nip.io domain: ./setup-ssl.sh 54-123-45-67.nip.io
#   - Auto-detect:   ./setup-ssl.sh (uses server public IP + nip.io)
#
# Prerequisites:
#   - Server must be reachable on port 80
#   - DNS must point to this server (or using nip.io)
#   - Run as root or with sudo
#
# Usage: sudo bash scripts/setup-ssl.sh [domain]
# ==============================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}=============================================="
echo "  🔐 SSL Certificate Setup (Let's Encrypt)"
echo "==============================================${NC}"
echo ""

# ---- Determine domain ----
if [ -n "$1" ]; then
    DOMAIN="$1"
else
    # Auto-detect public IP and use nip.io
    echo -e "${YELLOW}No domain specified. Auto-detecting public IP...${NC}"
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com || curl -s http://ifconfig.me)
    if [ -z "$PUBLIC_IP" ]; then
        echo -e "${RED}❌ Could not detect public IP. Please provide domain as argument.${NC}"
        exit 1
    fi
    DOMAIN="${PUBLIC_IP//./-}.nip.io"
    echo -e "${GREEN}✅ Using nip.io domain: ${DOMAIN}${NC}"
fi

echo -e "  Domain: ${CYAN}${DOMAIN}${NC}"
echo ""

# ---- Install Certbot if not present ----
if ! command -v certbot &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Certbot...${NC}"
    apt-get update -y
    apt-get install -y certbot
    echo -e "${GREEN}✅ Certbot installed${NC}"
else
    echo -e "${GREEN}✅ Certbot already installed${NC}"
fi

# ---- Stop nginx temporarily for standalone mode ----
APP_DIR="/opt/expense-tracker"
COMPOSE_FILE="${APP_DIR}/docker-compose.yml"

echo -e "${YELLOW}⏸️  Temporarily stopping nginx for certificate challenge...${NC}"
if [ -f "$COMPOSE_FILE" ]; then
    cd "$APP_DIR"
    docker compose stop nginx 2>/dev/null || true
else
    # Try stopping any nginx container
    docker stop expense-nginx-prod 2>/dev/null || true
    docker stop expense-nginx 2>/dev/null || true
fi

# ---- Obtain SSL Certificate ----
echo -e "${YELLOW}🔑 Requesting SSL certificate from Let's Encrypt...${NC}"
echo ""

certbot certonly \
    --standalone \
    --non-interactive \
    --agree-tos \
    --email "admin@${DOMAIN}" \
    --domain "${DOMAIN}" \
    --preferred-challenges http \
    --http-01-port 80 \
    || {
        echo -e "${RED}❌ Certificate request failed!${NC}"
        echo "   Make sure port 80 is open and DNS points to this server."
        # Restart nginx
        if [ -f "$COMPOSE_FILE" ]; then
            cd "$APP_DIR" && docker compose start nginx 2>/dev/null || true
        fi
        exit 1
    }

echo -e "${GREEN}✅ SSL certificate obtained!${NC}"

# ---- Copy certificates to nginx directory ----
SSL_DIR="${APP_DIR}/nginx/ssl"
mkdir -p "$SSL_DIR"

echo -e "${YELLOW}📋 Copying certificates to nginx directory...${NC}"
cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem "${SSL_DIR}/fullchain.pem"
cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem "${SSL_DIR}/privkey.pem"
chmod 644 "${SSL_DIR}/fullchain.pem"
chmod 600 "${SSL_DIR}/privkey.pem"

echo -e "${GREEN}✅ Certificates copied to ${SSL_DIR}/${NC}"

# ---- Switch nginx to production HTTPS config ----
NGINX_CONF_DIR="${APP_DIR}/nginx/conf.d"
if [ -f "${NGINX_CONF_DIR}/production.conf" ]; then
    echo -e "${YELLOW}🔄 Activating HTTPS nginx configuration...${NC}"
    # Backup current config
    cp "${NGINX_CONF_DIR}/default.conf" "${NGINX_CONF_DIR}/default.conf.http-backup"
    # Activate production HTTPS config
    cp "${NGINX_CONF_DIR}/production.conf" "${NGINX_CONF_DIR}/default.conf"
    echo -e "${GREEN}✅ HTTPS nginx configuration activated${NC}"
fi

# ---- Restart nginx with SSL ----
echo -e "${YELLOW}🔄 Restarting nginx with SSL...${NC}"
if [ -f "$COMPOSE_FILE" ]; then
    cd "$APP_DIR"
    docker compose restart nginx
else
    docker start expense-nginx-prod 2>/dev/null || docker start expense-nginx 2>/dev/null || true
fi

echo -e "${GREEN}✅ Nginx restarted with HTTPS${NC}"

# ---- Setup auto-renewal cron job ----
echo -e "${YELLOW}⏰ Setting up auto-renewal cron job...${NC}"

RENEWAL_SCRIPT="/opt/expense-tracker/scripts/renew-ssl.sh"
mkdir -p "$(dirname "$RENEWAL_SCRIPT")"

cat > "$RENEWAL_SCRIPT" << 'RENEW_EOF'
#!/bin/bash
# SSL Certificate Auto-Renewal Script
set -e
APP_DIR="/opt/expense-tracker"

# Renew certificate
certbot renew --quiet --deploy-hook "
    cp /etc/letsencrypt/live/*/fullchain.pem ${APP_DIR}/nginx/ssl/fullchain.pem
    cp /etc/letsencrypt/live/*/privkey.pem ${APP_DIR}/nginx/ssl/privkey.pem
    cd ${APP_DIR} && docker compose restart nginx
"
RENEW_EOF

chmod +x "$RENEWAL_SCRIPT"

# Add cron job (runs twice daily as recommended by Let's Encrypt)
CRON_JOB="0 0,12 * * * /opt/expense-tracker/scripts/renew-ssl.sh >> /var/log/ssl-renewal.log 2>&1"
(crontab -l 2>/dev/null | grep -v "renew-ssl.sh"; echo "$CRON_JOB") | crontab -

echo -e "${GREEN}✅ Auto-renewal cron job configured (runs twice daily)${NC}"

# ---- Display results ----
echo ""
echo -e "${CYAN}=============================================="
echo "  🎉 SSL Setup Complete!"
echo "==============================================${NC}"
echo ""
echo -e "  Domain:       ${GREEN}${DOMAIN}${NC}"
echo -e "  HTTPS URL:    ${GREEN}https://${DOMAIN}${NC}"
echo -e "  API Docs:     ${GREEN}https://${DOMAIN}/docs${NC}"
echo -e "  Certificate:  ${SSL_DIR}/fullchain.pem"
echo -e "  Private Key:  ${SSL_DIR}/privkey.pem"
echo -e "  Auto-Renewal: Enabled (twice daily)"
echo ""
echo -e "  Cert Expiry:  $(openssl x509 -enddate -noout -in ${SSL_DIR}/fullchain.pem 2>/dev/null || echo 'Check manually')"
echo ""
echo -e "${CYAN}==============================================${NC}"
