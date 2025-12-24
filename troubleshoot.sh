#!/bin/bash

# Troubleshooting script for Rewordly WebSocket connection issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔍 Rewordly Troubleshooting${NC}"
echo ""

# Check Docker services
echo -e "${YELLOW}1. Checking Docker services...${NC}"
if command -v docker compose &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}❌ docker compose not found!${NC}"
    exit 1
fi

echo -e "${YELLOW}Service status:${NC}"
$DOCKER_COMPOSE ps

echo ""

# Check SSL certificates
echo -e "${YELLOW}2. Checking SSL certificates...${NC}"
if [ -f "/etc/letsencrypt/live/161.35.153.201/fullchain.pem" ]; then
    echo -e "${GREEN}✅ SSL certificate found${NC}"
    sudo openssl x509 -in /etc/letsencrypt/live/161.35.153.201/fullchain.pem -noout -subject -dates
else
    echo -e "${RED}❌ SSL certificate NOT found!${NC}"
    echo -e "${YELLOW}Run: sudo ./ssl-setup.sh${NC}"
fi

echo ""

# Check Nginx configuration
echo -e "${YELLOW}3. Checking Nginx configuration...${NC}"
if docker compose exec nginx nginx -t 2>/dev/null; then
    echo -e "${GREEN}✅ Nginx configuration is valid${NC}"
else
    echo -e "${RED}❌ Nginx configuration has errors!${NC}"
    docker compose exec nginx nginx -t
fi

echo ""

# Check ports (on host, not in container)
echo -e "${YELLOW}4. Checking ports...${NC}"
if ss -tuln 2>/dev/null | grep -q ":443 " || netstat -tuln 2>/dev/null | grep -q ":443 "; then
    echo -e "${GREEN}✅ Port 443 is listening${NC}"
else
    # Check via docker port mapping
    if docker compose ps nginx 2>/dev/null | grep -q "443"; then
        echo -e "${GREEN}✅ Port 443 is mapped (checking via Docker)${NC}"
    else
        echo -e "${YELLOW}⚠️  Port 443 check inconclusive (check manually: ss -tuln | grep 443)${NC}"
    fi
fi

if ss -tuln 2>/dev/null | grep -q ":80 " || netstat -tuln 2>/dev/null | grep -q ":80 "; then
    echo -e "${GREEN}✅ Port 80 is listening${NC}"
else
    # Check via docker port mapping
    if docker compose ps nginx 2>/dev/null | grep -q "80"; then
        echo -e "${GREEN}✅ Port 80 is mapped (checking via Docker)${NC}"
    else
        echo -e "${YELLOW}⚠️  Port 80 check inconclusive (check manually: ss -tuln | grep 80)${NC}"
    fi
fi

echo ""

# Check WebSocket server
echo -e "${YELLOW}5. Checking WebSocket server...${NC}"
if docker compose exec rewordly-server node -e "const ws = require('ws'); const client = new ws.WebSocket('ws://localhost:8081'); client.on('open', () => { client.close(); process.exit(0); }); client.on('error', () => process.exit(1)); setTimeout(() => process.exit(1), 5000);" 2>/dev/null; then
    echo -e "${GREEN}✅ WebSocket server is responding${NC}"
else
    echo -e "${RED}❌ WebSocket server is NOT responding!${NC}"
fi

echo ""

# Check Nginx logs
echo -e "${YELLOW}6. Recent Nginx logs:${NC}"
docker compose logs --tail=20 nginx

echo ""

# Check WebSocket server logs
echo -e "${YELLOW}7. Recent WebSocket server logs:${NC}"
docker compose logs --tail=20 rewordly-server

echo ""

# Test WSS connection
echo -e "${YELLOW}8. Testing WSS connection...${NC}"
if command -v curl &> /dev/null; then
    if curl -k -I https://161.35.153.201 2>&1 | grep -q "HTTP"; then
        echo -e "${GREEN}✅ HTTPS connection works${NC}"
    else
        echo -e "${RED}❌ HTTPS connection failed!${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  curl not found, skipping HTTPS test${NC}"
fi

echo ""
echo -e "${GREEN}✅ Troubleshooting complete!${NC}"

