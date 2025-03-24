#!/bin/bash

File: scripts/vaultvault-login.sh

set -euo pipefail

ENCRYPTED_TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token.sops"
DECRYPTED_TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token"
VAULT_ADDR="https://192.168.50.10:4425"

export SOPS_CONFIG="/home/viihna/Projects/pc-remote/.sops.yaml"

# decrypt the root token only when needed
get_vault_token() {
	# decrypt the root token using SOPS if it hasn't been decrypted yet
	if [ ! -f "$DECRYPTED_TOKEN_PATH" ]; then
		echo "[*] Decrypting Vault root token with SOPS..."
		sops --decrypt --output "$DECRYPTED_TOKEN_PATH" "$ENCRYPTED_TOKEN_PATH" || {
			echo "[!] Decryption failed. Manual cleanup recommended."
			exit 1
		}
	fi

	VAULT_TOKEN=$(cat "$DECRYPTED_TOKEN_PATH")
	echo "[*] Shredding decrypted Vault root token..."
	shred -u "$DECRYPTED_TOKEN_PATH"
}

# log in to Vault using the root token
login_to_vault() {
	echo "[*] Fetching Vault root token..."
	get_vault_token

	# set the VAULT_ADDR environment variable and export the decrypted token
	export VAULT_ADDR
	export VAULT_TOKEN

	echo "[*] Logging into Vault..."
	vault login "$VAULT_TOKEN" || {
		echo "[!] Vault login failed. Please check the token and Vault server status."
		exit 1
	}

	echo "[✓] Logged in to Vault successfully."
}

# run the login function
login_to_vault
