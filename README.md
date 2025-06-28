# NamelessMC Installer (Debian 12)

Automatisiert die komplette Installation von NamelessMC auf einem Debian 12 Server – inklusive Apache2, PHP 8.3, MariaDB, phpMyAdmin und optional SSL via Let's Encrypt.

---

## ✅ Features

- Interaktive Eingaben (Domain, DB, Pfad, SSL)
- PHP 8.3 mit allen empfohlenen Extensions
- Apache vHost + Rewrite aktiviert
- Let’s Encrypt optional aktivierbar
- phpMyAdmin verfügbar unter `/phpmyadmin`
- Automatische Cronjob-Einrichtung

---

## 🧰 Voraussetzungen

- Frisches **Debian 12**
- Root- oder sudo-Rechte
- Domain/Subdomain korrekt auf den Server geroutet

---

## 🚀 Verwendung

```bash
wget https://raw.githubusercontent.com/CryptixMCNetwork/Setups/main/nlmc.sh
chmod +x install_namelessmc.sh
sudo ./install_namelessmc.sh
