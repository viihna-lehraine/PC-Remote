#!/bin/bash

# File: scripts/vault/rotate-approle-secret.sh

set -euo pipefail

VAULT_ADDR="https://192.168.50.10:4425"
ROLE_NAME="pc-remote-role"
APPROLE_DIR="/home/viihna/Projects/pc-remote/vault/approle"
SOPS_CONFIG="/home/viihna/Projects/pc-remote/.sops.yaml"
SOPS_PGP_KEY_ID="B5BC332A603B022E21E46F2DA18BAE412BC0A77C"
ENCRYPTED_JSON="$APPROLE_DIR/credentials.json.gpg"

export VAULT_ADDR

echo "[*] Rotating Secret ID for AppRole: $ROLE_NAME..."

# Fetch existing Role ID
ROLE_ID=$(vault read -field=role_id "auth/approle/role/$ROLE_NAME/role-id")

# Generate a new Secret ID
SECRET_ID=$(vault write -f -field=secret_id "auth/approle/role/$ROLE_NAME/secret-id")

# Save to encrypted JSON
TEMP_JSON=$(mktemp)
cat <<EOF >"$TEMP_JSON"
{
	"role_id": "$ROLE_ID",
	"secret_id": "$SECRET_ID"
}
EOF

echo "[*] Encrypting rotated AppRole credentials..."
sudo -u viihna env SOPS_PGP_KEY_ID="$SOPS_PGP_KEY_ID" SOPS_CONFIG="$SOPS_CONFIG" \
	sops --encrypt --output "$ENCRYPTED_JSON" "$TEMP_JSON"

echo "[*] Shredding temporary plaintext AppRole JSON..."
shred -u "$TEMP_JSON"

echo "[✓] Secret ID rotated and credentials saved to: $ENCRYPTED_JSON"
