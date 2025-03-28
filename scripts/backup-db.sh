#!/bin/bash

# File: scripts/backup-db.sh

set -e

# Define backup directory and filename
BACKUP_DIR='/home/viihna/Projects/pc-remote/db/backups'
ARCHIVE_DIR='/home/viihna/Projects/pc-remote/db/backups/archive'
BACKUP_FILE="$BACKUP_DIR/db_backup_$(date +%F_%H-%M-%S).sql"
ENCRYPTED_FILE="${BACKUP_FILE}.enc"
MAX_BACKUPS=10

# Get the GPG key to use for encryption
GPG_KEY="$(gpg --list-secret-keys --keyid-format=long | awk '/sec/ {print $2}' | cut -d'/' -f2 | head -n 1)"

if [[ -z "$GPG_KEY" ]]; then
	echo "No GPG key found! Please make sure your key is imported."
	exit 1
fi

# Create backup and archive directories if they don't exist
mkdir -p "$BACKUP_DIR"
mkdir -p "$ARCHIVE_DIR"

# Cleanup: Archive old backups if the limit is exceeded
echo "Checking backup directory for cleanup tasks..."
NUM_BACKUPS=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "*.sql.enc" | wc -l)

if [ "$NUM_BACKUPS" -gt "$MAX_BACKUPS" ]; then
	echo "Moving old backups to archive..."
	find "$BACKUP_DIR" -maxdepth 1 -type f -name "*.sql.enc" | sort | head -n "$((NUM_BACKUPS - MAX_BACKUPS))" | xargs -I {} mv {} "$ARCHIVE_DIR/"
	echo "Old backups archived."
else
	echo "No backups need to be archived."
fi

# Set up the .pgpass file for secure access
export PGPASSFILE="$HOME/.pgpass"

# Perform the database dump using Docker exec to access the database container
echo "Dumping database to $BACKUP_FILE..."
if ! docker exec -u postgres pc-remote-db pg_dump -U vault_mgr -h localhost -p 4590 -d postgres -F c -f "$BACKUP_FILE"; then
	echo "Database dump failed!"
	exit 1
fi

# Encrypt the backup
echo "Encrypting backup..."
if ! sudo -u viihna sops --encrypt --pgp "$GPG_KEY" --output "$ENCRYPTED_FILE" "$BACKUP_FILE"; then
	echo "Encryption failed!"
	exit 1
fi

# Set proper permissions on the encrypted backup
chmod 600 "$ENCRYPTED_FILE"

# Clean up the unencrypted backup file
rm "$BACKUP_FILE"

echo "Backup complete: $ENCRYPTED_FILE"
