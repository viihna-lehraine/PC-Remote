#!/bin/bash

set -euo pipefail

# PROJECT_DIR="/home/viihna/Projects/pc-remote"

# generate a certificate for a given service (with ECDSA)
generate_cert() {
	SERVICE=$1
	COMMON_NAME=$2
	CERT_PATH=$3
	KEY_PATH=$4
	TTL=$5
	CA_CERT_PATH=$7 # Path to the root CA certificate
	CA_KEY_PATH=$8  # Path to the root CA private key

	echo "[*] Generating ECDSA certificate for $SERVICE..."

	# Issue certificate via Vault PKI with ECDSA and custom ecdsa.cnf
	vault write pki/issue/"$ROLE_NAME" \
		common_name="$COMMON_NAME" \
		ttl="$TTL" \
		ip_sans="192.168.50.10" \
		ecdsa_curve="P-256" \
		"ca_cert_file=$CA_CERT_PATH" \
		"ca_key_file=$CA_KEY_PATH" >/tmp/"$SERVICE"-cert.json

	# Extract cert and key from response and save to files
	CERT=$(jq -r '.data.certificate' /tmp/"$SERVICE"-cert.json)
	KEY=$(jq -r '.data.private_key' /tmp/"$SERVICE"-cert.json)

	# Write cert and key to files
	echo "$CERT" >"$CERT_PATH"
	echo "$KEY" >"$KEY_PATH"

	echo "[✓] ECDSA certificate and private key for $SERVICE saved to $CERT_PATH and $KEY_PATH."
}

# Define paths for your CA certificates
CA_CERT_PATH="/etc/ssl/projects/pc-remote/ca/rootCA.crt"
CA_KEY_PATH="/etc/ssl/projects/pc-remote/ca/rootCA.key"

# PostgreSQL certificate generation (referencing ecdsa.cnf)
generate_cert "postgresql" "pc-remote-db.pc-remote.local" "/etc/ssl/projects/pc-remote/services/db/postgres.crt" "/etc/ssl/projects/pc-remote/services/db/postgres.key" "24h" "/etc/ssl/projects/pc-remote/services/db/ecdsa.cnf" "$CA_CERT_PATH" "$CA_KEY_PATH"

# Nginx certificate generation (referencing ecdsa.cnf)
generate_cert "nginx" "pc-remote-nginx.pc-remote.local" "/etc/ssl/projects/pc-remote/services/nginx/server.crt" "/etc/ssl/projects/pc-remote/services/nginx/server.key" "24h" "/etc/ssl/projects/pc-remote/services/nginx/ecdsa.cnf" "$CA_CERT_PATH" "$CA_KEY_PATH"

# Vault certificate generation (referencing ecdsa.cnf)
generate_cert "vault" "pc-remote-vault.pc-remote.local" "/etc/ssl/projects/pc-remote/services/vault/vault.crt" "/etc/ssl/projects/pc-remote/services/vault/vault.key" "24h" "/etc/ssl/projects/pc-remote/services/vault/ecdsa.cnf" "$CA_CERT_PATH" "$CA_KEY_PATH"

# Client certificate generation (referencing ecdsa.cnf)
generate_cert "client" "viihna.pc-remote.local" "/etc/ssl/projects/pc-remote/client/client.crt" "/etc/ssl/projects/pc-remote/client/client.key" "24h" "/etc/ssl/projects/pc-remote/client/ecdsa.cnf" "$CA_CERT_PATH" "$CA_KEY_PATH"

# Backend certificate generation (referencing ecdsa.cnf)
generate_cert "backend" "pc-remote-backend.pc-remote.local" "/etc/ssl/projects/pc-remote/services/backend/server.crt" "/etc/ssl/projects/pc-remote/services/backend/server.key" "24h" "/etc/ssl/projects/pc-remote/services/backend/ecdsa.cnf" "$CA_CERT_PATH" "$CA_KEY_PATH"

echo "[✓] All certificates have been generated successfully."
