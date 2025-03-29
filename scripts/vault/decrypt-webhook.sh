#!/bin/bash

# File: scripts/vault/decrypt-webhook.sh

set -euo pipefail

WORK_DIR="/home/viihna/Projects/pc-remote"
SOPS_PGP_KEY_ID="B5BC332A603B022E21E46F2DA18BAE412BC0A77C"
ENCRYPTED_TOKEN="$WORK_DIR/secrets/webhooks/discord.json.gpg"
DECRYPTED_TOKEN="$WORK_DIR/secrets/webhooks/discord.json"

cd $WORK_DIR

sudo -u viihna env SOPS_PGP_KEY_ID="$SOPS_PGP_KEY_ID" \
	sops --decrypt \
	--config /dev/null \
	--pgp "$SOPS_PGP_KEY_ID" \
	--output "$DECRYPTED_TOKEN" "$ENCRYPTED_TOKEN"

cat "$DECRYPTED_TOKEN"

sudo shred -u "$DECRYPTED_TOKEN"

rm ~/.bash_history
