# @y0mcp/y0slack

Slack channel plugin for Claude Code.

## Features

- Connect Claude Code to a Slack channel
- Permission relay — approve/deny risky actions with reactions
- Multi-project — one agent per channel
- Dozzle container log integration (optional)
- Auto token refresh via launchd/systemd

## Setup

1. Create a Slack App ([guide](../../docs/setup-slack-app.md))
2. In Claude Code terminal:
   ```
   /plugin marketplace add es-ua/y0mcp
   /plugin install y0slack@y0mcp
   ```
3. Run `bash scripts/new-agent.sh` to create an agent
4. Add your Slack tokens to the generated `.env` file
5. Start the agent

## Configuration

| Variable | Required | Description |
|---|---|---|
| `SLACK_BOT_TOKEN` | Yes | Bot token (`xoxb-...`) |
| `SLACK_APP_TOKEN` | Yes | App token (`xapp-...`) |
| `SLACK_CHANNEL_ID` | Yes | Channel ID (`C...`) |
| `SLACK_CHANNEL_NAME` | No | Human-readable channel name |
| `AGENT_NAME` | No | Agent identifier (default: `default`) |
| `DOZZLE_URL` | No | Dozzle instance URL |
| `DOZZLE_TOKEN` | No | Dozzle auth token |

## Tools

- `reply` — Send a message to the Slack channel
- `react` — Add a reaction to a message
- `request_permission` — Ask for approval before risky actions
- `dozzle_logs` — Fetch container logs (when Dozzle is configured)
