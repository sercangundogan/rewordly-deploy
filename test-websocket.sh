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

# Test 2: WebSocket connection (using Node.js)
echo -e "${YELLOW}2. Testing WebSocket connection (WSS)...${NC}"
if command -v node &> /dev/null; then
    node << 'EOF'
const WebSocket = require('ws');

const ws = new WebSocket('wss://161.35.153.201', {
    rejectUnauthorized: false // Accept self-signed certificate
});

const timeout = setTimeout(() => {
    console.log('❌ Connection timeout');
    ws.close();
    process.exit(1);
}, 5000);

ws.on('open', () => {
    console.log('✅ WebSocket connected!');
    clearTimeout(timeout);
    
    // Send a test message
    const testMessage = {
        id: 'test-' + Date.now(),
        type: 'grammar_check',
        text: 'Hello world'
    };
    
    ws.send(JSON.stringify(testMessage));
    
    setTimeout(() => {
        ws.close();
        process.exit(0);
    }, 2000);
});

ws.on('message', (data) => {
    try {
        const message = JSON.parse(data.toString());
        console.log('📨 Received message:', message.type);
        if (message.type === 'grammar_check_response') {
            console.log('✅ Grammar check response received!');
        }
    } catch (e) {
        console.log('📨 Received:', data.toString());
    }
});

ws.on('error', (error) => {
    console.log('❌ WebSocket error:', error.message);
    clearTimeout(timeout);
    process.exit(1);
});

ws.on('close', () => {
    console.log('🔌 WebSocket closed');
});
EOF
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

