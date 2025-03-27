#!/bin/bash

# File: scripts/vault/reset-vault.sh

set -euo pipefail

VAULT_CONTAINER="pc-remote-vault-1"
PROJECT_ROOT="/home/viihna/Projects/pc-remote"
UNSEAL_KEYS_JSON="$PROJECT_ROOT/secrets/keys/usk.json"
UNSEALED_TMP="$PROJECT_ROOT/secrets/keys/.usk.json"
PLAIN_TOKEN_PATH="$PROJECT_ROOT/secrets/tokens/.vault-root-token"
ENCRYPTED_TOKEN_PATH="$PROJECT_ROOT/secrets/tokens/.vault-root-token.sops"
SOPS_CONFIG="$PROJECT_ROOT/.sops.yaml"
VAULT_DATA_DIR="$PROJECT_ROOT/vault/data"
VAULT_FILE_DIR="$PROJECT_ROOT/vault/file"

export SOPS_CONFIG

confirm() {
	read -r -p "⚠️  This will DELETE your Vault data. Are you sure? (yes/[no]): " response
	[[ "$response" == "yes" ]] || {
		echo "Aborted."
		exit 1
	}
}

echo "🚨 VAULT RESET SCRIPT 🚨"
confirm

echo "[*] Stopping and deleting Vault data volume..."
docker compose down -v --remove-orphans
docker compose build --no-cache

echo "[*] Wiping Vault data directory..."
sudo rm -rf "$VAULT_DATA_DIR"/*
sleep 1

echo "[*] Wiping Vault file directory..."
sudo rm -rf "$VAULT_FILE_DIR/*"
sleep 1

echo "[*] Starting Vault..."
docker compose up -d vault

echo "[*] Waiting for Vault to be healthy..."
until curl -sk -o /tmp/vault-health.json -w "%{http_code}" https://192.168.50.10:4425/v1/sys/health |
	grep -Eq '501|503'; do
	echo "[*] Waiting for uninitialized Vault..."
	sleep 2
done

echo "[*] Initializing Vault..."
INIT_OUTPUT=$(docker exec -i "$VAULT_CONTAINER" vault operator init -format=json -key-shares=5 -key-threshold=3)

echo "[*] Parsing unseal keys and root token..."
UNSEAL_KEYS=$(echo "$INIT_OUTPUT" | jq '{ unseal_keys: .unseal_keys_hex }')
ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')

echo "$UNSEAL_KEYS" >"$UNSEALED_TMP"
echo "$ROOT_TOKEN" >"$PLAIN_TOKEN_PATH"

mv "$UNSEALED_TMP" "$UNSEAL_KEYS_JSON"

cd $PROJECT_ROOT/scripts/vault

echo "[*] Removing existing encrypted key/token files..."
rm -f "$UNSEAL_KEYS_JSON.gpg" "$ENCRYPTED_TOKEN_PATH"

echo "[*] Encrypting unseal keys with SOPS..."
./usk.sh -e

echo "[*] Encrypting root token with SOPS..."
./encrypt-root-token.sh

echo "[✓] Vault has been reset and reinitialized."
echo "[✓] Keys stored securely in: $UNSEAL_KEYS_JSON"
echo "[✓] Root token encrypted at: $ENCRYPTED_TOKEN_PATH"

./notify-discord.sh "🚨 Vault has been reset and reinitialized on sharkie"
./notify-discord.sh "✅ Vault is up and fully configured"
