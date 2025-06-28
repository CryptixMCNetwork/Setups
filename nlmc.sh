#!/bin/bash

set -e

echo "========== NamelessMC + Apache2 + PHP 8.3 Installer =========="

# === Abfragen ===
read -p "📝 Domain/Subdomain (z.B. forum.example.com): " DOMAIN
read -p "📛 MySQL Datenbankname: " DB_NAME
read -p "👤 MySQL Benutzername: " DB_USER
read -s -p "🔐 MySQL Passwort: " DB_PASS
echo
read -p "📦 NamelessMC Zielverzeichnis (default: /var/www/namelessmc): " NAMLESS_DIR
NAMLESS_DIR=${NAMLESS_DIR:-/var/www/namelessmc}

read -p "🔒 SSL mit Let's Encrypt aktivieren? (j/n): " SSL_ENABLED

# === Systempakete ===
echo "[+] Aktualisiere Systempakete..."
apt update && apt upgrade -y

echo "[+] Installiere Apache, MariaDB, PHP 8.3 & Tools..."
apt install -y ca-certificates apt-transport-https gnupg lsb-release curl software-properties-common unzip wget git apache2 mariadb-server

# PHP 8.3 Repo
curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/php.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
apt update

# PHP 8.3 + Extensions
apt install -y php8.3 php8.3-{cli,common,gd,mysql,xml,curl,mbstring,zip,bcmath,imagick,intl}

# phpMyAdmin
echo "[+] Installiere phpMyAdmin..."
apt install -y phpmyadmin

# === MariaDB Setup ===
echo "[+] Konfiguriere MariaDB..."
mysql -u root <<EOF
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# === NamelessMC herunterladen ===
echo "[+] Lade NamelessMC herunter..."
cd /var/www/
wget -q https://github.com/NamelessMC/Nameless/releases/latest/download/nameless-deps-dist.zip
unzip -q nameless-deps-dist.zip
mv Nameless* "${NAMLESS_DIR}"
chown -R www-data:www-data "${NAMLESS_DIR}"
chmod -R 755 "${NAMLESS_DIR}"

# === Apache-Konfiguration ===
echo "[+] Richte Apache VirtualHost ein..."
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

# === Let's Encrypt SSL ===
if [[ "$SSL_ENABLED" =~ ^[Jj]$ ]]; then
    echo "[+] Installiere Certbot für Let's Encrypt SSL..."
    apt install -y certbot python3-certbot-apache
    certbot --apache -d "$DOMAIN"
fi

# === Cronjob für NamelessMC ===
echo "[+] Cronjob für NamelessMC einrichten..."
(crontab -l 2>/dev/null; echo "* * * * * php ${NAMLESS_DIR}/core/cron.php > /dev/null 2>&1") | crontab -

# === phpMyAdmin Symlink ===
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin 2>/dev/null || true

# === Abschluss ===
echo
echo "✅ Installation abgeschlossen!"
echo "🌐 Forum: http://${DOMAIN}"
echo "🛠 Installer im Browser starten und Einrichtung abschließen."
[[ "$SSL_ENABLED" =~ ^[Jj]$ ]] && echo "🔒 SSL aktiv unter https://${DOMAIN}"
echo "📂 NamelessMC-Verzeichnis: ${NAMLESS_DIR}"
echo "🗄 MySQL: DB=${DB_NAME}, User=${DB_USER}"
echo "🧰 phpMyAdmin: http://${DOMAIN}/phpmyadmin"
