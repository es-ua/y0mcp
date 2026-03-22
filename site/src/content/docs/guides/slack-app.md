---
title: Setup Slack App
description: Create and configure a Slack App for y0mcp.
---

One Slack App serves all y0mcp agents. Each agent filters messages by its own `SLACK_CHANNEL_ID`.

## Create the App

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Click **Create New App** → **From scratch**
3. Name: `y0mcp` (or your preference)
4. Select your workspace

## Enable Socket Mode

1. Go to **Socket Mode** → Enable
2. Generate an **App-Level Token** with `connections:write` scope
3. Save the token (`xapp-...`) — this is your `SLACK_APP_TOKEN`

## Bot Token Scopes

Go to **OAuth & Permissions** → **Bot Token Scopes** and add:

- `channels:history`
- `channels:read`
- `chat:write`
- `chat:write.public`
- `reactions:add`
- `reactions:read`
- `reactions:write`

## Event Subscriptions

Go to **Event Subscriptions** → Enable → **Subscribe to bot events**:

- `message.channels`
- `reaction_added`

## Install to Workspace

1. Go to **Install App** → **Install to Workspace**
2. Save the **Bot User OAuth Token** (`xoxb-...`) — this is your `SLACK_BOT_TOKEN`

## Invite the bot

In each Slack channel you want to use:

```
/invite @y0mcp
```

## Token summary

| Token | Env variable | Format |
|---|---|---|
| Bot User OAuth Token | `SLACK_BOT_TOKEN` | `xoxb-...` |
| App-Level Token | `SLACK_APP_TOKEN` | `xapp-...` |
