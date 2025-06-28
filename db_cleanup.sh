#!/bin/bash

echo "⚠️  WARNUNG: Dieses Skript löscht alle MySQL-User und Datenbanken außer 'root' und Systemdatenbanken."
read -p "Fortfahren? (j/N): " confirm
[[ "$confirm" != "j" && "$confirm" != "J" ]] && echo "Abbruch." && exit 1

read -p "MySQL root-Benutzer (default: root): " DB_ROOT_USER
DB_ROOT_USER=${DB_ROOT_USER:-root}

read -s -p "MySQL root-Passwort: " DB_ROOT_PASS
echo

EXCLUDE_DBS="'mysql','information_schema','performance_schema','sys'"

# Benutzerabfrage mit korrekt escaped SQL
USERS=$(mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASS" -N -B -e "
SELECT CONCAT('DROP USER IF EXISTS \"', user, '\"@\"', host, '\";') 
FROM mysql.user 
WHERE user != 'root';
")

# Datenbankabfrage
DATABASES=$(mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASS" -N -B -e "
SELECT CONCAT('DROP DATABASE IF EXISTS \`', schema_name, '\`;') 
FROM information_schema.schemata 
WHERE schema_name NOT IN (${EXCLUDE_DBS});
")

# Ausführen
echo "$USERS" | mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASS"
echo "$DATABASES" | mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASS"

echo "✅ Alle Benutzer (außer root) und alle nicht-Systemdatenbanken wurden entfernt."
