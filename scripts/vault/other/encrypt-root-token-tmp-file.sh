#!/bin/bash

# File: scripts/encrypt-root-token-tmp-file.sh

set -euo pipefail

SOPS_PGP_KEY_ID="B5BC332A603B022E21E46F2DA18BAE412BC0A77C"
INPUT="/home/viihna/Projects/pc-remote/secrets/tmp/tmp-root-token.bak"
OUTPUT="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token.sops"

# encrypt the root token with SOPS
echo "[*] Encrypting root token with SOPS..."
sops \
	--encrypt \
	--config /dev/null \
	--pgp "$SOPS_PGP_KEY_ID" \
	--output "$OUTPUT" \
	"$INPUT"

# shred the plaintext root token to ensure it's completely removed
echo "[*] Shredding plaintext root token..."
shred -u "$INPUT"

echo "[✓] Root token encrypted and stored at $OUTPUT"
echo "[✓] Plaintext root token shredded."
