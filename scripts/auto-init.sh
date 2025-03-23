#!/bin/sh

set -e

echo "[*] Waiting for Vault to be initialized..."
./scripts/wait-for-vault.sh

if vault status 2>&1 | grep -q 'sealed'; then
	echo "[*] Vault is sealed — running unseal.sh..."
	./scripts/unseal.sh
else
	echo "[✓] Vault already unsealed."
fi

echo "[✓] Vault is ready. Run the following to configure:"
echo "    docker exec -i pc-remote-vault sh /vault/init/configure.sh"
