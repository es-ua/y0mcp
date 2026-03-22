#!/bin/bash
# y0mcp token refresh script
# Runs every 2 hours via launchd/systemd

set -e

LOCK_FILE="$HOME/.y0mcp/token-refresh.lock"
CREDENTIALS="$HOME/.claude/.credentials.json"
LOG="$HOME/.y0mcp/token-refresh.log"
BUFFER_MINUTES=30  # refresh 30 minutes before expiry

mkdir -p "$HOME/.y0mcp"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"
}

# file lock — only one process refreshes the token
(
  flock -n 9 || { log "Another refresh in progress, skipping"; exit 0; }

  log "Checking token health..."

  # check if refresh is needed
  if [ -f "$CREDENTIALS" ]; then
    EXPIRES_AT=$(cat "$CREDENTIALS" | python3 -c "
import json, sys
data = json.load(sys.stdin)
oauth = data.get('claudeAiOauth', {})
print(oauth.get('expiresAt', 0))
" 2>/dev/null || echo 0)

    NOW_MS=$(($(date +%s) * 1000))
    BUFFER_MS=$((BUFFER_MINUTES * 60 * 1000))
    EXPIRES_MS=$EXPIRES_AT

    if [ "$EXPIRES_MS" -gt "$((NOW_MS + BUFFER_MS))" ]; then
      REMAINING_MIN=$(( (EXPIRES_MS - NOW_MS) / 60000 ))
      log "Token valid for ${REMAINING_MIN} more minutes, skipping refresh"
      exit 0
    fi

    log "Token expires soon, refreshing..."
  fi

  # refresh via claude CLI
  if claude auth refresh 2>/dev/null; then
    log "✓ Token refreshed successfully"
  else
    log "⚠️ Auto-refresh failed — manual re-login may be required"
    log "Run: claude /login"
  fi

) 9>"$LOCK_FILE"
