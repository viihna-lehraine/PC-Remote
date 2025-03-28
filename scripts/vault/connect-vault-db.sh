#!/bin/bash

# File: scripts/vault/connect-vault-db.sh

# prompt for the Vault password (or fetch it securely from Vault)
read -rsp "Enter Vault password for database connection: " PGPASSWORD

# check if the password is provided
if [[ -z "$PGPASSWORD" ]]; then
	echo "Error: Password is required!"
	exit 1
fi

# define variables for database connection and SSL certs
DB_HOST="pc-remote-db"
DB_PORT="4590"
DB_USER="vault_mgr"
DB_NAME="postgres"
SSL_DIR="/etc/ssl/certs"
SSL_CERT="$SSL_DIR/db.fullchain.crt"
SSL_KEY="$SSL_DIR/db.key"
SSL_CA="$SSL_DIR/rootCA.crt"

# verify if the SSL certs exist
if [[ ! -f "$SSL_CERT" || ! -f "$SSL_KEY" || ! -f "$SSL_CA" ]]; then
	echo "Error: One or more SSL certificate files are missing!"
	exit 1
fi

# connect to the database using psql
docker exec -it vault-container-name bash -c "
  export PGPASSWORD='$PGPASSWORD';
  psql -h $DB_HOST -U $DB_USER -p $DB_PORT -d $DB_NAME \
    sslmode=require \
    sslrootcert=$SSL_CA \
    sslcert=$SSL_CERT \
    sslkey=$SSL_KEY
"

unset PGPASSWORD
