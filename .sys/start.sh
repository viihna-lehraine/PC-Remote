#!/bin/bash

set -e

PROJECT_ROOT="/home/viihna/Projects/pc-remote"
LOGDIR="/home/viihna/Projects/pc-remote/logs/sysd"
ARCHIVEDIR="$LOGDIR/archive"

mkdir -p "$LOGDIR" "$ARCHIVEDIR"

LOGNUM=$(find "$LOGDIR" -maxdepth 1 -type f -name 'pc-remote-*.log' 2>/dev/null |
	awk -F'[-.]' '{print $(NF-1)}' | sort -n | tail -1)
LOGNUM=$((LOGNUM + 1))
LOGFILE="$LOGDIR/pc-remote-$LOGNUM.log"

# debug info
{
	echo "🟢 [$(date '+%F %T')] Starting PC Remote..."
	echo "User: $(whoami)"
	echo "Env: NODE_ENV=${NODE_ENV:-development}"
	echo "pnpm path: $(command -v pnpm)"
	env
	echo ""
} >>"$LOGFILE" 2>&1

# PATH fix for systemd
export PATH="$HOME/.local/share/pnpm:$HOME/.local/bin:$PATH"

cd "$PROJECT_ROOT" || {
	echo "❌ Failed to cd into $PROJECT_ROOT" >>"$LOGFILE"
	exit 1
}

# build Fastify backend
echo "📦 [$(date '+%F %T')] Building backend..." | tee -a "$LOGFILE"
pnpm --filter backend build 2>&1 | tee -a "$LOGFILE"

# start Dockerized Nginx
echo "🐳 [$(date '+%F %T')] Starting Nginx container..." | tee -a "$LOGFILE"
docker compose up -d nginx 2>&1 | tee -a "$LOGFILE"

# start Fastify
echo "🚀 [$(date '+%F %T')] Starting Fastify server..." | tee -a "$LOGFILE"
pnpm --filter backend start 2>&1 | tee -a "$LOGFILE"
