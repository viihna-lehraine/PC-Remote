#!/bin/bash

# File: scripts/vault/fix-cert-permissions.sh

set -e

ROOT_DIR="/home/viihna/Projects/pc-remote/secrets/certs/services"
SERVICES=("db" "backend" "vault" "nginx")

echo "Fixing cert file permissions under $ROOT_DIR"

for service in "${SERVICES[@]}"; do
	DIR="$ROOT_DIR/$service"

	if [ ! -d "$DIR" ]; then
		echo "Skipping missing directory: $DIR"
		continue
	fi

	echo "Processing: $service"

	case "$service" in
	db)
		OWNER_UID=0
		OWNER_GID=0
		;;
	nginx)
		OWNER_UID=101
		OWNER_GID=101
		;;
	*)
		OWNER_UID=1000
		OWNER_GID=1000
		;;
	esac

	echo "  → Setting owner to $OWNER_UID:$OWNER_GID"
	chown -R "$OWNER_UID:$OWNER_GID" "$DIR"

	echo "  → Securing directory permissions (751)"
	ls -lah "$DIR" || echo "(dir not listable)"
	chmod 751 "$DIR"
	ls -lah "$DIR" || echo "(dir not listable)"

	shopt -s nullglob
	for file in "$DIR"/*; do
		filename=$(basename "$file")
		case "$filename" in
		*.key)
			chmod 640 "$file"
			;;
		*.fullchain.crt)
			chmod 644 "$file"
			;;
		ca.crt)
			chmod 644 "$file"
			;;
		*.crt)
			chmod 644 "$file"
			;;
		*)
			chmod 600 "$file"
			;;
		esac
	done

	echo "  $service certs secured"
done

if [[ -f "$ROOT_DIR/db/db.key" ]]; then
	echo "  → Manually forcing db.key ownership and mode for PostgreSQL"
	chown 0:0 "$ROOT_DIR/db/db.key"
	chmod 600 "$ROOT_DIR/db/db.key"
fi

echo "All cert permissions fixed"
