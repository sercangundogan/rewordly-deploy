#!/bin/bash

# Troubleshooting script for 502 Bad Gateway error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Troubleshooting 502 Bad Gateway Error${NC}"
echo ""

# 1. Check if containers are running
echo -e "${YELLOW}1. Checking container status...${NC}"
docker ps --filter "name=rewordly" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 2. Check rewordly-web container specifically
echo -e "${YELLOW}2. Checking rewordly-web container...${NC}"
if docker ps | grep -q rewordly-web; then
    echo -e "${GREEN}✓ rewordly-web container is running${NC}"
    
    # Check if it's healthy
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' rewordly-web 2>/dev/null || echo "no-healthcheck")
    echo -e "Health status: ${HEALTH}"
    
    # Check logs
    echo -e "\n${YELLOW}Recent logs from rewordly-web:${NC}"
    docker logs --tail=50 rewordly-web
else
    echo -e "${RED}✗ rewordly-web container is NOT running${NC}"
    echo -e "${YELLOW}Checking if it exists but stopped...${NC}"
    docker ps -a | grep rewordly-web
fi
echo ""

# 3. Test connectivity from nginx to rewordly-web
echo -e "${YELLOW}3. Testing connectivity from nginx to rewordly-web...${NC}"
docker exec rewordly-nginx wget -q -O- http://rewordly-web:3000 2>&1 | head -20 || echo -e "${RED}✗ Cannot connect to rewordly-web:3000 from nginx${NC}"
echo ""

# 4. Check nginx logs
echo -e "${YELLOW}4. Checking nginx error logs...${NC}"
docker logs --tail=50 rewordly-nginx 2>&1 | grep -i error || echo "No errors found in recent logs"
echo ""

# 5. Check network connectivity
echo -e "${YELLOW}5. Checking network connectivity...${NC}"
docker network inspect rewordly-deploy_rewordly-network 2>/dev/null | grep -A 5 "Containers" || docker network inspect rewordly_rewordly-network 2>/dev/null | grep -A 5 "Containers"
echo ""

# 6. Check if port 3000 is listening in rewordly-web
echo -e "${YELLOW}6. Checking if port 3000 is listening in rewordly-web...${NC}"
docker exec rewordly-web netstat -tlnp 2>/dev/null | grep 3000 || docker exec rewordly-web ss -tlnp 2>/dev/null | grep 3000 || echo -e "${RED}✗ Port 3000 is not listening${NC}"
echo ""

# 7. Try to access rewordly-web directly
echo -e "${YELLOW}7. Testing direct access to rewordly-web:3000...${NC}"
docker exec rewordly-web wget -q -O- http://localhost:3000 2>&1 | head -10 || echo -e "${RED}✗ Cannot access rewordly-web internally${NC}"
echo ""

echo -e "${BLUE}📋 Summary:${NC}"
echo "If rewordly-web is not running or not healthy, try:"
echo "  docker-compose logs rewordly-web"
echo "  docker-compose restart rewordly-web"
echo "  docker-compose up -d --build rewordly-web"

