#!/bin/bash

set -e

LOGDIR="/home/viihna/Projects/pc_remote/logs/sysd"
ARCHIVEDIR="$LOGDIR/archive"
mkdir -p "$LOGDIR" "$ARCHIVEDIR"

LOGNUM=$(find "$LOGDIR" -maxdepth 1 -type f -name 'pc-remote-*.log' 2>/dev/null | awk -F'[-.]' '{print $(NF-1)}' | sort -n | tail -1)
LOGNUM=$((LOGNUM + 1))

LOGFILE="$LOGDIR/pc-remote-$LOGNUM.log"

{
	echo "Starting PC Remote..."
	date
	whoami
	env
	which pnpm
} >>"$LOGFILE" 2>&1

export PATH=$HOME/.local/share/pnpm:$HOME/.local/bin:$PATH

cd "/home/viihna/Projects/pc_remote" || {
	echo "Failed to cd into project directory" >>"$LOGFILE"
	exit 1
}

LOGCOUNT=$(find "$LOGDIR" -maxdepth 1 -type f -name 'pc-remote-*.log' 2>/dev/null | wc -l)
if [ "$LOGCOUNT" -gt 10 ]; then
	find "$LOGDIR" -maxdepth 1 -type f -name 'pc-remote-*.log' -printf "%T@ %p\n" | sort -n | head -n -10 | awk '{print $2}' | while read -r log; do
		mv "$log" "$ARCHIVEDIR/"
	done
fi

pnpm --filter backend start >>"$LOGFILE" 2>&1
