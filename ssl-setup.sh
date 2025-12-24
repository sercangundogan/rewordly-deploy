#!/bin/bash

# SSL Certificate Setup Script for Rewordly
# Creates self-signed certificate for IP address

set -e

CERT_DIR="/etc/letsencrypt/live/161.35.153.201"
DOMAIN="161.35.153.201"

echo "🔐 Creating SSL certificate for ${DOMAIN}..."

# Create directory
sudo mkdir -p ${CERT_DIR}

# Generate self-signed certificate
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ${CERT_DIR}/privkey.pem \
  -out ${CERT_DIR}/fullchain.pem \
  -subj "/C=US/ST=State/L=City/O=Rewordly/CN=${DOMAIN}" \
  -addext "subjectAltName=IP:${DOMAIN}"

# Set proper permissions
sudo chmod 600 ${CERT_DIR}/privkey.pem
sudo chmod 644 ${CERT_DIR}/fullchain.pem

echo "✅ SSL certificate created successfully!"
echo "📁 Location: ${CERT_DIR}"
echo ""
echo "⚠️  Note: This is a self-signed certificate. Browsers will show a warning."
echo "   For production, use a domain name with Let's Encrypt."

