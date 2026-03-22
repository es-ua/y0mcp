---
title: Configuration
description: All configuration options for y0mcp.
---

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `SLACK_BOT_TOKEN` | Yes | Slack Bot User OAuth Token (`xoxb-...`) |
| `SLACK_APP_TOKEN` | Yes | Slack App-Level Token (`xapp-...`) |
| `SLACK_CHANNEL_ID` | Yes | Slack channel ID (`C...`) |
| `SLACK_CHANNEL_NAME` | No | Human-readable channel name |
| `AGENT_NAME` | No | Agent identifier (default: `default`) |
| `DOZZLE_URL` | No | Dozzle instance URL |
| `DOZZLE_TOKEN` | No | Dozzle authentication token |

## File locations

| File | Location | Description |
|---|---|---|
| Agent env | `agents/<name>.env` | Agent configuration (not committed) |
| Access data | `~/.y0mcp/<name>/access.json` | Pairing allowlist |
| Token refresh log | `~/.y0mcp/token-refresh.log` | Refresh history |
| Agent logs | `~/.y0mcp/<name>.log` | Agent stdout |
| Agent errors | `~/.y0mcp/<name>.err` | Agent stderr |
| Credentials | `~/.claude/.credentials.json` | Claude OAuth token |

## plugin.json

The plugin manifest at `plugins/slack/plugin.json` defines:
- Plugin metadata (name, version, author)
- Runtime (`bun`)
- Entry point (`server.ts`)
- Channel capability
- Configuration schema

## Tools

| Tool | Description |
|---|---|
| `reply` | Send a message to the Slack channel |
| `react` | Add a reaction to a message |
| `request_permission` | Request approval for risky actions |
| `dozzle_logs` | Fetch container logs (when configured) |
