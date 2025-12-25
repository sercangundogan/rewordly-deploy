#!/bin/bash

# Rewordly Deployment Script
# Pulls latest code and starts services via Docker Compose
# Run this script directly on the server

# Make this script executable (if not already)
chmod +x "$0" 2>/dev/null || true

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REWORDLY_DIR="${REWORDLY_DIR:-/root/rewordly}"
REWORDLY_SERVER_DIR="${REWORDLY_DIR}/rewordly-server"
REWORDLY_WEB_DIR="${REWORDLY_DIR}/rewordly-web"
REWORDLY_DEPLOY_DIR="${REWORDLY_DIR}/rewordly-deploy"

echo -e "${GREEN}🚀 Starting Rewordly Deployment${NC}"
echo -e "Target directory: ${REWORDLY_DIR}"
echo ""

echo -e "${GREEN}📦 Pulling latest code...${NC}"

# Create directory if it doesn't exist
mkdir -p ${REWORDLY_DIR}
cd ${REWORDLY_DIR}

# Configure git to ignore file mode changes (prevents chmod issues)
git config core.fileMode false || true

# Clone or update rewordly-server
if [ -d "${REWORDLY_SERVER_DIR}" ]; then
    echo -e "${YELLOW}Updating rewordly-server...${NC}"
    cd ${REWORDLY_SERVER_DIR}
    # Ignore file mode changes to prevent chmod conflicts
    git config core.fileMode false || true
    # Reset any file mode changes
    git checkout . 2>/dev/null || true
    git pull origin main || git pull origin master
else
    echo -e "${YELLOW}Cloning rewordly-server...${NC}"
    git clone https://github.com/sercangundogan/rewordly-server.git ${REWORDLY_SERVER_DIR}
    cd ${REWORDLY_SERVER_DIR}
fi

# Clone or update rewordly-web
if [ -d "${REWORDLY_WEB_DIR}" ]; then
    echo -e "${YELLOW}Updating rewordly-web...${NC}"
    cd ${REWORDLY_WEB_DIR}
    # Ignore file mode changes to prevent chmod conflicts
    git config core.fileMode false || true
    # Reset any file mode changes
    git checkout . 2>/dev/null || true
    git pull origin main || git pull origin master
else
    echo -e "${YELLOW}Cloning rewordly-web...${NC}"
    git clone https://github.com/sercangundogan/rewordly-web.git ${REWORDLY_WEB_DIR}
    cd ${REWORDLY_WEB_DIR}
fi

# Clone or update rewordly-deploy
if [ -d "${REWORDLY_DEPLOY_DIR}" ]; then
    echo -e "${YELLOW}Updating rewordly-deploy...${NC}"
    cd ${REWORDLY_DEPLOY_DIR}
    # Ignore file mode changes to prevent chmod conflicts
    git config core.fileMode false || true
    # Reset any file mode changes
    git checkout . 2>/dev/null || true
    git pull origin main || git pull origin master
    # Ensure deploy.sh is executable after pull
    chmod +x deploy.sh 2>/dev/null || true
else
    echo -e "${YELLOW}Cloning rewordly-deploy...${NC}"
    git clone https://github.com/sercangundogan/rewordly-deploy.git ${REWORDLY_DEPLOY_DIR}
    cd ${REWORDLY_DEPLOY_DIR}
fi

echo -e "${GREEN}✅ Code updated${NC}"
echo ""

# Check if .env exists
if [ ! -f "${REWORDLY_DEPLOY_DIR}/.env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Creating from example...${NC}"
    cp ${REWORDLY_DEPLOY_DIR}/env.example ${REWORDLY_DEPLOY_DIR}/.env
    echo -e "${RED}⚠️  Please edit .env file and add OPENAI_API_KEY before starting services!${NC}"
    exit 1
fi

echo -e "${GREEN}🐳 Starting Docker services...${NC}"
cd ${REWORDLY_DEPLOY_DIR}

# Detect docker compose command (docker compose or docker-compose)
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}❌ Error: docker compose or docker-compose not found!${NC}"
    exit 1
fi

echo -e "${YELLOW}Using: ${DOCKER_COMPOSE}${NC}"

# Stop existing containers
echo -e "${YELLOW}Stopping existing containers...${NC}"
${DOCKER_COMPOSE} down || true

# Build and start services
echo -e "${YELLOW}Building and starting services...${NC}"
${DOCKER_COMPOSE} up -d --build

# Wait a bit for services to start
sleep 5

# Check service status
echo -e "${GREEN}📊 Service Status:${NC}"
${DOCKER_COMPOSE} ps

echo ""
echo -e "${GREEN}✅ Deployment completed!${NC}"
echo -e "${GREEN}🌐 Web App: https://rewordly.store${NC}"
echo -e "${GREEN}📡 WebSocket Server: wss://rewordly.store${NC}"
echo -e "${GREEN}🔍 LanguageTool: http://161.35.153.201:8010${NC}"

# Show logs
echo ""
echo -e "${YELLOW}Recent logs:${NC}"
${DOCKER_COMPOSE} logs --tail=20
