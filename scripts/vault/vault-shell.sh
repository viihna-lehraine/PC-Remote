#!/bin/bash

# File: vault-shell.sh

set -euo pipefail

readonly ENCRYPTED_TOKEN="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token.sops"
readonly DECRYPTED_TOKEN="/tmp/.vault-token.$$"
readonly SOPS_CONFIG="/home/viihna/Projects/pc-remote/.sops.yaml"
readonly VAULT_ADDR="https://192.168.50.10:4425"
readonly VAULT_CACERT="/home/viihna/Projects/pc-remote/secrets/certs/ca/root/rootCA.crt"

export SOPS_CONFIG VAULT_ADDR VAULT_CACERT

# Clean up decrypted token on exit or interrupt
cleanup() {
	if [[ -f "$DECRYPTED_TOKEN" ]]; then
		echo "[*] Cleaning up decrypted Vault token..."
		shred -u "$DECRYPTED_TOKEN"
	fi
}
trap cleanup EXIT INT TERM

echo "[*] Decrypting Vault root token with SOPS..."
sops --config "$SOPS_CONFIG" --decrypt --output "$DECRYPTED_TOKEN" "$ENCRYPTED_TOKEN"

VAULT_TOKEN="$(<"$DECRYPTED_TOKEN")"
export VAULT_TOKEN

echo "[*] Logging into Vault..."
vault login "$VAULT_TOKEN" >/dev/null 2>&1 && echo "[✓] Authenticated with Vault."

echo "[*] Entering Vault shell... (type 'exit' to leave)"
bash --rcfile <(
	printf "export VAULT_TOKEN='%s'\n" "$VAULT_TOKEN"
	printf "printf '[Vault Shell Ready] %s\\n\\n'\n" "$VAULT_ADDR"
)
