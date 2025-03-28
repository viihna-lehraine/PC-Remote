#!/bin/bash

# File: scripts/vault/up.sh

set -euo pipefail

PROJECT_ROOT="/home/viihna/Projects/pc-remote"
APPROLE_CHECK_ATTEMPTS=10
APPROLE_VERIFIED=0
DB_CERT_PATH="$PROJECT_ROOT/secrets/certs/services/db/db.fullchain.crt"
ENCRYPTED_TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token.sops"
DECRYPTED_TOKEN_PATH="/home/viihna/Projects/pc-remote/secrets/tokens/.vault-root-token"
GPG_KEY_ID="B5BC332A603B022E21E46F2DA18BAE412BC0A77C"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
SOPS_CONFIG="$PROJECT_ROOT/.sops.yaml"
VAULT_ADDR="https://192.168.50.10:4425"
VAULT_CONTAINER="pc-remote-vault-1"

export SOPS_CONFIG VAULT_ADDR VAULT_CONTAINER

cd $PROJECT_ROOT

wait_for_db_cert() {
	echo "[*] Waiting for DB cert to be issued..."
	COUNT=0
	while [ ! -f "$DB_CERT_PATH" ]; do
		sleep 2
		COUNT=$((COUNT + 1))
		if [ "$COUNT" -ge 30 ]; then
			echo "[!] Timed out waiting for DB cert."
			exit 1
		fi
	done
	echo "[✓] DB cert found at $DB_CERT_PATH"
}

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

echo "[*] Starting Vault container..."
docker compose up -d vault

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

echo "[*] Logging into Vault on host (to run host CLI commands)..."
"$SCRIPTS_DIR/vault/vault-login.sh"

echo "[*] Enabling Vault secrets engine"
vault secrets enable -path=secret -version=2 kv

echo "[*] Checking if vault_mgr DB password is already stored..."
if ! vault kv get -mount=secret pc-remote/db-creds >/dev/null 2>&1; then
	echo "[*] Generating and storing DB password for vault_mgr..."
	vault kv put -mount=secret pc-remote/db-creds vault_mgr="$(openssl rand -base64 32)"
	echo "[✓] DB credentials stored at secret/pc-remote/db-creds"
else
	echo "[✓] DB credentials already exist, skipping."
fi

echo "[*] Writing vault_mgr password to temporary file for DB access..."
vault kv get -field=vault_mgr secret/pc-remote/db-creds >"$PROJECT_ROOT/db/secrets/vault_mgr_password"
chmod 600 "$PROJECT_ROOT/db/secrets/vault_mgr_password"

echo "[*] Checking if bootstrap DB superuser password exists..."
if ! vault kv get -mount=secret pc-remote/db-init >/dev/null 2>&1; then
	echo "[*] Generating and storing bootstrap POSTGRES_PASSWORD..."
	vault kv put -mount=secret pc-remote/db-init postgres="$(openssl rand -base64 32)"
	echo "[✓] Bootstrap POSTGRES_PASSWORD stored at secret/pc-remote/db-init"
else
	echo "[✓] Bootstrap POSTGRES_PASSWORD already exists. Skipping..."
fi

echo "[*] Running Vault configuration script..."
docker exec -e VAULT_TOKEN="$VAULT_TOKEN" "$VAULT_CONTAINER" sh /vault/init/configure.sh

echo "[*] Fixing cert ownership and permissions..."
cd $SCRIPTS_DIR/vault
sudo ./fix-cert-permissions.sh
cd "$PROJECT_ROOT"

# wait for DB cert before starting PostgreSQL
wait_for_db_cert

echo "[*] Starting database container now that cert is ready..."
BOOTSTRAP_DB_PASS=$(vault kv get -field=postgres secret/pc-remote/db-init)
sleep 1
export POSTGRES_PASSWORD="$BOOTSTRAP_DB_PASS"
echo "[*] Cleaning up any old db container (run)..."
docker rm -f pc-remote-db 2>/dev/null || true
echo "[*] Starting database container now that cert is ready..."
docker compose up -d db

echo "[*] Waiting for PostgreSQL to become ready..."
until docker exec pc-remote-db pg_isready -U postgres -d postgres -p 4590 -h 127.0.0.1 >/dev/null 2>&1; do
	echo "[*] PostgreSQL not ready, retrying..."
	sleep 3
done
echo "[✓] PostgreSQL is ready."

echo "[*] Configuring Vault DB secrets engine..."
MAX_RETRIES=10
RETRY_INTERVAL=3
attempt=1
until vault write postgresql/config/pc-remote-db \
	plugin_name=postgresql-database-plugin \
	allowed_roles=viihna-app \
	connection_url="postgresql://{{username}}:{{password}}@pc-remote-db:4590/postgres?sslmode=verify-full" \
	username="vault_mgr" \
	password="$(vault kv get -field=vault_mgr secret/pc-remote/db-creds)"; do

	echo "[!] Attempt $attempt failed. Retrying in $RETRY_INTERVAL seconds..."
	sleep $RETRY_INTERVAL
	attempt=$((attempt + 1))

	if [ "$attempt" -gt "$MAX_RETRIES" ]; then
		echo "[✗] Failed to configure Vault DB secrets engine after $MAX_RETRIES attempts."
		exit 1
	fi
