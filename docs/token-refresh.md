# Token Refresh

Claude Code OAuth tokens expire periodically. y0mcp includes an automatic token refresh mechanism.

## How it works

1. A scheduled job runs every 2 hours
2. It checks the token expiry in `~/.claude/.credentials.json`
3. If the token expires within 30 minutes, it refreshes via `claude auth refresh`
4. File locking (`flock`) prevents race conditions with multiple agents

## Setup

Token refresh is installed automatically by `scripts/install.sh`. To install manually:

```bash
bash scripts/setup-token-refresh.sh
```

This creates:
- **macOS**: `~/Library/LaunchAgents/dev.y0mcp.token-refresh.plist`
- **Linux**: `~/.config/systemd/user/y0mcp-token-refresh.timer`

## Manual refresh

```bash
bash scripts/token-refresh.sh
```

## Monitoring

Check the refresh log:

```bash
cat ~/.y0mcp/token-refresh.log
```

## Troubleshooting

If auto-refresh fails:

```bash
# Re-login manually
claude /login

# Then verify
cat ~/.claude/.credentials.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('claudeAiOauth', {}).get('expiresAt', 'not found'))
"
```

## Token on Mac (Keychain)

On macOS, Claude Code may store tokens in Keychain instead of the file. In this case, `checkTokenHealth()` returns a fallback status and the refresh script may not detect expiry. If you experience issues, ensure credentials are file-based.
