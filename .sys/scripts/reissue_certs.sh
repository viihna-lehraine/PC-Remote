#!/bin/bash

# File: scripts/reissue_certs.sh

set -euo pipefail

# variables
PROJECT_DIR=/etc/ssl/projects/pc-remote
ROOT_CA_DIR="$PROJECT_DIR/ca"
ROOT_CA_CRT="$ROOT_CA_DIR/rootCA.crt"
ROOT_CA_KEY="$ROOT_CA_DIR/rootCA.key"

# service-specific
DB_CERT_DIR="$PROJECT_DIR/services/db"
DB_CN="pc-remote-db"
DB_CSR="$DB_CERT_DIR/postgres.csr"
DB_CRT="$DB_CERT_DIR/postgres.crt"
DB_KEY="$DB_CERT_DIR/postgres.key"
DB_TLS_CONFIG="$DB_CERT_DIR/ecdsa.cnf"

echo "[*] Ensuring cert directory exists..."
sudo mkdir -p "$DB_CERT_DIR"

echo "[*] Clearing old DB certs..."
sudo rm -f "$DB_CSR" "$DB_CRT" "$DB_KEY"
echo "[*] Old certs removed."

echo "[*] Generating ECDSA private key..."
sudo openssl ecparam -genkey -name prime256v1 -out "$DB_KEY"

echo "[*] Generating CSR..."
sudo openssl req -new -key "$DB_KEY" \
	-subj "/CN=$DB_CN" \
	-out "$DB_CSR" \
	-config "$DB_TLS_CONFIG"

echo "[*] Signing certificate with Root CA..."
sudo openssl x509 -req \
	-in "$DB_CSR" \
	-CA "$ROOT_CA_CRT" \
	-CAkey "$ROOT_CA_KEY" \
	-CAcreateserial \
	-out "$DB_CRT" \
	-days 825 \
	-sha256 \
	-extfile "$DB_TLS_CONFIG" \
	-extensions v3_req

echo "[*] Setting permissions..."
sudo chown 999:999 "$DB_KEY" "$DB_CRT"
sudo chmod 600 "$DB_KEY"
sudo chmod 644 "$DB_CRT"

echo "Certificate issued and secured: CN=$DB_CN"
