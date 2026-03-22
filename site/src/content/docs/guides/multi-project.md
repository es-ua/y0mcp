---
title: Multiple Projects
description: Run multiple y0mcp agents for different projects.
---

Each y0mcp agent is independent — separate Slack channel, separate repo, separate process.

## Setup

### 1. Create Slack channels

One channel per project:
- `#project-a`
- `#project-b`
- `#project-c`

Invite the bot to each: `/invite @y0mcp`

### 2. Create agents

```bash
bash scripts/new-agent.sh  # for each project
```

### 3. Configure tokens

Edit each `agents/<name>.env`:
- Same `SLACK_BOT_TOKEN` and `SLACK_APP_TOKEN`
- Different `SLACK_CHANNEL_ID`
- Different `WORKSPACE_PATH`

### 4. Start all agents

**macOS:**
```bash
launchctl load ~/Library/LaunchAgents/dev.y0mcp.project-a.plist
launchctl load ~/Library/LaunchAgents/dev.y0mcp.project-b.plist
```

**Linux:**
```bash
systemctl --user enable --now y0mcp-project-a
systemctl --user enable --now y0mcp-project-b
```

## Token refresh

The shared token refresh job handles all agents. File locking (`flock`) prevents race conditions.
