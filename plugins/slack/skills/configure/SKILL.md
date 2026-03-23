---
name: configure
description: Configure y0slack — set Slack bot token, app token, and channel ID for this project.
user_invocable: true
---

# y0slack:configure

Set up the Slack connection for this project's Claude Code agent.

## What you need

1. A **Slack App** with Socket Mode enabled (see [Setup Slack App](https://y0mcp.dev/guides/slack-app/))
2. **Bot Token** (`xoxb-...`) — from OAuth & Permissions
3. **App Token** (`xapp-...`) — from Socket Mode settings
4. **Channel ID** (`C...`) — right-click channel in Slack → "Copy link", the ID is the last path segment

## Steps

1. Ask the user for their **Slack Bot Token** (`SLACK_BOT_TOKEN`)
2. Ask the user for their **Slack App Token** (`SLACK_APP_TOKEN`)
3. Ask the user for their **Slack Channel ID** (`SLACK_CHANNEL_ID`)
4. Optionally ask for **Agent Name** (`AGENT_NAME`) — defaults to the project directory name
5. Write the configuration to `~/.claude/channels/y0slack/.env`:

```
SLACK_BOT_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...
SLACK_CHANNEL_ID=C...
AGENT_NAME=my-project
```

6. Create the directory if it doesn't exist: `mkdir -p ~/.claude/channels/y0slack`
7. Confirm the configuration was saved and instruct the user to restart Claude Code with:

```
claude --channels plugin:y0slack@y0mcp
```

## Important

- Never display tokens in full — mask all but the first 8 characters
- The `.env` file should have `600` permissions (owner read/write only)
- One `.env` file is shared across agents; each agent filters by its own `SLACK_CHANNEL_ID`
