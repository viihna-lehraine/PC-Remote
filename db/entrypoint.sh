#!/bin/bash

set -euo pipefail

# Ensure the PostgreSQL data directory has the correct ownership and permissions
echo "[*] Ensuring correct ownership for PostgreSQL data directory..."
chown -R postgres:postgres /var/lib/postgresql/data
chmod 700 /var/lib/postgresql/data

# Optionally clean the data directory to ensure it's empty (WARNING: data will be lost)
echo "[*] Cleaning up PostgreSQL data directory (optional)..."
rm -rf /var/lib/postgresql/data/*

# Copy Vault-issued certs into writable volume
echo "[*] Copying Vault-issued certs into writable volume..."
mkdir -p /var/lib/postgresql/certs
cp /vault-certs/* /var/lib/postgresql/certs/

# Ensure the certs have the right permissions
chown -R postgres:postgres /var/lib/postgresql/certs
chmod 700 /var/lib/postgresql/certs
chmod 600 /var/lib/postgresql/certs/*.key
chmod 644 /var/lib/postgresql/certs/*.crt

echo "[✓] Certs copied and permissioned."

# Skip PostgreSQL initialization if data directory exists, and just continue
echo "[*] Checking if PostgreSQL data directory exists..."
if [ ! -d /var/lib/postgresql/data/pg_version ]; then
	echo "[*] PostgreSQL data directory does not exist. Initializing PostgreSQL database..."
	gosu postgres initdb
	echo "[✓] PostgreSQL initialized."
else
	echo "[✓] PostgreSQL data directory exists, skipping initialization."
fi

# Start PostgreSQL in the background
echo "[*] Starting PostgreSQL in the background..."
gosu postgres postgres -c config_file=/etc/postgresql/postgresql.conf &

# Wait for PostgreSQL to become ready
echo "[*] Waiting for PostgreSQL to accept connections..."
for _i in {1..20}; do
	if pg_isready -h 127.0.0.1 -p 4590 -U postgres >/dev/null 2>&1; then
		echo "[✓] PostgreSQL is ready."
		break
	fi
	sleep 1
done

# Check if Vault credentials are available
DB_PASS=$(tr -d '\r\n' </run/secrets/vault_mgr_password | sed "s/'/''/g")

# Ensure vault_mgr role and password match
echo "[*] Ensuring vault_mgr role and password match..."
psql -U postgres -d postgres -h 127.0.0.1 -p 4590 <<EOF
DO \$\$ BEGIN
   IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'vault_mgr') THEN
      RAISE NOTICE 'vault_mgr exists — updating password';
      ALTER ROLE vault_mgr WITH LOGIN PASSWORD '$DB_PASS';
   ELSE
      RAISE NOTICE 'vault_mgr does not exist — creating role';
      CREATE ROLE vault_mgr WITH LOGIN PASSWORD '$DB_PASS';
      GRANT CONNECT ON DATABASE postgres TO vault_mgr;
      GRANT USAGE, CREATE ON SCHEMA public TO vault_mgr;
      ALTER ROLE vault_mgr WITH NOINHERIT;
   END IF;
END \$\$;
EOF

touch /var/lib/postgresql/data/.vault-role-created

# Verify vault_mgr login works
echo "[*] Verifying vault_mgr login..."
for _i in {1..10}; do
	if PGPASSWORD="$DB_PASS" psql -U vault_mgr -h 127.0.0.1 -p 4590 -d postgres -c '\q' >/dev/null 2>&1; then
		echo "[✓] vault_mgr login verified."
		break
	fi
	sleep 1
done

# Cleanup and exit to allow PostgreSQL to keep running
echo "[✓] PostgreSQL setup complete."
exec tail -f /dev/null
