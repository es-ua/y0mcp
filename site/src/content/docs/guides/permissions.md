---
title: Permission Relay
description: Approve or deny risky Claude Code actions directly from Slack.
---

When Claude Code wants to perform a risky action, y0mcp sends a permission request to Slack. You approve or deny with a reaction.

## How it works

1. Claude Code identifies a risky action (e.g., `rm -rf`, `git push --force`)
2. y0mcp posts a permission request to the Slack channel
3. You react with ✅ to approve or ❌ to deny
4. Claude Code proceeds or aborts based on your response

## Example

```
🔴 Permission required

Action: `rm -rf ./node_modules`
Reason: Cleaning before reinstall

React ✅ to approve or ❌ to deny
Timeout: 5 minutes
```

## Risk levels

| Emoji | Level | Description |
|---|---|---|
| 🟢 | Low | Safe operations |
| 🟡 | Medium | Moderate risk |
| 🔴 | High | Destructive or irreversible |

## Timeout

Permission requests expire after 5 minutes. Expired requests are automatically denied.

## Message updates

After you react, the original message updates to show the result:

- `✅ Approved — rm -rf ./node_modules`
- `❌ Denied — rm -rf ./node_modules`
