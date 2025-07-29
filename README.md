# استک داکر وردپرس با عملکرد بالا - راهنمای کامل

این پروژه یک قالب آماده و حرفه‌ای برای راه‌اندازی یک یا چند سایت وردپرسی بسیار سریع، امن و بهینه با استفاده از Docker است. تمام فرآیندها برای نصب آسان و سریع، خودکار شده‌اند.

## معماری 🏗️

این استک از بهترین ابزارهای مدرن برای اجرای وردپرس استفاده می‌کند:
* **Reverse Proxy:** **Traefik** (برای مسیریابی هوشمند و مدیریت خودکار SSL)
* **وب سرور:** **Nginx** (برای سرویس‌دهی به فایل‌های وردپرس و ارتباط با PHP)
* **اپلیکیشن:** **WordPress** (اجرا شده روی آخرین نسخه PHP-FPM)
* **دیتابیس:** **MariaDB** (جایگزین سریع‌تر و بهینه‌تر MySQL)
* **کشینگ:** **Redis** (برای کش آبجکت‌ها و افزایش چشمگیر سرعت)
* **کنترل پنل:** **Portainer** (رابط گرافیکی برای مدیریت داکر)

## پیش‌نیازها 📋

1. یک سرور با سیستم عامل **Ubuntu 22.04 / 24.04**
2. یک **دامنه** که Nameserver های آن روی **Cloudflare** تنظیم شده باشد
3. یک **توکن API از کلودفلر** (Cloudflare API Token) با دسترسی `Edit zone DNS`

## 🚀 راهنمای نصب و راه‌اندازی

### 1. راه‌اندازی اولیه سرور

با SSH به سرور خود متصل شوید و دستورات زیر را اجرا کنید:

```bash
git clone https://github.com/WebCodex-ir/docker-wordpress-stack.git
cd docker-wordpress-stack
cp .env.example .env
nano .env
```

مقادیر زیر را در فایل `.env` ویرایش کنید:
- `DOMAIN_NAME`: دامنه اصلی شما (مثال: example.com)
- `CLOUDFLARE_EMAIL`: ایمیل حساب کلودفلر
- `CLOUDFLARE_DNS_API_TOKEN`: توکن API کلودفلر
- رمزهای عبور دیتابیس (مقادیر تصادفی و قوی انتخاب کنید)

سپس اسکریپت نصب را اجرا کنید:

```bash
chmod +x install.sh
sudo ./install.sh
```

### 2. تنظیم DNS در کلودفلر

1. به پنل کلودفلر وارد شوید
2. برای دامنه خود یک رکورد `A` ایجاد کنید که به IP سرور شما اشاره کند
3. حالت SSL را روی **Full (Strict)** تنظیم کنید

### 3. تکمیل نصب وردپرس

پس از چند دقیقه، به آدرس دامنه خود مراجعه کرده و مراحل نصب ۵ دقیقه‌ای وردپرس را تکمیل کنید.

## 🚚 راهنمای انتقال سایت موجود

### مرحله 1: تهیه بک‌آپ از سایت قدیمی

1. از کنترل پنل سرور قدیمی (مثلاً دایرکت ادمین) یک **بک‌آپ کامل** تهیه کنید
2. بکاپ باید شامل:
   - پوشه `wp-content` و سایر فایل‌های وردپرس
   - فایل دیتابیس با پسوند `.sql`

### مرحله 2: انتقال فایل‌ها به سرور جدید

1. فایل بک‌آپ را روی سرور جدید آپلود کنید (مثلاً در `/root/`)
2. از حالت فشرده خارج کنید:
   ```bash
   tar -xvzf your-backup.tar.gz
   ```

### مرحله 3: جایگزینی فایل‌ها و دیتابیس

1. سرویس‌ها را متوقف کنید:
   ```bash
   sudo docker compose down
   ```

2. محتویات پیش‌فرض را پاک کنید:
   ```bash
   sudo rm -rf ./data/wordpress/*
   sudo rm -rf ./data/mariadb/*
   ```

3. فایل‌های سایت قدیمی را کپی کنید:
   ```bash
   sudo cp -r /path/to/extracted_backup/domains/old-domain.com/public_html/* ./data/wordpress/
   ```

4. دیتابیس را راه‌اندازی کنید:
   ```bash
   sudo docker compose up -d mariadb wordpress
   ```

5. دیتابیس را وارد کنید (مقادیر را از `.env` جایگزین کنید):
   ```bash
   sudo docker exec -i mariadb mariadb -uYOUR_DB_USER -pYOUR_DB_PASSWORD YOUR_DB_NAME < /path/to/database.sql
   ```

### مرحله 4: اصلاحات نهایی

1. جایگزینی آدرس دامنه در دیتابیس:
   ```bash
   sudo docker compose run --rm wp-cli wp search-replace 'https://old-domain.com' 'https://new-domain.com' --all-tables
   ```

2. جایگزینی مسیرهای فایل:
   ```bash
   sudo docker compose run --rm wp-cli wp search-replace '/home/user/domains/old-domain.com/public_html' '/var/www/html' --all-tables
   ```

3. راه‌اندازی کامل سرویس‌ها:
   ```bash
   sudo docker compose up -d
   ```

4. تنظیم دسترسی فایل‌ها:
   ```bash
   sudo chown -R www-data:www-data ./data/wordpress/
   ```

