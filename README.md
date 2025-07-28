# استک داکر وردپرس با عملکرد بالا

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

1.  یک سرور با سیستم عامل **Ubuntu 22.04 / 24.04**.
2.  یک **دامنه** که Nameserver های آن روی **Cloudflare** تنظیم شده باشد.
3.  یک **توکن API از کلودفلر** (Cloudflare API Token) با دسترسی `Edit zone DNS`.

## راهنمای راه‌اندازی اولیه 🚀

این مراحل سرور شما را برای میزبانی سایت‌ها آماده می‌کند.

#### **۱. آماده‌سازی اولیه سرور**

با SSH به سرور خود متصل شوید و این ریپازیتوری را کلون کنید:
```bash
git clone [https://github.com/WebCodex-ir/docker-wordpress-stack.git](https://github.com/WebCodex-ir/docker-wordpress-stack.git)
cd docker-wordpress-stack
````

سپس فایل پیکربندی را آماده کنید:

```bash
# فایل نمونه را کپی کنید
cp .env.example .env

# فایل را با اطلاعات خود ویرایش کنید
nano .env
```

در فایل `.env`، تمام مقادیر (`DOMAIN_NAME`, `CLOUDFLARE_EMAIL`, `CLOUDFLARE_DNS_API_TOKEN` و رمزهای عبور دیتابیس) را با دقت پر کنید. در نهایت، اسکریپت نصب را قابل اجرا کنید:

```bash
chmod +x install.sh
```

#### **۲. اجرای اسکریپت نصب**

اسکریپت را اجرا کنید. این اسکریپت داکر، پورتینر و سایر نیازمندی‌ها را نصب کرده و یک وردپرس خالی راه‌اندازی می‌کند.

```bash
sudo ./install.sh
```

پس از اتمام، یک وردپرس خام روی دامنه اصلی شما در دسترس است که می‌توانید آن را نصب کرده یا با استفاده از راهنمای زیر، سایت قدیمی خود را به آن منتقل کنید.

-----

## مدیریت پیشرفته سرور 🛠️

در ادامه نحوه مدیریت، توسعه و نگهداری سرور توضیح داده شده است.

### **افزودن یک ساب‌دامین جدید**

فرض کنید می‌خواهیم یک سایت استاتیک ساده روی ساب‌دامین `test.sialkplast.ir` اضافه کنیم.

1.  **تنظیم DNS:** در کلودفلر، یک رکورد `A` جدید برای ساب‌دامین `test` بسازید که به IP سرور شما اشاره کند.
2.  **ویرایش `docker-compose.yml`:** فایل `docker-compose.yml` را باز کرده و سرویس جدید زیر را به انتهای آن (هم‌سطح با سرویس‌های دیگر) اضافه کنید:
    ```yaml
    
      test-site:
        image: httpd:alpine
        container_name: test-site
        restart: unless-stopped
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.test-site.rule=Host(`test.sialkplast.ir`)"
          - "traefik.http.routers.test-site.entrypoints=websecure"
          - "traefik.http.routers.test-site.tls=true"
          - "traefik.http.routers.test-site.tls.certresolver=cloudflare"
    ```
3.  **اعمال تغییرات:** دستور زیر را اجرا کنید. Traefik به صورت خودکار سرویس جدید را شناسایی کرده و برای آن SSL دریافت می‌کند.
    ```bash
    sudo docker compose up -d
    ```

### **افزودن یک دامنه کاملاً جدید**

شما می‌توانید یک وردپرس کاملاً مجزا برای یک دامنه جدید (مثلاً `new-domain.com`) نیز اضافه کنید.

1.  **تنظیم DNS:** دامنه جدید را به کلودفلر اضافه کرده و یک رکورد `A` برای آن بسازید که به IP سرور شما اشاره کند.
2.  **ویرایش `docker-compose.yml`:** سرویس‌های جدیدی برای وردپرس و دیتابیس دوم به انتهای فایل `docker-compose.yml` اضافه کنید. **مهم است که نام سرویس‌ها و مسیر پوشه‌ها منحصر به فرد باشند.**
    ```yaml
    
      # --- سرویس‌های سایت دوم ---
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
          - WORDPRESS_DB_PASSWORD=a_very_strong_password
          - WORDPRESS_DB_NAME=db_site2
        depends_on:
          - mariadb_site2

      mariadb_site2:
        image: mariadb:latest
        restart: unless-stopped
        volumes:
          - ./data/mariadb2:/var/lib/mysql
        environment:
          - MARIADB_ROOT_PASSWORD=another_strong_root_password
          - MARIADB_DATABASE=db_site2
          - MARIADB_USER=user_site2
          - MARIADB_PASSWORD=a_very_strong_password
    ```
3.  **اعمال تغییرات:** دستور `sudo docker compose up -d` را اجرا کنید تا سایت جدید راه‌اندازی شود.

-----

## بکاپ و بازگردانی 💾

### **گرفتن بکاپ کامل**

بکاپ کامل شامل داده‌ها (پوشه `data`) و پیکربندی (فایل‌های پروژه در گیت‌هاب) است.

1.  برای گرفتن بکاپ از تمام فایل‌ها و دیتابیس‌ها، دستور زیر را در پوشه اصلی پروژه اجرا کنید:
    ```bash
    sudo tar -czvf backup-$(date +%Y-%m-%d).tar.gz ./data
    ```
2.  این دستور یک فایل فشرده با نام `backup-YYYY-MM-DD.tar.gz` ایجاد می‌کند. این فایل را دانلود کرده و در جای امنی نگهداری کنید.

### **بازگردانی بکاپ کامل**

برای بازگردانی سایت روی یک سرور جدید و خام:

1.  **آماده‌سازی اولیه:** پروژه را از گیت‌هاب خود `clone` کرده و فایل `.env` را با اطلاعات صحیح پر کنید.
2.  **آپلود و استخراج بکاپ:** فایل بکاپ (`.tar.gz`) را در پوشه اصلی پروژه آپلود کرده و با دستور زیر آن را از حالت فشرده خارج کنید:
    ```bash
    sudo tar -xzvf your-backup-file.tar.gz
    ```
3.  **راه‌اندازی سرویس‌ها:** دستور زیر را اجرا کنید تا تمام سرویس‌ها با اطلاعات بکاپ شما بالا بیایند:
    ```bash
    sudo docker compose up -d
    ```

-----

## عیب‌یابی و دستورات مفید ⚙️

  * **مشکل دسترسی فایل‌ها پس از انتقال:**
    اگر بعد از انتقال سایت با افزونه Duplicator یا به صورت دستی، در آپدیت یا نصب افزونه‌ها با خطای دسترسی فایل (File Permissions) مواجه شدید، به این دلیل است که مالکیت فایل‌ها به هم ریخته است. با دستور زیر آن را اصلاح کنید:

    ```bash
    sudo chown -R www-data:www-data ./data/wordpress/
    ```

  * **دستورات مدیریتی:**

      * **مشاهده کانتینرها:** `sudo docker ps`
      * **مشاهده لاگ‌ها:** `sudo docker compose logs -f <service_name>`
      * **متوقف کردن سرویس‌ها:** `sudo docker compose down`
      * **شروع مجدد سرویس‌ها:** `sudo docker compose up -d`

<!-- end list -->
