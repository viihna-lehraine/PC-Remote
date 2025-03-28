#!/bin/bash

# File: scripts/vault/encrypt-vault_mgr_password.sh

set -euo pipefail

WORK_DIR="/home/viihna/Projects/pc-remote"
SECRET_DIR="$WORK_DIR/db/secrets"
SOPS_PGP_KEY_ID="B5BC332A603B022E21E46F2DA18BAE412BC0A77C"

VAULT_MGR_PASSWORD_PATH="$SECRET_DIR/vault_mgr_password"
ENCRYPTED_PASSWORD_PATH="$SECRET_DIR/vault_mgr_password.gpg"

if [[ ! -f "$VAULT_MGR_PASSWORD_PATH" ]]; then
	echo "[!] Vault manager password not found. Aborting."
	exit 1
fi

VAULT_MGR_PASSWORD=$(<"$VAULT_MGR_PASSWORD_PATH")

# create temporary JSON file for the password
TEMP_JSON="$SECRET_DIR/vault_mgr_password.json"
cat <<EOF >"$TEMP_JSON"
{
    "vault_mgr_password": "$VAULT_MGR_PASSWORD"
}
EOF

echo "[*] Encrypting Vault manager password with SOPS..."
sudo -u viihna env SOPS_PGP_KEY_ID="$SOPS_PGP_KEY_ID" \
	sops --encrypt \
	--config /dev/null \
	--input-type json \
	--output-type json \
	--pgp "$SOPS_PGP_KEY_ID" \
	--output "$ENCRYPTED_PASSWORD_PATH" "$TEMP_JSON"

echo "[*] Shredding temporary plaintext password JSON..."
shred -u "$TEMP_JSON"

echo "[*] Taking ownership of plaintext Vault manager password file before shredding..."
sudo chown viihna:viihna "$VAULT_MGR_PASSWORD_PATH"

echo "[*] Shredding plaintext Vault manager password file..."
shred -u "$VAULT_MGR_PASSWORD_PATH"

echo "[✓] Encrypted Vault manager password written to: $ENCRYPTED_PASSWORD_PATH"
