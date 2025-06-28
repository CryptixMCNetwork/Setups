#!/bin/bash

set -e

echo "=== Apache2 + PHP 8.3 + phpMyAdmin + NamelessMC Setup ==="

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo "Bitte als root ausführen."
    exit 1
fi

read -p "Domain oder IP für NamelessMC (z.B. example.com): " DOMAIN

# Update & Grundpakete
echo "--- System aktualisieren ---"
apt update && apt upgrade -y
apt install -y curl wget unzip gnupg2 lsb-release ca-certificates apt-transport-https software-properties-common

# Apache installieren
echo "--- Apache2 installieren ---"
apt install -y apache2
systemctl enable apache2
systemctl start apache2

# PHP 8.3 installieren
echo "--- PHP 8.3 installieren ---"
wget -q https://packages.sury.org/php/apt.gpg -O- | gpg --dearmor -o /etc/apt/trusted.gpg.d/php.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
apt update
apt install -y php8.3 php8.3-cli php8.3-mbstring php8.3-xml php8.3-mysql php8.3-curl php8.3-zip php8.3-gd libapache2-mod-php8.3

# Apache neustarten
systemctl restart apache2

# phpMyAdmin installieren
echo "--- phpMyAdmin installieren ---"
DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin

# Symbolischen Link setzen, falls nötig
if [ ! -e /var/www/html/phpmyadmin ]; then
    ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
fi

# NamelessMC Setup
echo "--- NamelessMC herunterladen ---"
cd /var/www/html
NAMEDIR="namelessmc"

if [ -d "$NAMEDIR" ]; then
    echo "Verzeichnis $NAMEDIR existiert bereits. Bitte manuell prüfen."
else
    mkdir "$NAMEDIR"
    cd "$NAMEDIR"
    curl -sL https://namelessmc.com/latest.zip -o nameless.zip
    unzip nameless.zip
    rm nameless.zip
    chown -R www-data:www-data /var/www/html/$NAMEDIR
fi

# Apache Konfiguration
echo "--- Apache VirtualHost konfigurieren ---"
cat >/etc/apache2/sites-available/namelessmc.conf <<EOL
<VirtualHost *:80>
    ServerAdmin webmaster@$DOMAIN
    ServerName $DOMAIN
    DocumentRoot /var/www/html/$NAMEDIR

    <Directory /var/www/html/$NAMEDIR>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/namelessmc_error.log
    CustomLog \${APACHE_LOG_DIR}/namelessmc_access.log combined
</VirtualHost>
EOL

a2ensite namelessmc.conf
a2enmod rewrite
systemctl reload apache2

echo "=== Setup abgeschlossen ==="
echo "Rufe http://$DOMAIN auf, um die NamelessMC-Web-Installation abzuschließen."
