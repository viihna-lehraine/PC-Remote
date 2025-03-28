#!/bin/bash

# File: scripts/vault/fetch-vault-mgr-password.sh

set -euo pipefail

WORK_DIR="/home/viihna/Projects/pc-remote"
SECRET_DIR="$WORK_DIR/db/secrets"
SOPS_PGP_KEY_ID="B5BC332A603B022E21E46F2DA18BAE412BC0A77C"

ENCRYPTED_PASSWORD_PATH="$SECRET_DIR/vault_mgr_password.gpg"
DECRYPTED_PASSWORD_PATH="$SECRET_DIR/vault_mgr_password"

# create the secrets directory if it doesn't exist
mkdir -p "$SECRET_DIR"

# check if the encrypted password file exists
if [[ ! -f "$ENCRYPTED_PASSWORD_PATH" ]]; then
	echo "[!] Encrypted Vault manager password not found. Aborting."
	exit 1
fi

# decrypt the password using SOPS
echo "[*] Decrypting Vault manager password..."
sudo -u viihna env SOPS_PGP_KEY_ID="$SOPS_PGP_KEY_ID" \
	sops --decrypt \
	--input-type json \
	--output-type json \
	--pgp "$SOPS_PGP_KEY_ID" \
	--output "$DECRYPTED_PASSWORD_PATH" "$ENCRYPTED_PASSWORD_PATH"

# check if the decrypted password file exists
if [[ ! -f "$DECRYPTED_PASSWORD_PATH" ]]; then
	echo "[!] Decrypted Vault manager password file not found. Aborting."
	exit 1
fi

# read the password from the decrypted file
VAULT_MGR_PASSWORD=$(<"$DECRYPTED_PASSWORD_PATH")

# clear the decrypted password file for security reasons
shred -u "$DECRYPTED_PASSWORD_PATH"

# export the password for use by the calling script
export VAULT_MGR_PASSWORD

# print success message
echo "[✓] Vault manager password fetched and stored in environment variable."
