#!/bin/sh

set -e

echo "Starting Vault configuration..."

echo "Configuring Root Certificate..."
chmod 644 /vault/ca/rootCA.crt || true
echo "Root Certificate configured."

echo "Configuring CA Certificates..."
chown -R vault:vault /vault/certs
chmod 600 /vault/certs/vault.key
chmod 644 /vault/certs/vault.crt
echo "CA Certificates configured."

echo "Installing CA Certificates package and running CA certs update..."
apk add --no-cache ca-certificates
update-ca-certificates
cp /vault/ca/rootCA.crt /etc/ssl/certs/
echo "CA Certificates package installed and Vault certs updated."

echo "Setting environment variables..."
export VAULT_CACERT=/vault/ca/rootCA.crt

echo "Vault is running and ready for operation."
exit 0
