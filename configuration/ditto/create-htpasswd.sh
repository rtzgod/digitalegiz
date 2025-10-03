#!/bin/bash
# Create htpasswd file for Ditto nginx authentication
# Usage: ./create-htpasswd.sh

# Read credentials from .env file
source ../.env 2>/dev/null || source ../../.env 2>/dev/null || true

# Default credentials if not set in .env
DITTO_USER="${DITTO_USER:-ditto}"
DITTO_PASSWORD="${DITTO_PASSWORD:-ditto}"

# Create htpasswd file using openssl (available in most systems)
echo "Creating nginx.htpasswd file..."
echo "$DITTO_USER:$(openssl passwd -apr1 $DITTO_PASSWORD)" > nginx.htpasswd

echo "Created nginx.htpasswd with user: $DITTO_USER"
echo "You can now start Ditto with: docker-compose -f docker-compose.ditto.yml up -d"
