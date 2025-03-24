#!/bin/sh

# File: vault/init/configure.sh

set -e

APPROLE_TMP="/tmp/approle"
MAX_RETRIES=10

mkdir -p "$APPROLE_TMP"

echo "[*] Applying policy..."
until vault policy write kv-secrets /vault/policies/kv-secrets.hcl; do
	echo "[!] Vault not ready, retrying policy upload..."
	sleep 1
done

echo "[*] Writing PC Remote Policy"
vault policy write pc-remote-policy /vault/policies/pc-remote.hcl || true

# enable secrets engine if not already enabled
if ! vault secrets list -format=json | grep -q '"postgresql/"'; then
	echo "[*] Enabling PostgreSQL secrets engine..."
	vault secrets enable -path=postgresql database
else
	echo "[✓] PostgreSQL secrets engine already enabled."
fi

# configure DB connection
DB_PASS=$(vault kv get -field=vault_mgr secret/pc-remote/db-creds 2>/dev/null || true)
if [ -z "$DB_PASS" ]; then
	echo "[✗] Failed to retrieve DB password from Vault. Aborting."
	exit 1
fi
if ! vault read postgresql/config/pc-remote-db >/dev/null 2>&1; then
	echo "[*] Configuring PostgreSQL connection..."
	vault write postgresql/config/pc-remote-db \
		plugin_name=postgresql-database-plugin \
		allowed_roles=viihna-app \
		connection_url="postgresql://{{username}}:{{password}}@pc-remote-db:4590/postgres?sslmode=verify-full&sslrootcert=/vault/ca/rootCA.crt" \
		username="vault_mgr" \
		password="$DB_PASS"
else
	echo "[✓] PostgreSQL connection already configured."
fi

# create dynamic DB role
if ! vault read postgresql/roles/viihna-app >/dev/null 2>&1; then
	echo "[*] Creating dynamic role viihna-app..."
	vault write postgresql/roles/viihna-app \
		db_name=pc-remote-db \
		creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT ALL PRIVILEGES ON DATABASE postgres TO \"{{name}}\";" \
		default_ttl="1h" \
		max_ttl="24h"
else
	echo "[✓] DB role viihna-app already exists."
fi

echo "[*] Enabling AppRole auth method..."
vault auth enable approle || true

# create AppRole
if ! vault list auth/approle/role | grep -q 'pc-remote-role'; then
	echo "[*] Creating AppRole: pc-remote-role"
	vault write auth/approle/role/pc-remote-role \
		token_policies="pc-remote-policy" \
		token_ttl="1h" \
		token_max_ttl="4h" \
		secret_id_ttl="24h"
else
	echo "[✓] AppRole pc-remote-role already exists."
fi

echo "[*] Waiting briefly to ensure AppRole is queryable..."
sleep 2

# save AppRole creds
for i in $(seq 1 $MAX_RETRIES); do
	echo "[*] Attempt $i: Fetching AppRole credentials..."

	# attempt to get ROLE_ID
	ROLE_ID_JSON=$(vault read -format=json auth/approle/role/pc-remote-role/role-id 2>/dev/null || true)
	ROLE_ID=$(echo "$ROLE_ID_JSON" | jq -r '.data.role_id' 2>/dev/null || true)

	# attempt to get SECRET_ID
	SECRET_ID_JSON=$(vault write -f -format=json auth/approle/role/pc-remote-role/secret-id 2>/dev/null || true)
	SECRET_ID=$(echo "$SECRET_ID_JSON" | jq -r '.data.secret_id' 2>/dev/null || true)

	# check both are non-empty
	if [ -n "$ROLE_ID" ] && [ -n "$SECRET_ID" ]; then
		echo "$ROLE_ID" >/vault/approle/role_id
		echo "$SECRET_ID" >/vault/approle/secret_id
		echo "[✓] Vault AppRole credentials saved to /vault/approle"
		break
	else
		echo "[!] Failed to fetch AppRole credentials, retrying..."
		sleep 2
	fi
done

# final bailout if still empty
if [ -z "$ROLE_ID" ] || [ -z "$SECRET_ID" ]; then
	echo "[✗] Gave up after $MAX_RETRIES attempts — AppRole credential fetch failed."
	exit 1
fi

echo "[*] Enabling PKI secrets engine..."
if ! vault secrets list -format=json | jq -e '."pki/" == null' >/dev/null; then
	echo "[*] Enabling PKI secrets engine..."
	vault secrets enable -path=pki pki
else
	echo "[✓] PKI secrets engine already enabled."
fi

# configure a role for issuing certificates (if not already configured)
ROLE_NAME="pc-remote-role"
if ! vault read pki/roles/$ROLE_NAME >/dev/null 2>&1; then
	echo "[*] Creating role $ROLE_NAME for issuing certificates..."
	vault write pki/roles/$ROLE_NAME \
		allowed_domains="pc-remote.local" \
		allow_subdomains=true \
		max_ttl="72h" \
		key_bits=2048 \
		key_type="rsa" \
		ttl="24h"
else
	echo "[✓] Role $ROLE_NAME already exists."
fi

chown -R viihna:viihna /vault/approle
