---
title: Token Refresh
description: Automatic OAuth token refresh for Claude Code.
---

Claude Code OAuth tokens expire periodically. y0mcp includes automatic refresh.

## How it works

1. A scheduled job runs every 2 hours
2. Checks token expiry in `~/.claude/.credentials.json`
3. Refreshes if expiring within 30 minutes
4. File locking prevents race conditions

## Setup

Installed automatically by `scripts/install.sh`. For manual setup:

```bash
bash scripts/setup-token-refresh.sh
```

## Manual refresh

```bash
bash scripts/token-refresh.sh
```

## Monitoring

```bash
cat ~/.y0mcp/token-refresh.log
```

## Troubleshooting

If auto-refresh fails, re-login manually:

```bash
claude /login
```
