#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
Y0PS_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔══════════════════════════════╗"
echo "║     y0mcp — new agent        ║"
echo "╚══════════════════════════════╝"
echo ""

DEFAULT_PATH="$(pwd)"
DEFAULT_NAME="$(basename "$DEFAULT_PATH")"

read -p "Agent name [$DEFAULT_NAME]: " AGENT_NAME
AGENT_NAME="${AGENT_NAME:-$DEFAULT_NAME}"

read -p "Slack channel ID (C...): " SLACK_CHANNEL_ID

read -p "Slack channel name [$AGENT_NAME]: " SLACK_CHANNEL_NAME
SLACK_CHANNEL_NAME="${SLACK_CHANNEL_NAME:-$AGENT_NAME}"

read -p "Project path [$DEFAULT_PATH]: " WORKSPACE_PATH
WORKSPACE_PATH="${WORKSPACE_PATH:-$DEFAULT_PATH}"
WORKSPACE_PATH="${WORKSPACE_PATH/#\~/$HOME}"

read -p "Dozzle URL (optional, press Enter to skip): " DOZZLE_URL

# create .env
ENV_FILE="$Y0PS_DIR/agents/$AGENT_NAME.env"
mkdir -p "$Y0PS_DIR/agents"

cat > "$ENV_FILE" << EOF
SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN:-xoxb-...}
SLACK_APP_TOKEN=${SLACK_APP_TOKEN:-xapp-...}
SLACK_CHANNEL_ID=$SLACK_CHANNEL_ID
SLACK_CHANNEL_NAME=$SLACK_CHANNEL_NAME
AGENT_NAME=$AGENT_NAME
WORKSPACE_PATH=$WORKSPACE_PATH
${DOZZLE_URL:+DOZZLE_URL=$DOZZLE_URL}
EOF

echo ""
echo "✓ Created: agents/$AGENT_NAME.env"
echo ""
echo "Edit the file and add your Slack tokens:"
echo "  $ENV_FILE"
echo ""

# install launchd/systemd
if [[ "$OSTYPE" == "darwin"* ]]; then
  PLIST="$HOME/Library/LaunchAgents/dev.y0mcp.$AGENT_NAME.plist"

  cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>dev.y0mcp.${AGENT_NAME}</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-c</string>
    <string>source ${ENV_FILE} && cd ${WORKSPACE_PATH} && claude --dangerously-load-development-channels --channels plugin:slack@y0mcp</string>
  </array>

  <key>WorkingDirectory</key>
  <string>${WORKSPACE_PATH}</string>

  <key>KeepAlive</key>
  <dict>
    <key>SuccessfulExit</key>
    <false/>
  </dict>

  <key>RunAtLoad</key>
  <true/>

  <key>StandardOutPath</key>
  <string>${HOME}/.y0mcp/${AGENT_NAME}.log</string>

  <key>StandardErrorPath</key>
  <string>${HOME}/.y0mcp/${AGENT_NAME}.err</string>

  <key>ThrottleInterval</key>
  <integer>30</integer>
</dict>
</plist>
EOF

  echo "✓ Created: $PLIST"
  echo ""
  echo "To start after adding tokens:"
  echo "  launchctl load $PLIST"

else
  # Linux systemd
  mkdir -p "$HOME/.config/systemd/user"
  SERVICE="$HOME/.config/systemd/user/y0mcp-$AGENT_NAME.service"

  cat > "$SERVICE" << EOF
[Unit]
Description=y0mcp agent: ${AGENT_NAME}
After=network.target

[Service]
Type=simple
WorkingDirectory=${WORKSPACE_PATH}
EnvironmentFile=${ENV_FILE}
ExecStart=$(which claude) --dangerously-load-development-channels --channels plugin:slack@y0mcp
Restart=on-failure
RestartSec=30

[Install]
WantedBy=default.target
EOF

  echo "✓ Created: $SERVICE"
  echo ""
  echo "To start after adding tokens:"
  echo "  systemctl --user daemon-reload"
  echo "  systemctl --user enable --now y0mcp-$AGENT_NAME"
fi
