#!/bin/bash

set -e

LOGDIR="/home/viihna/Projects/pc_remote/logs/sysd"
ARCHIVEDIR="$LOGDIR/archive"
mkdir -p "$LOGDIR" "$ARCHIVEDIR"

LOGNUM=$(ls "$LOGDIR"/pc-remote-*.log 2>/dev/null | awk -F'[-.]' '{print $(NF-1)}' | sort -n | tail -1)
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

LOGCOUNT=$(ls "$LOGDIR"/pc-remote-*.log 2>/dev/null | wc -l)
if [ "$LOGCOUNT" -gt 10 ]; then
	OLDEST_LOGS=$(ls -t "$LOGDIR"/pc-remote-*.log | tail -n +"11")
	for log in $OLDEST_LOGS; do
		mv "$log" "$ARCHIVEDIR/"
	done
fi

pnpm --filter backend start >>"$LOGFILE" 2>&1
