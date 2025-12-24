#!/bin/bash

# Rewordly Deployment Script
# Pulls latest code and starts services via Docker Compose

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SERVER_HOST="${DEPLOY_HOST:-161.35.153.201}"
SERVER_USER="${DEPLOY_USER:-root}"
REWORDLY_DIR="${REWORDLY_DIR:-/root/rewordly}"

echo -e "${GREEN}🚀 Starting Rewordly Deployment${NC}"
echo -e "Server: ${SERVER_USER}@${SERVER_HOST}"
echo -e "Target directory: ${REWORDLY_DIR}"
echo ""

# SSH command - using here-doc with variable expansion
ssh ${SERVER_USER}@${SERVER_HOST} bash << EOF
set -e

REWORDLY_DIR="${REWORDLY_DIR}"
REWORDLY_SERVER_DIR="\${REWORDLY_DIR}/rewordly-server"
REWORDLY_DEPLOY_DIR="\${REWORDLY_DIR}/rewordly-deploy"

echo "📦 Pulling latest code..."

# Create directory if it doesn't exist
mkdir -p \${REWORDLY_DIR}
cd \${REWORDLY_DIR}

# Clone or update rewordly-server
if [ -d "\${REWORDLY_SERVER_DIR}" ]; then
    echo "Updating rewordly-server..."
    cd \${REWORDLY_SERVER_DIR}
    git pull origin main || git pull origin master
else
    echo "Cloning rewordly-server..."
    git clone https://github.com/sercangundogan/rewordly-server.git \${REWORDLY_SERVER_DIR}
    cd \${REWORDLY_SERVER_DIR}
fi

# Clone or update rewordly-deploy
if [ -d "\${REWORDLY_DEPLOY_DIR}" ]; then
    echo "Updating rewordly-deploy..."
    cd \${REWORDLY_DEPLOY_DIR}
    git pull origin main || git pull origin master
else
    echo "Cloning rewordly-deploy..."
    git clone https://github.com/sercangundogan/rewordly-deploy.git \${REWORDLY_DEPLOY_DIR}
    cd \${REWORDLY_DEPLOY_DIR}
fi

echo "✅ Code updated"
echo ""

# Check if .env exists
if [ ! -f "\${REWORDLY_DEPLOY_DIR}/.env" ]; then
    echo "⚠️  .env file not found. Creating from example..."
    cp \${REWORDLY_DEPLOY_DIR}/env.example \${REWORDLY_DEPLOY_DIR}/.env
    echo "⚠️  Please edit .env file and add OPENAI_API_KEY before starting services!"
    exit 1
fi

echo "🐳 Starting Docker services..."
cd \${REWORDLY_DEPLOY_DIR}

# Stop existing containers
echo "Stopping existing containers..."
docker-compose down || true

# Build and start services
echo "Building and starting services..."
docker-compose up -d --build

# Wait a bit for services to start
sleep 5

# Check service status
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "✅ Deployment completed!"
echo "📡 WebSocket Server: wss://161.35.153.201"
echo "🔍 LanguageTool: http://161.35.153.201:8010"

# Show logs
echo ""
echo "Recent logs:"
docker-compose logs --tail=20
EOF

echo ""
echo -e "${GREEN}✅ Deployment script completed!${NC}"
