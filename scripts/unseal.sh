#!/bin/bash

# File: scripts/init_vault.sh

set -euo pipefail

KEYFILE="/home/viihna/Projects/pc-remote/.sops/usk.json"
ENCRYPTED_KEYFILE="/home/viihna/Projects/pc-remote/.sops/usk.json.gpg"
VAULT_ADDR="https://192.168.50.10:4425"
VAULT_CACERT="/etc/ssl/projects/pc-remote/ca/rootCA.crt"

export VAULT_ADDR
export VAULT_CACERT

# decrypt the key file if needed
if [[ ! -f "$KEYFILE" ]]; then
	if [[ -f "$ENCRYPTED_KEYFILE" ]]; then
		echo "🔐 Decrypting encrypted key file via usk..."
		sudo /home/viihna/Projects/pc-remote/scripts/usk.sh -d
	else
		echo "Error: No unseal key file found!"
		exit 1
	fi
fi

# load and check keys
echo "Reading unseal keys from $KEYFILE..."
if ! jq empty "$KEYFILE" >/dev/null 2>&1; then
	echo "Error: JSON format invalid. Shredding and exiting."
	sudo shred -u "$KEYFILE"
	exit 1
fi

mapfile -t UNSEAL_KEYS < <(jq -r '.unseal_keys[]' "$KEYFILE")

if [[ ${#UNSEAL_KEYS[@]} -eq 0 ]]; then
	echo "No unseal keys found!"
	sudo shred -u "$KEYFILE"
	exit 1
fi

echo "Unsealing Vault with ${#UNSEAL_KEYS[@]} keys..."
for key in "${UNSEAL_KEYS[@]}"; do
	echo "→ Applying key: ${key:0:4}****"
	docker exec -e VAULT_ADDR="$VAULT_ADDR" -i pc-remote-vault-1 vault operator unseal "$key" || true
	sleep 1
done

echo "Attempted all keys."
echo "Shredding unseal key file for safety..."
sudo shred -u "$KEYFILE"
echo "Done."

echo "Initializing unsealed vault."
docker exec -it pc-remote-vault /bin/sh /vault/init/configure.sh
