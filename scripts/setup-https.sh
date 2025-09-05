#!/bin/bash

echo "=== DigitalEgiz HTTPS Setup Script ==="
echo

# Get VPS IP address
echo "🌐 Detecting your VPS IP address..."
VPS_IP=$(curl -s https://ipinfo.io/ip 2>/dev/null || curl -s https://api.ipify.org 2>/dev/null)

if [ -z "$VPS_IP" ]; then
    echo "❌ Could not detect IP address automatically."
    read -p "Please enter your VPS IP address: " VPS_IP
fi

echo "   Detected IP: $VPS_IP"
echo

# Get email for Let's Encrypt
read -p "📧 Enter your email for Let's Encrypt certificates: " EMAIL

if [ -z "$EMAIL" ]; then
    echo "❌ Email is required for Let's Encrypt certificates"
    exit 1
fi

# Generate password hash for Traefik dashboard
echo "🔐 Generating secure password for Traefik dashboard..."
TRAEFIK_PASSWORD=$(openssl rand -base64 32 | tr -d '=' | head -c 16)
TRAEFIK_HASH=$(echo -n "$TRAEFIK_PASSWORD" | htpasswd -niB admin | cut -d: -f2 | sed 's/\$/\\$/g')

echo

# Update .env file
echo "📝 Updating .env configuration..."

# Create backup
cp .env .env.backup

# Update domain with VPS IP
DOMAIN="${VPS_IP}"
sed -i "s/DOMAIN=.*/DOMAIN=${DOMAIN}/" .env

# Update email
sed -i "s/LETSENCRYPT_EMAIL=.*/LETSENCRYPT_EMAIL=${EMAIL}/" .env

# Update Traefik auth
sed -i "s|TRAEFIK_AUTH=.*|TRAEFIK_AUTH=admin:${TRAEFIK_HASH}|" .env

echo "✅ Configuration updated!"
echo

echo "=== 🎯 Your HTTPS Configuration ==="
echo "Domain:             https://$DOMAIN"
echo "ChirpStack:         https://$DOMAIN/chirpstack/"
echo "Grafana:           https://$DOMAIN/grafana/"
echo "InfluxDB:          https://$DOMAIN/influxdb/"
echo "Traefik Dashboard: https://$DOMAIN/dashboard/"
echo
echo "Traefik Login:"
echo "  Username: admin"
echo "  Password: $TRAEFIK_PASSWORD"
echo
echo "=== 🚀 Next Steps ==="
echo "1. Deploy with HTTPS:"
echo "   docker compose down && docker compose up -d"
echo
echo "2. Wait 2-3 minutes for Let's Encrypt certificates"
echo
echo "3. Test your secure endpoints:"
echo "   curl https://$DOMAIN"
echo
echo "4. Access Traefik dashboard:"
echo "   https://$DOMAIN/dashboard/"
echo
echo "📝 Traefik password saved above - copy it now!"
echo
echo "⚠️  Make sure ports 80 and 443 are open in your VPS firewall"