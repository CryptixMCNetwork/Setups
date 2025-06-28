#!/bin/bash

echo "⚠️  WARNUNG: Dieses Skript löscht alle MySQL-User und Datenbanken außer 'root' und Systemdatenbanken."
read -p "Fortfahren? (j/N): " confirm
[[ "$confirm" != "j" && "$confirm" != "J" ]] && echo "Abbruch." && exit 1

read -p "MySQL root-Benutzer (default: root): " DB_ROOT_USER
DB_ROOT_USER=${DB_ROOT_USER:-root}

read -s -p "MySQL root-Passwort: " DB_ROOT_PASS
echo

echo "[+] Verbinde zu MySQL..."

# Datenbanken außer Systemdatenbanken
EXCLUDE_DBS="'mysql','information_schema','performance_schema','sys'"

mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASS" -N -B -e "
-- Lösche alle Benutzer außer 'root'
SELECT CONCAT('DROP USER IF EXISTS '\''', user, '\'\'@\'', host, '\''';') 
FROM mysql.user 
WHERE user != 'root';
" | mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASS"

# Jetzt die Datenbanken löschen (außer System)
mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASS" -N -B -e "
SELECT CONCAT('DROP DATABASE IF EXISTS \`', schema_name, '\`;') 
FROM information_schema.schemata 
WHERE schema_name NOT IN (${EXCLUDE_DBS});
" | mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASS"

echo "✅ Alle Benutzer (außer root) und alle nicht-Systemdatenbanken wurden entfernt."
