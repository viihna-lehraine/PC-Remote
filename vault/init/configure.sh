#!/bin/sh

# File: vault/init/configure.sh

set -e

APPROLE_TMP="/tmp/approle"
ISSUED_DIR="/vault/issued"
ISSUE_RETRIES=5
MAX_RETRIES=10
SERVICES="db backend vault nginx"
DOMAIN_SUFFIX="pc-remote.local"

secure_delete() {
	FILE="$1"
	if [ -f "$FILE" ]; then
		chown vault:vault "$FILE" 2>/dev/null || true
		chmod u+rw "$FILE" 2>/dev/null || true
		shred -n 3 -z "$FILE" 2>/dev/null || true
		rm -f "$FILE"
		echo "[✓] Securely deleted: $FILE"
	fi
}

umask 077

if [ -z "$VAULT_TOKEN" ]; then
	echo "[✗] VAULT_TOKEN not set. Cannot authenticate to Vault."
	exit 1
fi
export VAULT_TOKEN

mkdir -p "$APPROLE_TMP" "$ISSUED_DIR"
chown vault:vault "$ISSUED_DIR"

echo "[*] Applying policies..."
until vault policy write kv-secrets /vault/policies/kv-secrets.hcl; do
	echo "[!] Vault not ready, retrying..."
	sleep 1
done
vault policy write pc-remote-policy /vault/policies/pc-remote-policy.hcl

# === DB Setup ===
if ! vault secrets list -format=json | grep -q '"postgresql/"'; then
	echo "[*] Enabling PostgreSQL secrets engine..."
	vault secrets enable -path=postgresql database
else
	echo "[✓] PostgreSQL secrets engine already enabled."
fi

# === AppRole Setup ===
vault auth enable approle || true
vault write auth/approle/role/pc-remote-role \
	token_policies="pc-remote-policy" \
	token_ttl="1h" \
	token_max_ttl="4h" \
	secret_id_ttl="24h" || echo "[✓] AppRole already exists."

echo "[*] Waiting briefly to ensure AppRole is queryable..."
sleep 2

i=1
while [ "$i" -le "$MAX_RETRIES" ]; do
	echo "[*] Attempt $i: Fetching AppRole credentials..."
	ROLE_ID=$(vault read -format=json auth/approle/role/pc-remote-role/role-id | jq -r .data.role_id || true)
	SECRET_ID=$(vault write -f -format=json auth/approle/role/pc-remote-role/secret-id | jq -r .data.secret_id || true)
	if [ -n "$ROLE_ID" ] && [ -n "$SECRET_ID" ]; then
		echo "$ROLE_ID" >/vault/approle/role_id
		echo "$SECRET_ID" >/vault/approle/secret_id
		echo "[✓] AppRole credentials saved"
		break
	fi
	i=$((i + 1))
	sleep 2
done

if [ -z "$ROLE_ID" ] || [ -z "$SECRET_ID" ]; then
	echo "[✗] Failed to fetch AppRole credentials after $MAX_RETRIES retries."
	exit 1
fi

