#!/bin/bash

# File: scripts/vault/notify-discord.sh

set -euo pipefail

TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/webhooks/discord.json.gpg"
SOPS_CONFIG="/home/viihna/Projects/pc-remote/.sops.yaml"

if [ ! -f "$TOKEN_PATH" ]; then
	echo "[✗] Encrypted webhook file not found: $TOKEN_PATH"
	exit 1
fi

WEBHOOK_URL="$(sops --config "$SOPS_CONFIG" --decrypt "$TOKEN_PATH" | jq -r '.webhook')"

if [ -z "$WEBHOOK_URL" ]; then
	echo "[✗] Failed to extract webhook URL from decrypted JSON."
	exit 1
fi

MESSAGE=${1:-"Vault operation complete!"}

curl -H "Content-Type: application/json" \
	-X POST \
	-d "{\"content\": \"$MESSAGE\"}" \
	"$WEBHOOK_URL"
