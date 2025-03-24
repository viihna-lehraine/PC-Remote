#!/bin/bash

# File: scripts/vault/encrypt-approle-creds.sh

set -euo pipefail

WORK_DIR="/home/viihna/Projects/pc-remote"
APPROLE_DIR="$WORK_DIR/vault/approle"
SOPS_PGP_KEY_ID="B5BC332A603B022E21E46F2DA18BAE412BC0A77C"

ROLE_ID_PATH="$APPROLE_DIR/role_id"
SECRET_ID_PATH="$APPROLE_DIR/secret_id"
TEMP_JSON="$APPROLE_DIR/credentials.json"
ENCRYPTED_JSON="$APPROLE_DIR/credentials.json.gpg"

if [[ ! -f "$ROLE_ID_PATH" || ! -f "$SECRET_ID_PATH" ]]; then
	echo "[!] AppRole plaintext files not found. Aborting."
	exit 1
fi

ROLE_ID=$(<"$ROLE_ID_PATH")
SECRET_ID=$(<"$SECRET_ID_PATH")

cat <<EOF >"$TEMP_JSON"
{
	"role_id": "$ROLE_ID",
	"secret_id": "$SECRET_ID"
}
EOF

echo "[*] Encrypting AppRole credentials with SOPS (manual config override)..."
sudo -u viihna env SOPS_PGP_KEY_ID="$SOPS_PGP_KEY_ID" \
	sops --encrypt \
	--config /dev/null \
	--input-type json \
	--output-type json \
	--pgp "$SOPS_PGP_KEY_ID" \
	--output "$ENCRYPTED_JSON" "$TEMP_JSON"

echo "[*] Shredding temporary plaintext JSON..."
shred -u "$TEMP_JSON"

echo "[*] Shredding plaintext AppRole files..."
shred -u "$ROLE_ID_PATH" "$SECRET_ID_PATH"

echo "[✓] Encrypted AppRole credentials written to: $ENCRYPTED_JSON"