echo "[*] Cleaning up old .ok files to force fresh cert issuance..."
rm -f "$ISSUED_DIR"/*.ok 2>/dev/null || true

# === PKI Setup ===
vault secrets enable -path=pki/intermediate pki 2>/dev/null || echo "[✓] PKI already enabled"
vault secrets tune -max-lease-ttl=8760h pki/intermediate
vault write pki/intermediate/config/ca pem_bundle=@/vault/ca/intermediate/intermediate-bundle.pem
vault write pki/intermediate/config/urls \
	issuing_certificates="https://vault.local:4425/v1/pki/intermediate/ca" \
	crl_distribution_points="https://vault.local:4425/v1/pki/intermediate/crl"

# === role and cert setup ===
for service in $SERVICES; do
	ROLE_PATH="pki/intermediate/roles/$service"
	ISSUE_PATH="pki/intermediate/issue/$service"
	ISSUED_FILE="$ISSUED_DIR/$service.json"
	KV_PATH="secret/certs/$service"
	ALLOW_BARE=false

	case "$service" in
	db)
		DOMAIN_LIST="pc-remote-db.local db.local pc-remote-db $DOMAIN_SUFFIX"
		IP_SANS="192.168.50.10"
		SUBDOMAINS=false
		ALLOW_BARE=true
		;;
	backend)
		DOMAIN_LIST="pc-remote-backend.local backend.local $DOMAIN_SUFFIX"
		IP_SANS="192.168.50.10"
		SUBDOMAINS=true
		ALLOW_BARE=true
		;;
	vault)
		DOMAIN_LIST="vault.local"
		IP_SANS="192.168.50.10"
		SUBDOMAINS=false
		ALLOW_BARE=true
		;;
	nginx)
		DOMAIN_LIST="$DOMAIN_SUFFIX"
		IP_SANS="192.168.50.10"
		SUBDOMAINS=false
		ALLOW_BARE=true
		;;
	esac

	vault delete "$ROLE_PATH" 2>/dev/null || true

	CMD="vault write $ROLE_PATH"
	for domain in $DOMAIN_LIST; do
		CMD="$CMD allowed_domains=$domain"
	done
	CMD="$CMD allow_subdomains=$SUBDOMAINS allow_bare_domains=$ALLOW_BARE allow_ip_sans=true max_ttl=72h use_csr_common_name=true use_csr_sans=true"

	echo "[*] Creating new PKI role: $service"
	sh -c "$CMD"
	echo "[✓] PKI role $service written."

	# wait for Vault to register role change
	EXPECTED_DOMAINS=$(echo "$DOMAIN_LIST" | tr ' ' '\n' | sort)
	ALLOWED_DOMAINS=$(vault read -field=allowed_domains "$ROLE_PATH" 2>/dev/null | tr -d '[],"' | tr ' ' '\n' | sort)

	k=1
	while [ "$k" -le 10 ]; do
		ALLOWED_DOMAINS=$(vault read -field=allowed_domains "$ROLE_PATH" 2>/dev/null | tr -d '[],"' | tr ' ' '\n' | sort)
		MISSING_DOMAINS=""

		for domain in $EXPECTED_DOMAINS; do
			echo "$ALLOWED_DOMAINS" | grep -q "^$domain$" || MISSING_DOMAINS="$MISSING_DOMAINS $domain"
		done

		if [ -z "$MISSING_DOMAINS" ]; then
			echo "[✓] PKI role $service has all expected allowed_domains: $EXPECTED_DOMAINS"
			break
		else
			echo "[!] Attempt $k: still missing domain(s):$MISSING_DOMAINS"
			sleep 2
		fi
		k=$((k + 1))
	done

	if [ "$k" -gt 10 ]; then
		echo "[✗] PKI role $service did not register expected domains in time. Aborting."
		exit 1
	fi

	if [ ! -f "$ISSUED_FILE" ]; then
		echo "[*] Issuing certificate for $service..."
		j=1
		while [ "$j" -le "$ISSUE_RETRIES" ]; do
			CN_DOMAIN=$(echo "$DOMAIN_LIST" | awk '{ print $1 }')
			DNS_SANS=$(echo "$DOMAIN_LIST" | sed 's/ /,/g')

			if vault write -format=json "$ISSUE_PATH" \
				common_name="$CN_DOMAIN" \
				dns_sans="$DNS_SANS" \
				ip_sans="$IP_SANS" \
				ttl="72h" >"$ISSUED_FILE"; then

				EXPIRE=$(jq -r '.data.expiration' "$ISSUED_FILE")
				vault kv put "$KV_PATH" metadata_expire="$EXPIRE"
				echo "[✓] Issued and stored metadata for $service"
				touch "$ISSUED_FILE.ok"
				break
			else
				echo "[!] Attempt $j failed, retrying..."
				sleep 2
			fi
			j=$((j + 1))
		done

		if [ "$j" -le "$ISSUE_RETRIES" ]; then
			# === write cert files to expected host paths ===
			SVC_CERT_DIR="/vault/certs/$service"
			mkdir -p "$SVC_CERT_DIR"

			CERT=$(jq -r '.data.certificate' "$ISSUED_FILE")
			KEY=$(jq -r '.data.private_key' "$ISSUED_FILE")
			CA=$(jq -r '.data.issuing_ca' "$ISSUED_FILE")

			echo "$CERT" >"$SVC_CERT_DIR/$service.crt"
			echo "$KEY" >"$SVC_CERT_DIR/$service.key"
			echo "$CA" >"$SVC_CERT_DIR/ca.crt"
			cat "$SVC_CERT_DIR/$service.crt" "$SVC_CERT_DIR/ca.crt" >"$SVC_CERT_DIR/$service.fullchain.crt"

			chmod 640 "$SVC_CERT_DIR"/*
			echo "[✓] Wrote $service certificate files to $SVC_CERT_DIR"

			case "$service" in
			db)
				DB_UID=0
				DB_GID=0
				chown -R "$DB_UID:$DB_GID" "$SVC_CERT_DIR"
				chmod 600 "$SVC_CERT_DIR/$service.key"
				chmod 644 "$SVC_CERT_DIR/$service.crt" "$SVC_CERT_DIR/ca.crt" "$SVC_CERT_DIR/$service.fullchain.crt"
				chmod 700 "$SVC_CERT_DIR"
				;;
			nginx)
				chown -R 101:101 "$SVC_CERT_DIR"
				chmod 600 "$SVC_CERT_DIR/$service.key"
				chmod 644 "$SVC_CERT_DIR/$service.crt" "$SVC_CERT_DIR/ca.crt" "$SVC_CERT_DIR/$service.fullchain.crt"
				chmod o+rx "$SVC_CERT_DIR"
				;;
			*)
				chown -R 1000:1000 "$SVC_CERT_DIR"
				chmod 600 "$SVC_CERT_DIR/$service.key"
				chmod 644 "$SVC_CERT_DIR/$service.crt" "$SVC_CERT_DIR/ca.crt" "$SVC_CERT_DIR/$service.fullchain.crt"
				chmod o+rx "$SVC_CERT_DIR"
				;;
			esac
		else
			echo "[✗] Failed to issue cert for $service after $ISSUE_RETRIES retries."
			exit 1
		fi

	else
		echo "[✓] Cert for $service already exists, skipping."
	fi
done

chown -R 1000:1000 /vault/approle
chown -R vault:vault "$ISSUED_DIR"

echo "[*] Cleaning up issued cert JSON files..."
for ok_file in "$ISSUED_DIR"/*.ok; do
	json_file="${ok_file%.ok}"
	if [ -f "$json_file" ]; then
		secure_delete "$json_file"
	fi
	rm -f "$ok_file"
done

echo "[*] Relaxing permissions so host can access certs..."
for svc in $SERVICES; do
	chmod o+rx "/vault/certs/$svc" 2>/dev/null || true
done
