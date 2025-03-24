#!/bin/bash

# File: scripts/vault/usk.sh

set -e

KEY_DIR="/home/viihna/Projects/pc-remote/secrets/keys"
KEYFILE="$KEY_DIR/usk.json"
ENCRYPTED_KEYFILE="$KEY_DIR/usk.json.gpg"
SOPS_PGP_KEY_ID="B5BC332A603B022E21E46F2DA18BAE412BC0A77C"
SOPS_CONFIG="/home/viihna/Projects/pc-remote/.sops.yaml"

WORK_DIR="/home/viihna/Projects/pc-remote"
cd "$WORK_DIR"

usage() {
	echo "Usage: $0 [-e | -d | -c]"
	echo "  -e    Encrypt usk.json to usk.json.gpg (and shred usk.json)"
	echo "  -d    Decrypt usk.json.gpg to usk.json"
	echo "  -c    Check and shred any unencrypted usk.json file"
	exit 1
}

if [[ $# -ne 1 ]]; then
	usage
fi

case "$1" in
-d)
	echo "Decrypting..."
	if [[ -f "$KEYFILE" ]]; then
		echo "Decrypted file already exists: $KEYFILE"
		echo "Skipping decryption."
		exit 0
	fi

	if [[ ! -f "$ENCRYPTED_KEYFILE" ]]; then
		echo "Error: Encrypted file not found: $ENCRYPTED_KEYFILE"
		exit 1
	fi

	umask 077
	sudo -u viihna SOPS_PGP_KEY_ID=$SOPS_PGP_KEY_ID sops --config="$SOPS_CONFIG" --output-type json --decrypt "$ENCRYPTED_KEYFILE" | sudo tee "$KEYFILE" >/dev/null
	echo "Decrypted to: $KEYFILE"
	;;

-e)
	echo "Encrypting..."
	if [[ ! -f "$KEYFILE" ]]; then
		echo "Error: JSON file not found: $KEYFILE"
		exit 1
	fi

	if [[ -f "$ENCRYPTED_KEYFILE" ]]; then
		echo "Error: Encrypted file already exists: $ENCRYPTED_KEYFILE"
		echo "Refusing to overwrite. Please shred or move it first."
		exit 1
	fi

	# Use sops to write directly to the encrypted file — NO piping
	sudo -u viihna env SOPS_PGP_KEY_ID="$SOPS_PGP_KEY_ID" \
		sops --config "$SOPS_CONFIG" \
		--encrypt --pgp "$SOPS_PGP_KEY_ID" \
		--output "$ENCRYPTED_KEYFILE" "$KEYFILE"

	# Check if it actually wrote
	if [[ ! -s "$ENCRYPTED_KEYFILE" ]]; then
		echo "Error: Encrypted file is missing or empty!"
		exit 1
	fi

	echo "Encrypted to: $ENCRYPTED_KEYFILE"

	echo "Shredding unencrypted file: $KEYFILE"
	sudo shred -u "$KEYFILE"
	;;

-c)
	echo "Checking for leftover unencrypted file..."
	if [[ -f "$KEYFILE" ]]; then
		echo "Found unencrypted key file: $KEYFILE"
		echo "Shredding..."
		sudo shred -u "$KEYFILE"
		echo "Securely shredded: $KEYFILE"
	else
		echo "No unencrypted key file found. Nothing to do."
	fi
	;;

*)
	usage
	;;
esac
