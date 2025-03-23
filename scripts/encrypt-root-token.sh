#!/bin/bash

# File: scripts/encrypt-root-token.sh

set -euo pipefail

WORK_DIR="/home/viihna/Projects/pc-remote"

cd $WORK_DIR

# path to the root token and the output encrypted file
ROOT_TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token"
ENCRYPTED_TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token.sops"

# encrypt the root token with SOPS
echo "[*] Encrypting root token with SOPS..."
sops --encrypt --output "$ENCRYPTED_TOKEN_PATH" "$ROOT_TOKEN_PATH" || {
	echo "[!] Encryption failed. Manual cleanup recommended."
	exit 1
}

# shred the plaintext root token to ensure it's completely removed
echo "[*] Shredding plaintext root token..."
shred -u "$ROOT_TOKEN_PATH"

echo "[✓] Root token encrypted and stored at $ENCRYPTED_TOKEN_PATH"
echo "[✓] Plaintext root token shredded."
