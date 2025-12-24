// Test WebSocket connection exactly like the extension does
// Run: node test-extension-connection.js

const WebSocket = require('ws');

const WS_URL = 'wss://161.35.153.201';

console.log('🔌 Connecting to:', WS_URL);
console.log('📋 This simulates the extension connection...\n');

const ws = new WebSocket(WS_URL, {
  // Chrome extension doesn't set rejectUnauthorized, but Node.js does by default
  // For self-signed cert, we need to accept it
  rejectUnauthorized: false
});

let connected = false;
let messageReceived = false;

const timeout = setTimeout(() => {
  if (!connected) {
    console.log('❌ Connection timeout (5 seconds)');
    process.exit(1);
  } else if (!messageReceived) {
    console.log('⚠️  Connected but no message received');
    process.exit(0);
  }
}, 5000);

ws.on('open', () => {
  connected = true;
  console.log('✅ WebSocket connected!');
  console.log('📤 Sending grammar check request...\n');
  
  // Send exactly what extension sends
  const grammarCheckMessage = {
    id: `test-${Date.now()}`,
    type: 'grammar_check',
    text: 'Hello world. This is a test.',
    mode: 'default'
  };
  
  console.log('📨 Sending:', JSON.stringify(grammarCheckMessage, null, 2));
  ws.send(JSON.stringify(grammarCheckMessage));
});

ws.on('message', (data) => {
  messageReceived = true;
  try {
    const message = JSON.parse(data.toString());
    console.log('📥 Received message:');
    console.log(JSON.stringify(message, null, 2));
    
    if (message.type === 'grammar_check_response') {
      console.log('\n✅ Grammar check response received!');
      console.log(`   Errors found: ${message.errors?.length || 0}`);
      if (message.errors && message.errors.length > 0) {
        console.log('   First error:', message.errors[0]);
      }
    } else if (message.type === 'connected') {
      console.log('✅ Server confirmed connection');
    } else if (message.type === 'error') {
      console.log('❌ Server error:', message.message);
    }
    
    clearTimeout(timeout);
    setTimeout(() => {
      ws.close();
      process.exit(0);
    }, 1000);
  } catch (e) {
    console.log('📥 Received (non-JSON):', data.toString());
  }
});

ws.on('error', (error) => {
  console.log('❌ WebSocket error:');
  console.log('   Message:', error.message);
  console.log('   Code:', error.code);
  console.log('   Stack:', error.stack);
  clearTimeout(timeout);
  process.exit(1);
});

ws.on('close', (code, reason) => {
  console.log('\n🔌 WebSocket closed');
  console.log('   Code:', code);
  console.log('   Reason:', reason?.toString() || 'No reason');
  clearTimeout(timeout);
  if (!connected) {
    process.exit(1);
  }
});

// Handle process termination
process.on('SIGINT', () => {
  console.log('\n\n⚠️  Interrupted by user');
  ws.close();
  process.exit(0);
});

