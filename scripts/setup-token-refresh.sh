#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
Y0PS_DIR="$(dirname "$SCRIPT_DIR")"

echo "Setting up y0mcp token refresh..."

if [[ "$OSTYPE" == "darwin"* ]]; then
  # Mac — launchd
  PLIST="$HOME/Library/LaunchAgents/dev.y0mcp.token-refresh.plist"

  cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>dev.y0mcp.token-refresh</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${Y0PS_DIR}/scripts/token-refresh.sh</string>
  </array>

  <key>StartInterval</key>
  <integer>7200</integer>

  <key>RunAtLoad</key>
  <true/>

  <key>StandardOutPath</key>
  <string>${HOME}/.y0mcp/token-refresh.log</string>

  <key>StandardErrorPath</key>
  <string>${HOME}/.y0mcp/token-refresh.err</string>
</dict>
</plist>
EOF

  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load "$PLIST"
  echo "✓ Token refresh installed (launchd, every 2 hours)"

else
  # Linux — systemd user service
  mkdir -p "$HOME/.config/systemd/user"

  cat > "$HOME/.config/systemd/user/y0mcp-token-refresh.service" << EOF
[Unit]
Description=y0mcp Claude OAuth Token Refresh

[Service]
Type=oneshot
ExecStart=/bin/bash ${Y0PS_DIR}/scripts/token-refresh.sh
EOF

  cat > "$HOME/.config/systemd/user/y0mcp-token-refresh.timer" << EOF
[Unit]
Description=y0mcp Claude OAuth Token Refresh Timer

[Timer]
OnBootSec=5min
OnUnitActiveSec=2h
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now y0mcp-token-refresh.timer
  echo "✓ Token refresh installed (systemd, every 2 hours)"
fi
