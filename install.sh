#!/bin/bash
#
# WordPress High-Performance Stack Installer
# Author: Your Name (or AI Assistant)
# GitHub: your-github-link
#

# --- Step 1: Check for Root Privileges ---
if [ "$EUID" -ne 0 ]; then
  echo "لطفا این اسکریپت را با دسترسی root اجرا کنید (sudo ./install.sh)"
  exit 1
fi

# --- Step 2: Update System ---
echo "✅ در حال به‌روزرسانی پکیج‌های سیستم..."
apt-get update && apt-get upgrade -y

# --- Step 3: Install Docker and Docker Compose ---
echo "✅ در حال نصب داکر و داکر کامپوز..."
if ! command -v docker &> /dev/null; then
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo "داکر از قبل نصب شده است."
fi

# --- Step 4: Configure Firewall (UFW) ---
echo "✅ در حال پیکربندی فایروال (UFW)..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp  # SSH
    ufw allow 80/tcp  # HTTP
    ufw allow 443/tcp # HTTPS
    ufw --force enable
    echo "فایروال فعال و پورت‌های لازم باز شدند."
else
    echo "UFW یافت نشد، از این مرحله صرف نظر می‌شود."
fi

# --- Step 5: Create Project Structure ---
echo "✅ در حال ایجاد ساختار پروژه..."
mkdir -p ./data/traefik
mkdir -p ./data/wordpress
touch ./data/traefik/acme.json
chmod 600 ./data/traefik/acme.json

# --- Step 6: Check for .env file ---
if [ ! -f .env ]; then
    echo "⚠️ فایل .env یافت نشد."
    echo "یک فایل نمونه .env.example ایجاد شد. لطفا آن را با اطلاعات خود ویرایش کرده و به .env تغییر نام دهید."
    # Create the .env.example file
    cat > .env.example <<EOL
# --- General Settings ---
DOMAIN_NAME=your-domain.com
CLOUDFLARE_EMAIL=your-cloudflare-email@example.com

# --- Database Credentials (Use strong, random passwords) ---
DB_ROOT_PASSWORD=strong_root_password
DB_NAME=wordpress
DB_USER=wp_user
DB_PASSWORD=strong_user_password

# --- Traefik Basic Auth (for dashboard, optional) ---
# Generate with: echo $(htpasswd -nb user password) | sed -e s/\\$/\\$\\$/g
# Example for user: admin, pass: admin
TRAEFIK_AUTH=admin:\$$apr1\$$k8I72L1.\$$p9yH0FkS6LVj4rN/v21w8.
EOL
    exit 1
fi

# --- Step 7: Launch the Stack ---
echo "🚀 در حال راه‌اندازی تمام سرویس‌ها با Docker Compose..."
docker compose up -d

echo "🎉 نصب و راه‌اندازی با موفقیت انجام شد!"
echo "--------------------------------------------------"
echo "اکنون می‌توانید دامنه خود را در کلودفلر به IP این سرور (${HOSTNAME_IP}) متصل کنید."
echo "مطمئن شوید حالت SSL در کلودفلر روی 'Full (Strict)' تنظیم شده باشد."
echo "برای مشاهده لاگ‌ها از دستور 'docker compose logs -f' استفاده کنید."
