# Setup Slack App

One Slack App serves all y0mcp agents. Each agent filters messages by its own `SLACK_CHANNEL_ID`.

## Step-by-step

### 1. Create the App

- Go to [api.slack.com/apps](https://api.slack.com/apps)
- Click **Create New App** → **From scratch**
- Name: `y0mcp` (or whatever you prefer)
- Select your workspace

### 2. Enable Socket Mode

- Go to **Socket Mode** → Enable
- Generate an **App-Level Token** with `connections:write` scope
- Save the token (`xapp-...`) — this is your `SLACK_APP_TOKEN`

### 3. Bot Token Scopes

Go to **OAuth & Permissions** → **Bot Token Scopes** and add:

- `channels:history`
- `channels:read`
- `groups:history` (private channels)
- `groups:read` (private channels)
- `chat:write`
- `chat:write.public`
- `reactions:add`
- `reactions:read`
- `reactions:write`

### 4. Event Subscriptions

Go to **Event Subscriptions** → Enable → **Subscribe to bot events**:

- `message.channels` (public channels)
- `message.groups` (private channels)
- `reaction_added`

### 5. Install to Workspace

- Go to **Install App** → **Install to Workspace**
- Save the **Bot User OAuth Token** (`xoxb-...`) — this is your `SLACK_BOT_TOKEN`

### 6. Invite the bot

In each Slack channel you want to use:

```
/invite @y0mcp
```

## Token summary

| Token | Env variable | Format |
|---|---|---|
| Bot User OAuth Token | `SLACK_BOT_TOKEN` | `xoxb-...` |
| App-Level Token | `SLACK_APP_TOKEN` | `xapp-...` |

One Bot Token and one App Token are used for all agents. Each agent is separated by `SLACK_CHANNEL_ID`.
