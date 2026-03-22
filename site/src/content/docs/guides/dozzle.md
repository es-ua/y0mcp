---
title: Dozzle Logs
description: Access container logs through y0mcp via Dozzle.
---

y0mcp optionally integrates with [Dozzle](https://dozzle.dev) to provide container log access through Claude Code.

## Setup

1. Run Dozzle on your machine or server
2. Add the URL to your agent's env file:

```bash
DOZZLE_URL=http://localhost:8080
DOZZLE_TOKEN=your-optional-auth-token
```

3. Restart the agent

## Usage

When Dozzle is configured, the `dozzle_logs` tool becomes available. Claude Code can fetch container logs on demand.

The tool accepts:
- `container` — container name or ID
- `lines` — number of log lines (default: 100)

## Security

- Dozzle access is local by default
- Optional token authentication via `DOZZLE_TOKEN`
- Only the configured agent can access logs
