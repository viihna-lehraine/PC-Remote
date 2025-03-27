#!/bin/bash

# File: scripts/vault/vault-login.sh

set -euo pipefail

ENCRYPTED_TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token.sops"
DECRYPTED_TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token"
VAULT_ADDR="https://192.168.50.10:4425"

export SOPS_CONFIG="/home/viihna/Projects/pc-remote/.sops.yaml"
export VAULT_ADDR

# decrypt the root token only when needed
get_vault_token() {
	if [ ! -f "$DECRYPTED_TOKEN_PATH" ]; then
		echo "[*] Decrypting Vault root token with SOPS..."
		sops --config "$SOPS_CONFIG" --decrypt --output "$DECRYPTED_TOKEN_PATH" "$ENCRYPTED_TOKEN_PATH" || {
			echo "[!] Decryption failed. Manual cleanup recommended."
			exit 1
		}
	fi

	VAULT_TOKEN=$(<"$DECRYPTED_TOKEN_PATH")
	export VAULT_TOKEN

	echo "[*] Shredding decrypted Vault root token..."
	shred -u "$DECRYPTED_TOKEN_PATH"
}

# log in to Vault using the root token
login_to_vault() {
	echo "[*] Fetching Vault root token..."
	get_vault_token

	# silent API-based check to confirm login works
	echo "[*] Validating token with Vault..."
	if vault token lookup >/dev/null 2>&1; then
		echo "[✓] Logged in to Vault successfully (via token validation)."
	else
		echo "[!] Vault login failed. Token might be invalid or Vault is unreachable."
		exit 1
	fi
}

login_to_vault