5. در پیشخوان وردپرس، به **تنظیمات > پیوندهای یکتا** رفته و دو بار **ذخیره تغییرات** را کلیک کنید.

## 🏗️ افزودن سایت/ساب‌دامین جدید

### 1. افزودن ساب‌دامین (مثال: test.example.com)

1. در کلودفلر یک رکورد `A` برای ساب‌دامین ایجاد کنید
2. به `docker-compose.yml` بخش زیر را اضافه کنید:
   ```yaml
   test-site:
     image: httpd:alpine
     container_name: test-site
     restart: unless-stopped
     labels:
       - "traefik.enable=true"
       - "traefik.http.routers.test-site.rule=Host(`test.example.com`)"
       - "traefik.http.routers.test-site.entrypoints=websecure"
       - "traefik.http.routers.test-site.tls=true"
       - "traefik.http.routers.test-site.tls.certresolver=cloudflare"
   ```
3. تغییرات را اعمال کنید:
   ```bash
   sudo docker compose up -d
   ```

### 2. افزودن دامنه کاملاً جدید (مثال: new-domain.com)

1. دامنه جدید را در کلودفلر تنظیم کنید
2. به `docker-compose.yml` بخش زیر را اضافه کنید (مقادیر را تغییر دهید):
   ```yaml
   nginx_site2:
     image: nginx:stable-alpine
     restart: unless-stopped
     volumes:
       - ./data/wordpress2:/var/www/html
       - ./data/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
     labels:
       - "traefik.enable=true"
       - "traefik.http.routers.wordpress_site2.rule=Host(`new-domain.com`)"
       - "traefik.http.routers.wordpress_site2.entrypoints=websecure"
       - "traefik.http.routers.wordpress_site2.tls=true"
       - "traefik.http.routers.wordpress_site2.tls.certresolver=cloudflare"

   wordpress_site2:
     image: wordpress:latest-fpm-alpine
     restart: unless-stopped
     volumes:
       - ./data/wordpress2:/var/www/html
     environment:
       - WORDPRESS_DB_HOST=mariadb_site2
       - WORDPRESS_DB_USER=user_site2
       - WORDPRESS_DB_PASSWORD=password_site2
       - WORDPRESS_DB_NAME=db_site2
     depends_on:
       - mariadb_site2

   mariadb_site2:
     image: mariadb:latest
     restart: unless-stopped
     volumes:
       - ./data/mariadb2:/var/lib/mysql
     environment:
       - MARIADB_ROOT_PASSWORD=root_password_site2
       - MARIADB_DATABASE=db_site2
       - MARIADB_USER=user_site2
       - MARIADB_PASSWORD=password_site2
   ```
3. تغییرات را اعمال کنید:
   ```bash
   sudo docker compose up -d
   ```

## 💾 بکاپ و بازگردانی

### گرفتن بکاپ کامل

```bash
sudo tar -czvf backup-$(date +%Y-%m-%d).tar.gz ./data
```

### بازگردانی بکاپ کامل

1. پروژه را از گیت کلون کنید:
   ```bash
   git clone https://github.com/WebCodex-ir/docker-wordpress-stack.git
   cd docker-wordpress-stack
   ```

2. فایل `.env` را با اطلاعات خود پر کنید

3. فایل بکاپ را استخراج کنید:
   ```bash
   sudo tar -xzvf backup-file.tar.gz
   ```

4. سرویس‌ها را راه‌اندازی کنید:
   ```bash
   sudo docker compose up -d
   ```

## ⚙️ دستورات مدیریتی و عیب‌یابی

### دستورات پایه

| دستور | توضیح |
|-------|-------|
| `sudo docker ps` | مشاهده کانتینرهای در حال اجرا |
| `sudo docker compose logs -f service_name` | مشاهده لاگ سرویس |
| `sudo docker compose down` | متوقف کردن سرویس‌ها |
| `sudo docker compose up -d` | راه‌اندازی سرویس‌ها |
| `sudo chown -R www-data:www-data ./data/wordpress/` | اصلاح دسترسی فایل‌ها |

### عیب‌یابی مشکلات رایج

1. **مشکل دسترسی فایل‌ها پس از انتقال:**
   ```bash
   sudo chown -R www-data:www-data ./data/wordpress/
   ```

2. **مشکلات SSL:**
   - مطمئن شوید در کلودفلر:
     - رکورد DNS صحیح است
     - حالت SSL روی **Full (Strict)** است
     - توکن API دارای دسترسی کافی است

3. **مشاهده خطاهای خاص:**
   ```bash
   sudo docker compose logs -f wordpress  # برای خطاهای وردپرس
   sudo docker compose logs -f nginx     # برای خطاهای nginx
   sudo docker compose logs -f mariadb   # برای خطاهای دیتابیس
   ```

4. **ریست سرویس‌ها:**
   ```bash
   sudo docker compose restart
   ```

5. **بررسی وضعیت Traefik:**
   ```bash
   sudo docker compose logs -f traefik
   ```

## نکات مهم

1. همیشه قبل از انجام تغییرات بزرگ از سیستم بکاپ بگیرید
2. برای هر سایت جدید از نام سرویس‌ها و مسیرهای volume منحصر به فرد استفاده کنید
3. رمزهای عبور دیتابیس باید قوی و منحصر به فرد باشند
4. پس از انتقال سایت، حتماً پیوندهای یکتا را در وردپرس ذخیره کنید
5. برای عملکرد بهتر، کش Redis را در وردپرس فعال کنید
