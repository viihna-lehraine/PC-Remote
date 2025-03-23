#!/bin/bash

set -euo pipefail

APPROLE_DIR="./vault/approle"
ROLE_NAME="pc-remote-role"

# Create the approle directory if it doesn't exist
mkdir -p "$APPROLE_DIR"

# Ensure VAULT_TOKEN is available (can be passed from the parent script)
if [[ -z "${VAULT_TOKEN:-}" ]]; then
	echo "[!] VAULT_TOKEN is not set. Exiting."
	exit 1
fi

export VAULT_TOKEN

# Fetch the role_id
echo "[*] Fetching AppRole role_id..."
vault read -field=role_id auth/approle/role/"$ROLE_NAME"/role-id >"$APPROLE_DIR/role_id"

# Fetch the secret_id
echo "[*] Fetching AppRole secret_id..."
vault write -f -field=secret_id auth/approle/role/"$ROLE_NAME"/secret-id >"$APPROLE_DIR/secret_id"

# Check if the role_id and secret_id were successfully fetched
if [[ ! -f "$APPROLE_DIR/role_id" || ! -f "$APPROLE_DIR/secret_id" ]]; then
	echo "[!] Missing role_id or secret_id. Aborting."
	exit 1
fi

echo "[✓] AppRole credentials fetched successfully."
echo "[✓] role_id and secret_id saved in $APPROLE_DIR"

./encrypt-approle.sh
