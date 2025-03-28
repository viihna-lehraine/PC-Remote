#!/bin/bash

# File: scripts/vault/get-service-token.sh

set -euo pipefail

TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-service-token.sops"
SOPS_CONFIG="/home/viihna/Projects/pc-remote/.sops.yaml"

if [ ! -f "$TOKEN_PATH" ]; then
	echo "[!] Service token not found!"
	exit 1
fi

VAULT_TOKEN=$(sops --config "$SOPS_CONFIG" --decrypt "$TOKEN_PATH")
export VAULT_TOKEN
echo "[✓] Vault service token decrypted and exported."