done

echo "[✓] Vault DB secrets engine configured successfully."

vault write postgresql/config/pc-remote-db \
	plugin_name=postgresql-database-plugin \
	allowed_roles=viihna-app \
	connection_url="postgresql://{{username}}:{{password}}@pc-remote-db:4590/postgres?sslmode=verify-full" \
	username="vault_mgr" \
	password="$(vault kv get -field=vault_mgr secret/pc-remote/db-creds)" || echo "[✓] DB config already exists."

vault write postgresql/roles/viihna-app \
	db_name=pc-remote-db \
	creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT ALL PRIVILEGES ON DATABASE postgres TO \"{{name}}\";" \
	default_ttl="1h" \
	max_ttl="24h" || echo "[✓] DB role already exists."

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
	SESSION_SECRET=$(openssl rand -hex 32)
	vault kv put -mount=secret pc-remote/session-secret session_secret="$SESSION_SECRET"
	echo "[✓] Session secret stored in Vault at secret/pc-remote/session-secret"
else
	echo "[✓] Session secret already exists. Skipping..."
fi

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
cd "$SCRIPTS_DIR/vault"
./fetch-approle-credentials.sh "$VAULT_TOKEN"

echo "[*] Encrypting AppRole credentials..."
./encrypt-approle-creds.sh

echo "[*] Bringing up the rest of the stack..."
docker compose up -d

history -d "$(history 1)" 2>/dev/null || true

sudo chmod 700 /home/viihna/Projects/pc-remote/db/data

echo "[*] Cleaning up vault_mgr password file..."
shred -u "$PROJECT_ROOT/db/secrets/vault_mgr_password"

echo "[*] Rotating vault_mgr password in Vault..."
vault kv put -mount=secret pc-remote/db-creds vault_mgr="$(openssl rand -base64 32)"
echo "[✓] vault_mgr password rotated."

echo "[*] Writing Admin and Service policies..."
docker exec -e VAULT_TOKEN="$VAULT_TOKEN" pc-remote-vault-1 vault policy write \
	pc-remote-service /vault/policies/pc-remote-service.hcl
docker exec -e VAULT_TOKEN="$VAULT_TOKEN" pc-remote-vault-1 vault policy write \
	pc-remote-admin /vault/policies/pc-remote-admin.hcl

echo "[*] Creating standard token..."
echo "[*] Writing standard token policy to Vault..."
export VAULT_TOKEN="$VAULT_TOKEN"
vault write auth/token/roles/pc-remote-service \
	allowed_policies="pc-remote-service" \
	period="24h" \
	explicit_max_ttl="48h" \
	orphan=true
SERVICE_TOKEN=$(vault token create -policy=pc-remote-service -ttl=24h -format=json | jq -r '.auth.client_token')

echo "$SERVICE_TOKEN" >"$PROJECT_ROOT/secrets/tokens/.vault-service-token"
chmod 600 "$PROJECT_ROOT/secrets/tokens/.vault-service-token"

echo "[*] Encrypting service token..."
sops --config /dev/null --encrypt --pgp "$GPG_KEY_ID" --output "$PROJECT_ROOT/secrets/tokens/.vault-service-token.sops" "$PROJECT_ROOT/secrets/tokens/.vault-service-token"

echo "[*] Shredding unencrypted service token..."
shred -u "$PROJECT_ROOT/secrets/tokens/.vault-service-token"
echo "[✓] Encrypted service token stored."

echo "[*] Creating admin token..."
export VAULT_TOKEN="$VAULT_TOKEN"
vault write auth/token/roles/pc-remote-admin \
	allowed_policies="pc-remote-admin" \
	period="24h" \
	explicit_max_ttl="48h" \
	orphan=true
ADMIN_TOKEN=$(vault token create -policy=pc-remote-admin -ttl=72h -format=json | jq -r '.auth.client_token')

echo "$ADMIN_TOKEN" >"$PROJECT_ROOT/secrets/tokens/.vault-admin-token"
chmod 600 "$PROJECT_ROOT/secrets/tokens/.vault-admin-token"

echo "[*] Encrypting admin token..."
sops --config /dev/null --encrypt --pgp "$GPG_KEY_ID" --output "$PROJECT_ROOT/secrets/tokens/.vault-admin-token.sops" "$PROJECT_ROOT/secrets/tokens/.vault-admin-token"

echo "[*] Shredding unencrypted admin token..."
shred -u "$PROJECT_ROOT/secrets/tokens/.vault-admin-token"
echo "[✓] Encrypted admin token stored."

./verify.sh
# ./notify-discord.sh "Vault stack initialized and configured successfully" success

echo "[*] Purging root toke from memory..."
unset VAULT_TOKEN
echo "[*] Vault stack is up and running."
