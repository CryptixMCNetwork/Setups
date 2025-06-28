#!/bin/bash

### Konfiguration
DOMAIN="deine-domain.tld"
DB_NAME="namelessmc"
DB_USER="namelessuser"
DB_PASS="starkesPasswort123!"
NAMLESS_DIR="/var/www/namelessmc"

### Systempakete aktualisieren
apt update && apt upgrade -y

### Repos für PHP 8.3 hinzufügen
apt install -y ca-certificates apt-transport-https gnupg lsb-release curl software-properties-common

curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/php.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

apt update

### Apache, PHP 8.3, MariaDB & Tools installieren
apt install -y apache2 mariadb-server unzip wget git php8.3 php8.3-{cli,common,gd,mysql,xml,curl,mbstring,zip,bcmath,imagick,intl} phpmyadmin

### MariaDB konfigurieren (non-interaktiv)
mysql -u root <<EOF
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

### NamelessMC herunterladen (fertige Release mit vendor)
cd /var/www/
wget https://github.com/NamelessMC/Nameless/releases/latest/download/nameless-deps-dist.zip
unzip nameless-deps-dist.zip
mv Nameless* namelessmc

chown -R www-data:www-data ${NAMLESS_DIR}
chmod -R 755 ${NAMLESS_DIR}

### Apache VirtualHost anlegen
cat <<EOF > /etc/apache2/sites-available/namelessmc.conf
<VirtualHost *:80>
    ServerName ${DOMAIN}
    DocumentRoot ${NAMLESS_DIR}

    <Directory ${NAMLESS_DIR}>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/nameless_error.log
    CustomLog \${APACHE_LOG_DIR}/nameless_access.log combined
</VirtualHost>
EOF

a2ensite namelessmc.conf
a2enmod rewrite
systemctl reload apache2

### PHPMyAdmin aktivieren (falls nicht automatisch eingebunden)
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

### Let’s Encrypt (optional – manuell nach Domainauflösung)
# apt install certbot python3-certbot-apache -y
# certbot --apache -d ${DOMAIN}

### Cronjob für NamelessMC einrichten
(crontab -l 2>/dev/null; echo "* * * * * php ${NAMLESS_DIR}/core/cron.php > /dev/null 2>&1") | crontab -

echo "✅ Installation abgeschlossen."
echo "Domain: http://${DOMAIN}"
echo "DB-Name: ${DB_NAME}, User: ${DB_USER}, Passwort: ${DB_PASS}"
echo "phpMyAdmin: http://${DOMAIN}/phpmyadmin"
