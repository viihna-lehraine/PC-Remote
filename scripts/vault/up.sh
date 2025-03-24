#!/bin/bash

# File: scripts/vault/up.sh

set -euo pipefail

APPROLE_CHECK_ATTEMPTS=10
APPROLE_VERIFIED=0
ENCRYPTED_TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token.sops"
DECRYPTED_TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token"
PROJECT_ROOT="/home/viihna/Projects/pc-remote"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
SOPS_CONFIG="$PROJECT_ROOT/.sops.yaml"
VAULT_ADDR="https://192.168.50.10:4425"
VAULT_CONTAINER="pc-remote-vault-1"

export SOPS_CONFIG VAULT_ADDR VAULT_CONTAINER

cd $PROJECT_ROOT

# decrypt Vault root token and export it
get_vault_token() {
	if [ ! -f "$DECRYPTED_TOKEN_PATH" ]; then
		echo "[*] Decrypting Vault root token with SOPS..."
		sops --config "$SOPS_CONFIG" --decrypt --output "$DECRYPTED_TOKEN_PATH" "$ENCRYPTED_TOKEN_PATH" || {
			echo "[!] Decryption failed. Manual cleanup recommended."
			exit 1
		}
	fi
	VAULT_TOKEN=$(cat "$DECRYPTED_TOKEN_PATH")
	export VAULT_TOKEN
	echo "[*] Shredding decrypted Vault root token..."
	shred -u "$DECRYPTED_TOKEN_PATH"
}

echo "[*] Fetching Vault root token..."
get_vault_token

echo "[*] Starting Vault and DB containers..."
docker compose up -d vault db

echo "[*] Waiting for Vault API to become available..."
until curl --silent --insecure "$VAULT_ADDR/v1/sys/health" | grep -q '"initialized":true'; do
	echo "[*] Vault not initialized yet, retrying..."
	sleep 5
done

echo "[*] Waiting for Vault to be unsealed..."
until curl --silent --insecure "$VAULT_ADDR/v1/sys/health" | grep -q '"sealed":false'; do
	echo "[*] Vault is sealed, retrying..."
	sleep 5
done

echo "[✓] Vault is unsealed and ready."

echo "[*] Waiting for PostgreSQL to become ready..."
until docker exec pc-remote-db pg_isready -U postgres -d postgres -p 4590 -h 127.0.0.1 >/dev/null 2>&1; do
	echo "[*] PostgreSQL not ready, retrying..."
	sleep 3
done
echo "[✓] PostgreSQL is ready."

echo "[*] Running Vault configuration script..."
docker exec -e VAULT_TOKEN="$VAULT_TOKEN" "$VAULT_CONTAINER" sh /vault/init/configure.sh

echo "[*] Enabling Vault secrets engine"
vault secrets enable -path=secret kv

echo "[*] Checking if Password Pepper already exists..."
if ! vault kv get -mount=secret pc-remote/pepper >/dev/null 2>&1; then
	echo "[*] Generating and storing password pepper..."
	vault kv put -mount=secret pc-remote/pepper value="$(openssl rand -hex 64)"
	echo "[✓] Password pepper stored in Vault as secret/pc-remote/pepper."
else
	echo "[✓] Password pepper already exists in Vault. Skipping..."
fi

echo "[*] Checking if session secret exists..."
if ! vault kv get -mount=secret pc-remote/session-secret >/dev/null 2>&1; then
	echo "[*] Generating and storing session secret..."
	SESSION_SECRET=$(openssl rand -hex 64)
	vault kv put -mount=secret pc-remote/session-secret session_secret="$SESSION_SECRET"
	echo "[✓] Session secret stored in Vault at secret/pc-remote/session-secret"
else
	echo "[✓] Session secret already exists. Skipping..."
fi

echo "[*] Checking if vault_mgr DB password is already stored..."
if ! vault kv get -mount=secret pc-remote/db-creds >/dev/null 2>&1; then
	echo "[*] Generating and storing DB password for vault_mgr..."
	vault kv put -mount=secret pc-remote/db-creds vault_mgr="$(openssl rand -base64 32)"
	echo "[✓] DB credentials stored at secret/pc-remote/db-creds"
else
	echo "[✓] DB credentials already exist, skipping."
fi

# ensure AppRole exists before trying to fetch it
echo "[*] Verifying AppRole exists before fetching credentials..."

for i in $(seq 1 "$APPROLE_CHECK_ATTEMPTS"); do
	if docker exec -e VAULT_TOKEN="$VAULT_TOKEN" "$VAULT_CONTAINER" vault read -field=role_id auth/approle/role/pc-remote-role/role-id >/dev/null 2>&1; then
		echo "[✓] AppRole verified."
		APPROLE_VERIFIED=1
		break
	else
		echo "[*] AppRole not available yet, retrying ($i/$APPROLE_CHECK_ATTEMPTS)..."
		sleep 1
	fi
done

if [ "$APPROLE_VERIFIED" -ne 1 ]; then
	echo "[!] AppRole setup failed after $APPROLE_CHECK_ATTEMPTS attempts. Aborting."
	exit 1
fi

echo "[*] Fixing AppRole directory permissions..."
sudo chown -R viihna:viihna "$PROJECT_ROOT/vault/approle"

echo "[*] Fetching AppRole credentials..."
cd $SCRIPTS_DIR/vault
./fetch-approle-credentials.sh "$VAULT_TOKEN"

echo "[*] Encrypting AppRole credentials..."
./encrypt-approle-creds.sh

echo "[*] Bringing up the rest of the stack..."
docker compose up -d

history -d "$(history 1)" 2>/dev/null || true

./verify.sh

./notify-discord.sh "Vault stack initialized and configured successfully" success
