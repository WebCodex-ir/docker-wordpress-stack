#!/bin/bash

# --- Check for Root Privileges ---
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with root privileges (sudo ./install.sh)"
  exit 1
fi

echo "✅ Updating system packages..."
apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1

echo "✅ Installing Docker and Docker Compose..."
if ! command -v docker &> /dev/null; then
    apt-get install -y ca-certificates curl > /dev/null 2>&1
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update > /dev/null 2>&1
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1
else
    echo "Docker is already installed."
fi

echo "✅ Configuring Firewall (UFW)..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp  > /dev/null 2>&1
    ufw allow 80/tcp  > /dev/null 2>&1
    ufw allow 443/tcp > /dev/null 2>&1
    ufw --force enable > /dev/null 2>&1
fi

echo "✅ Creating project structure..."
mkdir -p ./data/nginx
mkdir -p ./data/traefik
mkdir -p ./data/wordpress
mkdir -p ./data/mariadb
touch ./data/traefik/acme.json
chmod 600 ./data/traefik/acme.json

if [ ! -f .env ]; then
    echo "❌ ERROR: .env file not found. Please copy .env.example to .env and fill it with your details."
    exit 1
fi

echo "🚀 Launching all services..."
docker compose up -d

echo "🎉 Deployment successful!"
echo "➡️ Wait a few minutes for the SSL certificate to be issued."
echo "➡️ Your site will be available at: https://$(grep DOMAIN_NAME .env | cut -d '=' -f2)"
echo "➡️ Your Traefik dashboard: https://traefik.$(grep DOMAIN_NAME .env | cut -d '=' -f2)"
