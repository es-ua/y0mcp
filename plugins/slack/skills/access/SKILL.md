---
name: access
description: Manage y0slack pairing and allowlists. Pair new Slack users, list allowed users, or revoke access.
user_invocable: true
---

# y0slack:access

Manage who can send messages to your Claude Code agent through Slack.

## Commands

### Pair a new user

When a user messages the bot in Slack for the first time, they receive a pairing code. To complete pairing, run:

```
/y0slack:access pair <CODE>
```

This adds the Slack user to the allowlist so their future messages are forwarded to Claude Code.

### List allowed users

```
/y0slack:access list
```

Shows all Slack user IDs currently in the allowlist.

### Revoke access

```
/y0slack:access revoke <SLACK_USER_ID>
```

Removes a user from the allowlist. Their messages will no longer be forwarded.

## How it works

1. Read the access state from `~/.claude/channels/y0slack/{AGENT_NAME}/access.json`
2. Parse the subcommand from the user's input:
   - `pair <CODE>` — call `addToAllowlist(code)` and confirm
   - `list` — show all entries in `allowlist`
   - `revoke <ID>` — remove the ID from `allowlist` and save
3. If no subcommand given, show help text

## Access file format

```json
{
  "allowlist": ["U12345678", "U87654321"],
  "pendingPairs": {
    "ABC123": "U99999999"
  }
}
```

Located at `~/.claude/channels/y0slack/{AGENT_NAME}/access.json` where `AGENT_NAME` defaults to `"default"`.
