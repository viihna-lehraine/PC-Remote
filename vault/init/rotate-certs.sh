#!/bin/bash

# File: vault/init/rotate-certs.sh

set -euo pipefail

VAULT_ADDR="https://192.168.50.10:4425"
VAULT_CACERT="/etc/ssl/certs/rootCA.crt"
VAULT_SECRET_ROOT="secret/pc-remote/certs"
ISSUED_DIR="/vault/issued"

export VAULT_ADDR VAULT_CACERT

# Convert ISO timestamp to epoch
iso_to_epoch() {
	date -d "$1" +%s
}

rotate_cert_if_needed() {
	local cert_name=$1
	local common_name=$2
	local ip_sans=$3
	local ttl=$4

	local secret_path="${VAULT_SECRET_ROOT}/${cert_name}"
	local cert_path="${ISSUED_DIR}/${cert_name}.json"

	echo ""
	echo "[*] Checking certificate metadata for: ${cert_name}"

	EXPIRY=$(vault kv get -field=expires_at "$secret_path" 2>/dev/null || echo "")

	if [ -z "$EXPIRY" ]; then
		echo "[!] No expiry metadata found for ${cert_name}. Skipping rotation."
		return
	fi

	NOW_EPOCH=$(date +%s)
	EXPIRY_EPOCH=$(iso_to_epoch "$EXPIRY")
	SECS_LEFT=$((EXPIRY_EPOCH - NOW_EPOCH))

	if [ "$SECS_LEFT" -lt 86400 ]; then
		echo "[*] ${cert_name} expiring in <24h. Rotating now..."

		vault write -format=json "pki/intermediate/issue/${cert_name}" \
			common_name="${common_name}" \
			ip_sans="${ip_sans}" \
			ttl="${ttl}" >"${cert_path}"

		local now_ts
		now_ts=$(date --iso-8601=seconds)
		local new_expiry
		new_expiry=$(date -d "+${ttl}" --iso-8601=seconds)

		vault kv put "$secret_path" \
			issued_at="$now_ts" \
			expires_at="$new_expiry" \
			sans="$ip_sans"

		echo "[✓] ${cert_name} rotated. Metadata updated."
	else
		echo "[✓] ${cert_name} is still valid. No rotation needed."
	fi
}

# ---- configure per-service rotation ----
rotate_cert_if_needed db "pc-remote-db.local" "192.168.50.10" "72h"
rotate_cert_if_needed backend "pc-remote-backend.local" "192.168.50.10" "24h"
rotate_cert_if_needed nginx "pc-remote.local" "192.168.50.10" "72h"
rotate_cert_if_needed vault "vault.local" "192.168.50.10" "72h"
