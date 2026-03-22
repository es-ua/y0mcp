# Always-on Setup

y0mcp agents run as system services that start on boot and auto-restart on crash.

## Machine requirements

| Setup | Notes |
|---|---|
| Mac Studio / Mac Mini / Linux desktop | Works out of the box |
| Laptop (open) | Use `caffeinate` or disable sleep |
| Laptop (closed) | Use a VPS (e.g., Hetzner CAX11 ~€3/mo) |

## macOS (launchd)

Agents are managed via launchd plist files in `~/Library/LaunchAgents/`.

```bash
# Start
launchctl load ~/Library/LaunchAgents/dev.y0mcp.my-project.plist

# Stop
launchctl unload ~/Library/LaunchAgents/dev.y0mcp.my-project.plist

# Check status
launchctl list | grep y0mcp

# View logs
tail -f ~/.y0mcp/my-project.log
```

### Keep laptop awake

```bash
# Prevent sleep while on AC power
caffeinate -s &
```

## Linux (systemd)

Agents are managed via systemd user services.

```bash
# Start
systemctl --user enable --now y0mcp-my-project

# Stop
systemctl --user disable --now y0mcp-my-project

# Check status
systemctl --user status y0mcp-my-project

# View logs
journalctl --user -u y0mcp-my-project -f
```

## Heartbeat

Each agent sends a Slack message on:
- Start: `🟢 y0mcp agent started`
- Crash: `🔴 y0mcp agent crashed` (with error message)
- Stop: `🔴 y0mcp agent stopped`

## Auto-restart

- **macOS**: `KeepAlive` with `SuccessfulExit: false` — restarts on non-zero exit
- **Linux**: `Restart=on-failure` with `RestartSec=30`
- **Throttle**: 30-second minimum between restarts to prevent rapid loops
