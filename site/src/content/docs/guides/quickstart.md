---
title: Quick Start
description: Get y0mcp up and running in minutes.
---

## Prerequisites

- macOS or Linux
- [Claude Code CLI](https://claude.ai) installed and logged in
- claude.ai Pro or Max subscription
- Slack workspace with admin access

## Install the plugin

In your Claude Code terminal:

```
/plugin marketplace add es-ua/y0mcp
/plugin install slack@y0mcp
```

This will:
1. Add the y0mcp marketplace to Claude Code
2. Install the Slack channel plugin with all dependencies
3. Set up automatic token refresh

## Create your first agent

Run from your project directory — the path and name will be auto-detected:

```bash
cd ~/projects/my-project
bash scripts/new-agent.sh
```

You'll be prompted for:
- **Agent name** — defaults to current folder name
- **Slack channel ID** — starts with `C`, find it in channel details
- **Slack channel name** — defaults to agent name
- **Project path** — defaults to current directory
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
