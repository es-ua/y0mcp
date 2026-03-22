---
title: Quick Start
description: Get y0mcp up and running in minutes.
---

## Prerequisites

- macOS or Linux
- [Claude Code CLI](https://claude.ai) installed
- claude.ai Pro or Max subscription
- Slack workspace with admin access
- Node.js 20+ and [Bun](https://bun.sh)

## Install

```bash
git clone https://github.com/es-ua/y0mcp
cd y0mcp
bash scripts/install.sh
```

The installer will:
1. Check for Claude Code and Bun (install if missing)
2. Install plugin dependencies
3. Verify Claude authentication
4. Set up automatic token refresh

## Create your first agent

```bash
bash scripts/new-agent.sh
```

You'll be prompted for:
- **Agent name** — e.g., `my-project`
- **Slack channel ID** — starts with `C`, find it in channel details
- **Slack channel name** — human-readable name
- **Project path** — where your code lives
- **Dozzle URL** — optional, for container logs

## Add Slack tokens

Edit the generated env file:

```bash
nano agents/my-project.env
```

Add your `SLACK_BOT_TOKEN` and `SLACK_APP_TOKEN`. See [Setup Slack App](/guides/slack-app) for how to get them.

## Start the agent

**macOS:**
```bash
launchctl load ~/Library/LaunchAgents/dev.y0mcp.my-project.plist
```

**Linux:**
```bash
systemctl --user enable --now y0mcp-my-project
```

## Pair with Slack

1. Send any message in the Slack channel
2. The bot will respond with a pairing code
3. Enter the code in your Claude Code terminal: `/pair CODE`
4. You're connected!
