#!/bin/bash

# Test WebSocket connection via WSS

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🧪 Testing WebSocket Connection${NC}"
echo ""

# Test 1: HTTPS connection
echo -e "${YELLOW}1. Testing HTTPS connection...${NC}"
if curl -k -I https://161.35.153.201 2>&1 | grep -q "HTTP"; then
    echo -e "${GREEN}✅ HTTPS works${NC}"
else
    echo -e "${RED}❌ HTTPS failed${NC}"
fi

echo ""

# Test 2: WebSocket connection (exactly like extension)
echo -e "${YELLOW}2. Testing WebSocket connection (WSS) - Extension style...${NC}"
if command -v node &> /dev/null; then
    if [ -f "test-extension-connection.js" ]; then
        node test-extension-connection.js
    else
        echo -e "${RED}❌ test-extension-connection.js not found${NC}"
        echo -e "${YELLOW}   Using inline test instead...${NC}"
        node << 'EOF'
const WebSocket = require('ws');
const ws = new WebSocket('wss://161.35.153.201', { rejectUnauthorized: false });
const timeout = setTimeout(() => { console.log('❌ Timeout'); ws.close(); process.exit(1); }, 5000);
ws.on('open', () => {
    console.log('✅ Connected!');
    ws.send(JSON.stringify({ id: 'test-' + Date.now(), type: 'grammar_check', text: 'Hello world', mode: 'default' }));
});
ws.on('message', (d) => { console.log('📥', JSON.parse(d.toString()).type); clearTimeout(timeout); setTimeout(() => { ws.close(); process.exit(0); }, 1000); });
ws.on('error', (e) => { console.log('❌', e.message); clearTimeout(timeout); process.exit(1); });
EOF
    fi
else
    echo -e "${RED}❌ Node.js not found. Install Node.js to test WebSocket.${NC}"
fi

echo ""

# Test 3: Check Nginx access logs
echo -e "${YELLOW}3. Recent Nginx access logs:${NC}"
docker compose logs --tail=10 nginx 2>/dev/null | grep -E "(GET|POST|WebSocket|upgrade)" || echo "No access logs found"

echo ""

# Test 4: Check if WebSocket upgrade is working
echo -e "${YELLOW}4. Testing WebSocket upgrade headers...${NC}"
curl -k -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  https://161.35.153.201 2>&1 | head -20

echo ""
echo -e "${GREEN}✅ Test complete!${NC}"

