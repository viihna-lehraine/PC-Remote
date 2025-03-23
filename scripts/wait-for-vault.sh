#!/bin/sh

# File: scripts/wait-for-vault.sh

set -e

VAULT_ADDR="https://192.168.50.10:4425"
# VAULT_TOKEN="$(gpg --decrypt /vault/keys/usk.json.gpg | jq -r '.[0]')"

command -v curl >/dev/null || {
	echo "curl is required but not installed." >&2
	exit 1
}

echo "[*] Waiting for Vault to be initialized..."
until curl --silent --insecure "$VAULT_ADDR/v1/sys/health" | grep -q '"initialized":true'; do
	sleep 1
done

echo "[*] Vault is initialized. Waiting for unseal..."
until curl --silent --insecure "$VAULT_ADDR/v1/sys/health" | grep -q '"sealed":false'; do
	sleep 1
done

echo "[✓] Vault is unsealed and ready."
