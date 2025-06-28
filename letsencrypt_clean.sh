#!/bin/bash

set -e

echo "=== ALLE Let's Encrypt Zertifikate löschen (Certbot) ==="

# Prüfen ob certbot installiert ist
if ! command -v certbot &>/dev/null; then
    echo "Certbot ist nicht installiert. Abbruch."
    exit 1
fi

# Zertifikate auflisten
CERTS=$(certbot certificates 2>/dev/null | grep -oP '(?<=Certificate Name: ).*')

if [ -z "$CERTS" ]; then
    echo "Keine Zertifikate gefunden."
    exit 0
fi

echo "--- Gefundene Zertifikate:"
echo "$CERTS"
echo

read -p "Wirklich ALLE Zertifikate löschen? [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Abbruch durch Benutzer."
    exit 0
fi

# Alle Zertifikate einzeln löschen
for cert in $CERTS; do
    echo "-> Zertifikat löschen: $cert"
    certbot delete --cert-name "$cert" --non-interactive || echo "Fehler beim Löschen von $cert"
done

# Reste bereinigen (optional)
echo "--- Reste unter /etc/letsencrypt löschen ---"
rm -rf /etc/letsencrypt/live/*
rm -rf /etc/letsencrypt/archive/*
rm -rf /etc/letsencrypt/renewal/*

echo "=== Alle Let's Encrypt Zertifikate wurden entfernt ==="
