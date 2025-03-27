#!/bin/bash

# File: scripts/vault/issue-all-certs.sh

set -euo pipefail

VAULT_ADDR="https://192.168.50.10:4425"
export VAULT_ADDR

BASE_DIR="/etc/ssl/projects/pc-remote/services"
ROLE="pc-remote-role"
TTL="72h"

# format: name|CN|SAN|file_prefix
SERVICES=(
	"backend|pc-remote-backend.local|pc-remote.local,192.168.50.10|server"
	"nginx|pc-remote.local|pc-remote.local,192.168.50.10|server"
	"db|pc-remote-db|pc-remote-db.local,pc-remote.local,pc-remote-db,127.0.0.1,192.168.50.10|postgres"
	"vault|vault.local|vault.local,192.168.50.10|vault"
	"client|viihna|viihna|viihna"
)

issue_cert() {
	local name="$1"
	local cn="$2"
	local alt_names="$3"
	local prefix="$4"
	local out_dir="$BASE_DIR/$name"

	echo "[*] Issuing ECDSA certificate for $name..."
	sudo mkdir -p "$out_dir"
	TEMP_JSON=$(mktemp)

	vault write -format=json "pki/issue/$ROLE" \
		common_name="$cn" \
		alt_names="$alt_names" \
		ttl="$TTL" \
		key_type="ec" \
		key_bits="256" >"$TEMP_JSON"

	sudo jq -r .data.certificate "$TEMP_JSON" | sudo tee "$out_dir/$prefix.crt" >/dev/null
	sudo jq -r .data.private_key "$TEMP_JSON" | sudo tee "$out_dir/$prefix.key" >/dev/null
	sudo jq -r .data.issuing_ca "$TEMP_JSON" | sudo tee "$out_dir/$prefix.ca" >/dev/null

	rm -f "$TEMP_JSON"

	echo "[✓] $name cert issued at $out_dir"
}

for entry in "${SERVICES[@]}"; do
	IFS='|' read -r name cn alt prefix <<<"$entry"
	issue_cert "$name" "$cn" "$alt" "$prefix"
done

# Apply correct ownership and permissions
sudo ./fix-cert-permissions.sh

echo "[*] Restarting services to pick up new certs..."
docker restart pc-remote-nginx pc-remote-db pc-remote-backend pc-remote-vault-1

echo "[✓] All certs reissued, permissions fixed, and services restarted."
