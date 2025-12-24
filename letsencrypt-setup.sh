#!/bin/bash

# Let's Encrypt SSL Certificate Setup with Auto-Renewal
# For domain: rewordly.store

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DOMAIN="rewordly.store"
EMAIL="${SSL_EMAIL:-admin@rewordly.store}"  # Change this to your email

echo -e "${GREEN}🔐 Let's Encrypt SSL Certificate Setup${NC}"
echo -e "Domain: ${DOMAIN}"
echo -e "Email: ${EMAIL}"
echo ""

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo -e "${YELLOW}📦 Installing certbot...${NC}"
    sudo apt-get update
    sudo apt-get install -y certbot
else
    echo -e "${GREEN}✅ Certbot already installed${NC}"
fi

echo ""

# Check DNS resolution
echo -e "${YELLOW}🔍 Checking DNS resolution...${NC}"
if nslookup ${DOMAIN} | grep -q "161.35.153.201"; then
    echo -e "${GREEN}✅ DNS is correctly configured${NC}"
else
    echo -e "${RED}❌ DNS is not pointing to 161.35.153.201${NC}"
    echo -e "${YELLOW}Please wait for DNS propagation (5-30 minutes)${NC}"
    echo -e "${YELLOW}Or check your DNS settings in GoDaddy${NC}"
    exit 1
fi

echo ""

# Stop nginx temporarily (required for standalone mode)
echo -e "${YELLOW}🛑 Stopping nginx temporarily...${NC}"
cd /root/rewordly/rewordly-deploy
docker compose stop nginx || true

# Wait a bit for ports to be free
sleep 2

# Obtain certificate
echo -e "${YELLOW}📜 Obtaining SSL certificate...${NC}"
sudo certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email ${EMAIL} \
    -d ${DOMAIN} \
    -d www.${DOMAIN} \
    --preferred-challenges http

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSL certificate obtained successfully!${NC}"
else
    echo -e "${RED}❌ Failed to obtain certificate${NC}"
    docker compose start nginx || true
    exit 1
fi

# Set proper permissions
echo -e "${YELLOW}🔒 Setting certificate permissions...${NC}"
sudo chmod 644 /etc/letsencrypt/live/${DOMAIN}/fullchain.pem
sudo chmod 600 /etc/letsencrypt/live/${DOMAIN}/privkey.pem

# Start nginx
echo -e "${YELLOW}🚀 Starting nginx...${NC}"
docker compose start nginx

# Wait for nginx to start
sleep 3

# Test nginx config
echo -e "${YELLOW}🧪 Testing nginx configuration...${NC}"
if docker compose exec nginx nginx -t 2>/dev/null; then
    echo -e "${GREEN}✅ Nginx configuration is valid${NC}"
else
    echo -e "${RED}❌ Nginx configuration has errors${NC}"
    docker compose logs nginx | tail -20
    exit 1
fi

echo ""

# Setup auto-renewal cron job
echo -e "${YELLOW}⏰ Setting up auto-renewal...${NC}"

# Create renewal script
sudo tee /usr/local/bin/rewordly-ssl-renew.sh > /dev/null << 'EOF'
#!/bin/bash
# Let's Encrypt SSL renewal script for Rewordly

cd /root/rewordly/rewordly-deploy

# Stop nginx
docker compose stop nginx

# Renew certificate
certbot renew --standalone --non-interactive

# Start nginx
docker compose start nginx

# Reload nginx to use new certificate
docker compose exec nginx nginx -s reload
EOF

sudo chmod +x /usr/local/bin/rewordly-ssl-renew.sh

# Add cron job (runs twice daily, Let's Encrypt checks 30 days before expiry)
(crontab -l 2>/dev/null | grep -v "rewordly-ssl-renew"; echo "0 3,15 * * * /usr/local/bin/rewordly-ssl-renew.sh >> /var/log/rewordly-ssl-renew.log 2>&1") | crontab -

echo -e "${GREEN}✅ Auto-renewal cron job added${NC}"
echo -e "${YELLOW}   Certificate will be renewed automatically twice daily${NC}"

echo ""

# Test SSL
echo -e "${YELLOW}🧪 Testing SSL certificate...${NC}"
if curl -I https://${DOMAIN} 2>&1 | grep -q "HTTP"; then
    echo -e "${GREEN}✅ HTTPS is working!${NC}"
else
    echo -e "${YELLOW}⚠️  HTTPS test inconclusive (may need DNS propagation)${NC}"
fi

echo ""
echo -e "${GREEN}✅ SSL Setup Complete!${NC}"
echo -e "${GREEN}📡 WebSocket endpoint: wss://${DOMAIN}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Wait for DNS propagation (if needed)"
echo -e "2. Test: curl -I https://${DOMAIN}"
echo -e "3. Update extension to use wss://${DOMAIN}"
echo ""
echo -e "${YELLOW}Certificate location:${NC}"
echo -e "  /etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
echo -e "  /etc/letsencrypt/live/${DOMAIN}/privkey.pem"
echo ""
echo -e "${YELLOW}Auto-renewal:${NC}"
echo -e "  Cron job runs daily at 3:00 AM and 3:00 PM"
echo -e "  Logs: /var/log/rewordly-ssl-renew.log"

