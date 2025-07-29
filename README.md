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

## راهنمای راه‌اندازی سریع (نصب وردپرس خام) 🚀

این راهنما یک وردپرس خام و جدید را برای شما راه‌اندازی می‌کند.

1.  **آماده‌سازی اولیه:** با SSH به سرور متصل شده و پروژه را از گیت‌هاب کلون کنید:
    ```bash
    git clone https://github.com/WebCodex-ir/docker-wordpress-stack.git
    cd docker-wordpress-stack
    ```
2.  **پیکربندی:** فایل `.env.example` را به `.env` کپی کرده و با اطلاعات صحیح خود (دامنه، ایمیل و توکن کلودفلر و رمزهای دیتابیس) پر کنید.
    ```bash
    cp .env.example .env
    nano .env
    ```
3.  **اجرای اسکریپت:** اسکریپت نصب را قابل اجرا کرده و آن را اجرا کنید.
    ```bash
    chmod +x install.sh
    sudo ./install.sh
    ```
4.  **تنظیمات DNS:** در کلودفلر، یک رکورد `A` برای دامنه خود بسازید که به IP سرور اشاره کند و حالت SSL را روی **Full (Strict)** قرار دهید.
5.  **نصب وردپرس:** پس از چند دقیقه، به آدرس دامنه خود بروید و مراحل نصب ۵ دقیقه‌ای وردپرس را تکمیل کنید.

---
## راهنمای انتقال کامل سایت (روش دستی و حرفه‌ای) 🚚

این روش پیشنهادی و مطمئن‌ترین راه برای انتقال یک سایت موجود است.

**مرحله ۱: آماده‌سازی بک‌آپ در سرور قدیمی**
- از کنترل پنل خود (مثلاً دایرکت ادمین) یک **بک‌آپ کامل** تهیه و آن را دانلود کنید. این بکاپ شامل یک پوشه `domains` (حاوی فایل‌های سایت مانند `wp-content`) و یک پوشه `backup` (حاوی فایل دیتابیس با پسوند `.sql`) است.

**مرحله ۲: راه‌اندازی سرور جدید**
- مراحل ۱ تا ۳ راهنمای نصب سریع را انجام دهید تا یک وردپرس خام روی سرور جدید شما بالا بیاید.

**مرحله ۳: انتقال فایل‌ها و دیتابیس**
- فایل بک‌آپ (`.tar.gz`) را روی سرور جدید (مثلاً در پوشه `/root/`) آپلود کرده و با دستور `tar -xvzf your-backup.tar.gz` آن را از حالت فشرده خارج کنید.

**مرحله ۴: جایگزینی فایل‌ها و دیتابیس**
1.  **متوقف کردن سرویس‌ها:**
    ```bash
    sudo docker compose down
    ```
2.  **پاک کردن محتویات پیش‌فرض:**
    ```bash
    sudo rm -rf ./data/wordpress/*
    sudo rm -rf ./data/mariadb/*
    ```
3.  **کپی کردن فایل‌های سایت قدیمی:**
    پوشه `wp-content` و سایر فایل‌های وردپرس را از بک‌آپ استخراج شده به مسیر `./data/wordpress/` کپی کنید.
    ```bash
    # مسیر بک‌آپ خود را جایگزین کنید
    sudo cp -r /path/to/extracted_backup/domains/[your-old-domain.com/public_html/](https://your-old-domain.com/public_html/)* ./data/wordpress/
    ```
4.  **راه‌اندازی دیتابیس و وردپرس:**
    ```bash
    sudo docker compose up -d mariadb wordpress
    ```
5.  **درون‌ریزی دیتابیس:**
    فایل `.sql` را به دیتابیس جدید وارد کنید (مقادیر را از فایل `.env` خود جایگزین کنید).
    ```bash
    sudo docker exec -i mariadb mariadb -uYOUR_DB_USER -pYOUR_DB_PASSWORD YOUR_DB_NAME < /path/to/your/database.sql
    ```

**مرحله ۵: اصلاحات نهایی (بسیار مهم)**
1.  **جایگزینی آدرس دامنه در دیتابیس:**
    ```bash
    # به جای your-old-domain.com آدرس سایت قدیمی را وارد کنید
    sudo docker compose run --rm wp-cli wp search-replace '[https://your-old-domain.com](https://your-old-domain.com)' '[https://your-new-domain.com](https://your-new-domain.com)' --all-tables
    ```
2.  **جایگزینی مسیرهای فایل در دیتابیس:**
    ```bash
    # به جای /home/user/domains/... مسیر قدیمی را وارد کنید
    sudo docker compose run --rm wp-cli wp search-replace '/home/user/domains/[old-domain.com/public_html](https://old-domain.com/public_html)' '/var/www/html' --all-tables
    ```
3.  **راه‌اندازی کامل سرویس‌ها:**
    ```bash
    sudo docker compose up -d
    ```
4.  **تنظیم دسترسی فایل‌ها (دستور کلیدی):**
    این دستور نهایی برای حل مشکلات آپدیت و دسترسی است.
    ```bash
    sudo chown -R www-data:www-data ./data/wordpress/
    ```
5.  **ورود و ذخیره پیوندهای یکتا:**
    وارد پیشخوان وردپرس شوید، به **تنظیمات > پیوندهای یکتا** بروید و دو بار روی دکمه **"ذخیره تغییرات"** کلیک کنید.

---
## مدیریت پیشرفته و دستورات مفید ⚙️

* **افزودن دامنه یا ساب‌دامین جدید:**
  به بخش مربوطه در فایل `docker-compose.yml` یک سرویس جدید (شامل `nginx`, `wordpress`, `mariadb`) با نام‌ها و پوشه‌های منحصر به فرد اضافه کنید و در بخش `labels` آن، `Host(\`new-domain.com\`)` را با دامنه جدید خود مشخص کنید.

* **گرفتن بکاپ کامل:**
    ```bash
    sudo tar -czvf backup-$(date +%Y-%m-%d).tar.gz ./data
    ```

* **بازگردانی بکاپ کامل:**
    پروژه را از گیت کلون کنید، فایل بکاپ را در آن آپلود و با دستور `sudo tar -xzvf your-backup-file.tar.gz` استخراج کنید. سپس `sudo docker compose up -d` را اجرا نمایید.

* **مشاهده کانتینرها:** `sudo docker ps`
* **مشاهده لاگ‌ها:** `sudo docker compose logs -f <service_name>`
* **متوقف کردن سرویس‌ها:** `sudo docker compose down`
* **شروع مجدد سرویس‌ها:** `sudo docker compose up -d`
