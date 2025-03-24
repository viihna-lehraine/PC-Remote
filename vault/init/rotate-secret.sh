#!/bin/sh

SECRET_ID=$(vault write -f -format=json auth/approle/role/pc-remote-role/secret-id | jq -r .data.secret_id)
echo "$SECRET_ID" >/vault/approle/secret_id
echo "[✓] Rotated and saved new Secret ID"

# ADD CRONJOB TO CALL THIS
