#!/bin/bash

# Docker Cleanup Script for Rewordly
# Removes unused Docker resources to free up disk space

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Docker Cleanup Script${NC}"
echo ""

# Check disk usage before cleanup
echo -e "${YELLOW}📊 Disk Usage Before Cleanup:${NC}"
docker system df
echo ""

# Ask for confirmation
read -p "Do you want to proceed with cleanup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Cleanup cancelled.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Starting cleanup...${NC}"
echo ""

# 1. Remove stopped containers
echo -e "${YELLOW}1. Removing stopped containers...${NC}"
docker container prune -f
echo ""

# 2. Remove unused images (not used by any container)
echo -e "${YELLOW}2. Removing unused images...${NC}"
docker image prune -f
echo ""

# 3. Remove unused volumes (be careful - this removes data!)
echo -e "${YELLOW}3. Removing unused volumes...${NC}"
read -p "Remove unused volumes? This will delete data! (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker volume prune -f
else
    echo -e "${BLUE}Skipping volume cleanup.${NC}"
fi
echo ""

# 4. Remove unused networks
echo -e "${YELLOW}4. Removing unused networks...${NC}"
docker network prune -f
echo ""

# 5. Remove build cache (frees up significant space)
echo -e "${YELLOW}5. Removing build cache...${NC}"
docker builder prune -f
echo ""

# 6. Complete system cleanup (all of the above in one command)
echo -e "${YELLOW}6. Running complete system cleanup...${NC}"
read -p "Run complete system cleanup (removes all unused resources)? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker system prune -a -f --volumes
else
    echo -e "${BLUE}Skipping complete cleanup.${NC}"
fi
echo ""

# Check disk usage after cleanup
echo -e "${GREEN}📊 Disk Usage After Cleanup:${NC}"
docker system df
echo ""

echo -e "${GREEN}✅ Cleanup completed!${NC}"

