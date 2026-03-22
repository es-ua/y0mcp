# Multiple Projects

y0mcp supports running multiple Claude Code agents simultaneously, each connected to its own Slack channel and project directory.

## How it works

Each agent is an independent process:

- Separate Slack channel
- Separate working directory (repo)
- Separate launchd/systemd service
- Shared Slack Bot Token (filtered by channel ID)
- Shared token refresh job (with file locking)

## Setup

### 1. Create channels in Slack

Create one channel per project:
- `#project-a`
- `#project-b`
- `#project-c`

Invite the bot to each: `/invite @y0mcp`

### 2. Create agents

Run `bash scripts/new-agent.sh` for each project:

```bash
bash scripts/new-agent.sh  # project-a
bash scripts/new-agent.sh  # project-b
bash scripts/new-agent.sh  # project-c
```

### 3. Fill in tokens

Edit each `agents/<name>.env` file with:
- Same `SLACK_BOT_TOKEN` and `SLACK_APP_TOKEN` for all
- Different `SLACK_CHANNEL_ID` for each
- Different `WORKSPACE_PATH` for each

### 4. Start all agents

**Mac:**
```bash
launchctl load ~/Library/LaunchAgents/dev.y0mcp.project-a.plist
launchctl load ~/Library/LaunchAgents/dev.y0mcp.project-b.plist
launchctl load ~/Library/LaunchAgents/dev.y0mcp.project-c.plist
```

**Linux:**
```bash
systemctl --user enable --now y0mcp-project-a
systemctl --user enable --now y0mcp-project-b
systemctl --user enable --now y0mcp-project-c
```

## Token refresh

The shared token refresh job runs every 2 hours and uses file locking (`flock`) to prevent race conditions when multiple agents are running.
