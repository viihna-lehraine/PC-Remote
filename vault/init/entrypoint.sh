#!/bin/sh

# File: vault/init/entrypoint.sh

set -e

echo "Starting Vault configuration (running entrypoint.sh)..."

echo "Fixing permissions for mounted certificates..."
chown -R vault:vault /vault/certs/vault
chmod 600 /vault/certs/vault/vault.key
chmod 644 /vault/certs/vault/vault.fullchain.crt
chmod 644 /vault/ca/root/rootCA.crt || true
echo "[✓] Vault cert permissions configured."

echo "Installing CA certificates package..."
apk add --no-cache ca-certificates

echo "Copying rootCA into system trust store..."
cp /vault/ca/root/rootCA.crt /usr/local/share/ca-certificates/rootCA.crt

echo "Updating system trust store..."
update-ca-certificates
echo "[✓] Root CA trusted by system."

echo "Exporting Vault environment variables..."
export VAULT_CACERT=/etc/ssl/certs/rootCA.crt
echo "[✓] VAULT_CACERT set to /etc/ssl/certs/rootCA.crt"

echo "Vault is ready to launch (entrypoint.sh completed)."
exec vault server -config=/vault/config/config.hcl
