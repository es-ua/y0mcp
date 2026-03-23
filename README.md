# y0mcp

Control your dev projects from Slack using your claude.ai subscription.

Multi-project routing. Permission relay. Always-on with auto token refresh.
No API key required — works with claude.ai Pro/Max.

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude-Code-blueviolet)](https://claude.ai)
[![Slack](https://img.shields.io/badge/Slack-plugin-4A154B)](https://slack.com)
[![macOS](https://img.shields.io/badge/macOS-supported-brightgreen)]()
[![Linux](https://img.shields.io/badge/Linux-supported-brightgreen)]()

---

## Why y0mcp

| | OpenClaw | Claude Code Channels | y0mcp |
|---|---|---|---|
| Slack | ✓ | ✗ | ✓ |
| Multi-project routing | ✓ | ✗ | ✓ |
| Permission relay in Slack | ✗ | ✗ | ✓ |
| claude.ai subscription | ✗ | ✓ | ✓ |
| API key required | ✓ | ✗ | ✗ |
| Auto token refresh | ✗ | ✗ | ✓ |
| Always-on (launchd/systemd) | ✗ | ✗ | ✓ |
| Container logs (Dozzle) | ✗ | ✗ | ✓ |

## How it works

```
You → Slack #project-a → y0mcp → Claude Code in ~/projects/project-a
                               ↕ permission relay (✅/❌ in Slack)
                               → Dozzle API (optional)
```

## Quick Start

**1. Add marketplace and install plugin** — in Claude Code terminal:
```
/plugin marketplace add es-ua/y0mcp
/plugin install slack@y0mcp
```

**2. Create a Slack App** — see [Setup Slack App](https://y0mcp.dev/guides/slack-app/)

**3. Create an agent:**
```bash
bash scripts/new-agent.sh
```

**4. Start:**
```bash
# Mac
launchctl load ~/Library/LaunchAgents/dev.y0mcp.my-project.plist

# Linux
systemctl --user enable --now y0mcp-my-project
```

**5. Pair** — message the bot in Slack → get code → `/pair CODE` in terminal

## Permission relay

```
🔴 Permission required

Action: `rm -rf ./node_modules`
Reason: Cleaning before reinstall

React ✅ to approve or ❌ to deny (timeout: 5 min)
```

## Always-on

- Agents start automatically on login
- Auto-restart on crash (KeepAlive)
- OAuth token refreshed every 2 hours

## Multiple projects

Each agent is independent — separate Slack channel, separate repo, separate process.
Run as many as you need. Token refresh uses file locking to prevent conflicts.

## Requirements

- macOS or Linux
- Claude Code CLI (claude.ai login)
- claude.ai Pro or Max subscription
- Slack workspace (admin access to create apps)

## Security

- **Socket Mode** — no public URL exposed
- **Pairing** — only you can message the agent
- **Permission relay** — approve/deny risky actions from Slack
- **Token refresh under file lock** — no race conditions

## Project structure

```
y0mcp/
├── plugins/slack/       ← Slack channel plugin (v1)
├── scripts/             ← Install, token refresh, agent setup
├── docs/                ← Documentation
└── site/                ← y0mcp.dev (Astro Starlight)
```

## Roadmap

- **v1**: Slack + permission relay + always-on ← now
- **v2**: Hosted `mcp.y0mcp.dev` — connect agents to cloud, API keys, subscriptions

## License

MIT
