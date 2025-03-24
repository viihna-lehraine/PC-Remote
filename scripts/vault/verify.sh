#!/bin/bash

# File: scripts/vault/vault/verify.sh

set -eou pipefail

echo "[*] Checking Vault status..."
vault status | grep -q 'Sealed.*false' || {
	echo "[!] Vault is sealed or unavailable"
	exit 1
}

echo "[*] Verifying policies..."
vault policy read kv-secrets >/dev/null
vault policy read pc-remote-policy >/dev/null

echo "[*] Verifying secrets engines..."
vault secrets list -format=json | grep -q '"postgresql/"'
vault secrets list -format=json | grep -q '"secret/"'

echo "[✓] Vault configuration appears correct"
