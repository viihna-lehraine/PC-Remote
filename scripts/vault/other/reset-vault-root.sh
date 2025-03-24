#!/bin/bash

# File: scripts/rotate-root-token.sh

set -euo pipefail

PROJECT_ROOT="/home/viihna/Projects/pc-remote"
TMP_TOKEN_FILE=$(mktemp)
ENCRYPTED_TOKEN_PATH="$PROJECT_ROOT/secrets/tokens/.vault-root-token.sops"
TEMP_ROOT_TOKEN_FILE="$PROJECT_ROOT/secrets/tmp/tmp-root-token.bak"
SOPS_PGP_KEY_ID="B5BC332A603B022E21E46F2DA18BAE412BC0A77C"
SOPS_CONFIG="$PROJECT_ROOT/.sops.yaml"

VAULT_TOKEN=$(sops --decrypt "$ENCRYPTED_TOKEN_PATH")
export VAULT_TOKEN

echo "[*] Creating new root token..."
NEW_TOKEN_JSON=$(vault token create -policy=root -ttl=5m -format=json)
NEW_TOKEN=$(echo "$NEW_TOKEN_JSON" | jq -r .auth.client_token)

echo "$NEW_TOKEN" >"$TMP_TOKEN_FILE"

echo "[*] Encrypting new root token with SOPS..."
if sudo -u viihna env SOPS_PGP_KEY_ID="$SOPS_PGP_KEY_ID" SOPS_CONFIG="$SOPS_CONFIG" \
	sops --config "$SOPS_CONFIG" \
	--encrypt --output "$ENCRYPTED_TOKEN_PATH" "$TMP_TOKEN_FILE"; then

	echo "[*] Shredding plaintext token..."
	shred -u "$TMP_TOKEN_FILE"

	echo "[*] Revoking old root token..."
	if vault token revoke "$VAULT_TOKEN"; then
		echo "[✓] Vault root token rotated and sanitized."
	else
		echo "[!] Old token already revoked or invalid."
	fi
else
	echo "[✗] Failed to encrypt new root token."
	cp "$TMP_TOKEN_FILE" "$TEMP_ROOT_TOKEN_FILE"
	echo "[!] Backup token saved at: $TEMP_ROOT_TOKEN_FILE"
	exit 1
fi
