#!/bin/bash

# File: scripts/up.sh

set -euo pipefail

VAULT_ADDR="https://192.168.50.10:4425"
VAULT_CONTAINER="pc-remote-vault-1"

ENCRYPTED_TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token.sops"
DECRYPTED_TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token"

# Decrypt the Vault root token only when needed, and shred it after use
get_vault_token() {
	# decrypt the token only if it doesn't already exist in plaintext
	if [ ! -f "$DECRYPTED_TOKEN_PATH" ]; then
		echo "[*] Decrypting Vault root token with SOPS..."
		sops --decrypt --output "$DECRYPTED_TOKEN_PATH" "$ENCRYPTED_TOKEN_PATH" || {
			echo "[!] Decryption failed. Manual cleanup recommended."
			exit 1
		}
	fi

	# read the decrypted token
	VAULT_TOKEN=$(cat "$DECRYPTED_TOKEN_PATH")

	# shred the decrypted token to ensure it's completely removed after use
	echo "[*] Shredding decrypted Vault root token..."
	shred -u "$DECRYPTED_TOKEN_PATH"
}

# fetch AppRole credentials first to ensure they are available for later configuration
echo "[*] Fetching AppRole credentials..."
./fetch-approle-credentials.sh "$VAULT_TOKEN" || {
	echo "[!] Failed to fetch AppRole credentials. Aborting."
	exit 1
}

echo "[*] Starting Vault container..."
docker compose up -d vault

echo "[*] Waiting for Vault to initialize and unseal..."
./wait-for-vault.sh

echo "[*] Checking if Vault is sealed..."
if curl --silent --insecure "$VAULT_ADDR/v1/sys/health" | grep -q '"sealed":true'; then
	echo "[*] Vault is sealed — running unseal script..."
	./unseal.sh
else
	echo "[✓] Vault already unsealed."
fi

# decrypt the root token before containuing
echo "[*] Fetching Vault root token..."
get_vault_token

echo "[*] Checking if Vault is already configured..."
if docker exec "$VAULT_CONTAINER" vault read -field=role_id auth/approle/role/pc-remote-role/role-id >/dev/null 2>&1; then
	echo "[✓] Vault already configured."
else
	echo "[*] Configuring Vault (policies, DB, AppRole)..."
	docker exec -e VAULT_TOKEN="$VAULT_TOKEN" "$VAULT_CONTAINER" sh /vault/init/configure.sh
fi

# encrypt the AppRole credentials
echo "[*] Encrypting AppRole creds with SOPS..."
./encrypt-approle.sh || {
	echo "[!] SOPS encryption failed. Manual cleanup recommended."
	exit 1
}

echo "[*] Bringing up the rest of the stack..."
docker compose up -d

echo "[*] Rotating root token..."
NEW_TOKEN=$(vault token create -policy=root -ttl=5m -format=json | jq -r .auth.client_token)

echo "[*] Revoking old root token..."
vault token revoke "$VAULT_TOKEN" || echo "[!] Old token already revoked or invalid."

# write new token to temp file for encryption
TMP_TOKEN_FILE=$(mktemp)
echo "$NEW_TOKEN" >"$TMP_TOKEN_FILE"

echo "[*] Encrypting new root token with SOPS..."
sops --encrypt --output "$ENCRYPTED_TOKEN_PATH" "$TMP_TOKEN_FILE"

echo "[*] Shredding plaintext token..."
shred -u "$TMP_TOKEN_FILE"

echo "[✓] Vault root token encrypted at $ENCRYPTED_TOKEN_PATH"

# wipe from shell history
history -d "$(history 1)" 2>/dev/null || true

echo "[✓] Vault root token rotated and sanitized."
