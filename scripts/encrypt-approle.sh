#!/bin/bash

# File: scripts/encrypt-approle.sh

set -euo pipefail

APPROLE_DIR="./vault/approle"
PLAINTEXT="$APPROLE_DIR/approle.json"
ENCRYPTED="$APPROLE_DIR/approle.sops.json"

if [[ ! -f "$APPROLE_DIR/role_id" || ! -f "$APPROLE_DIR/secret_id" ]]; then
	echo "[!] Missing role_id or secret_id. Aborting SOPS encryption."
	exit 1
fi

echo "[*] Preparing JSON for SOPS encryption..."

jq -n \
	--arg role_id "$(cat "$APPROLE_DIR/role_id")" \
	--arg secret_id "$(cat "$APPROLE_DIR/secret_id")" \
	'{data: {role_id: $role_id, secret_id: $secret_id}}' >"$PLAINTEXT"

echo "[*] Encrypting with SOPS..."
sops --encrypt --output "$ENCRYPTED" "$PLAINTEXT"

echo "[*] Shredding raw credentials..."
shred -u "$APPROLE_DIR/role_id" "$APPROLE_DIR/secret_id" "$PLAINTEXT"

echo "[✓] Encrypted AppRole credentials stored at:"
echo "    $ENCRYPTED"
