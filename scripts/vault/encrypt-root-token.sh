#!/bin/bash

# File: scripts/vault/encrypt-root-token.sh

set -euo pipefail

WORK_DIR="/home/viihna/Projects/pc-remote"
ROOT_TOKEN_PATH="$WORK_DIR/secrets/tokens/.vault-root-token"
ENCRYPTED_TOKEN_PATH="$WORK_DIR/secrets/tokens/.vault-root-token.sops"
SOPS_PGP_KEY_ID="B5BC332A603B022E21E46F2DA18BAE412BC0A77C"
SOPS_CONFIG="$WORK_DIR/.sops.yaml"

cd $WORK_DIR

# encrypt the root token with SOPS
echo "[*] Encrypting root token with SOPS..."
if sudo -u viihna env SOPS_PGP_KEY_ID="$SOPS_PGP_KEY_ID" SOPS_CONFIG="$SOPS_CONFIG" \
	sops \
	--config "$SOPS_CONFIG" \
	--encrypt \
	--pgp "$SOPS_PGP_KEY_ID" \
	--output "$ENCRYPTED_TOKEN_PATH" \
	"$ROOT_TOKEN_PATH"; then

	# shred the plaintext root token to ensure it's completely removed
	echo "[*] Shredding plaintext root token..."
	shred -u "$ROOT_TOKEN_PATH"

	echo "[✓] Root token encrypted and stored at $ENCRYPTED_TOKEN_PATH"
	echo "[✓] Plaintext root token shredded."
else
	echo "[!] Encryption failed. Manual cleanup recommended."
	exit 1
fi
