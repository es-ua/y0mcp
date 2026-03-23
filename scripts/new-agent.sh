#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
Y0PS_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔══════════════════════════════╗"
echo "║     y0mcp — new agent        ║"
echo "╚══════════════════════════════╝"
echo ""

# helper: show value, confirm or override
confirm() {
  local label="$1" default="$2"
  echo "$label: $default"
  read -p "  Confirm? [Y/n]: " answer
  if [[ "$answer" =~ ^[Nn] ]]; then
    read -p "  Enter new value: " new_value
    echo "$new_value"
  else
    echo "$default"
  fi
}

# helper: check if value is a real value (not a placeholder)
is_set() {
  [[ -n "$1" && "$1" != xoxb-... && "$1" != xapp-... ]]
}

# --- Detect defaults from current directory ---
DEFAULT_PATH="$(pwd)"
DEFAULT_NAME="$(basename "$DEFAULT_PATH")"

# --- Load existing .env if present ---
ENV_FILE="$Y0PS_DIR/agents/$DEFAULT_NAME.env"
if [[ -f "$ENV_FILE" ]]; then
  echo "Found existing config: $ENV_FILE"
  echo ""
  source "$ENV_FILE"
fi

# --- Only ask for values not already in .env ---

if is_set "${WORKSPACE_PATH:-}"; then
  echo "Project path: $WORKSPACE_PATH (from .env)"
else
  WORKSPACE_PATH="$(confirm "Project path" "$DEFAULT_PATH")"
  WORKSPACE_PATH="${WORKSPACE_PATH/#\~/$HOME}"
fi

if is_set "${AGENT_NAME:-}"; then
  echo "Agent name: $AGENT_NAME (from .env)"
else
  AGENT_NAME="$(confirm "Agent name" "$(basename "$WORKSPACE_PATH")")"
fi

# re-resolve env file path in case agent name changed
ENV_FILE="$Y0PS_DIR/agents/$AGENT_NAME.env"
if [[ -f "$ENV_FILE" ]] && [[ "$AGENT_NAME" != "$DEFAULT_NAME" ]]; then
  source "$ENV_FILE"
fi

if is_set "${SLACK_CHANNEL_ID:-}"; then
  echo "Slack channel ID: $SLACK_CHANNEL_ID (from .env)"
else
  read -p "Slack channel ID (C...): " SLACK_CHANNEL_ID
fi

if is_set "${SLACK_BOT_TOKEN:-}"; then
  echo "Slack bot token: ****${SLACK_BOT_TOKEN: -4} (from .env)"
else
  read -p "Slack bot token (xoxb-...): " SLACK_BOT_TOKEN
  SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-xoxb-...}"
fi

if is_set "${SLACK_APP_TOKEN:-}"; then
  echo "Slack app token: ****${SLACK_APP_TOKEN: -4} (from .env)"
else
  read -p "Slack app token (xapp-...): " SLACK_APP_TOKEN
  SLACK_APP_TOKEN="${SLACK_APP_TOKEN:-xapp-...}"
fi

echo ""

# --- Write .env ---
mkdir -p "$Y0PS_DIR/agents"

cat > "$ENV_FILE" << EOF
SLACK_BOT_TOKEN=$SLACK_BOT_TOKEN
SLACK_APP_TOKEN=$SLACK_APP_TOKEN
SLACK_CHANNEL_ID=$SLACK_CHANNEL_ID
AGENT_NAME=$AGENT_NAME
WORKSPACE_PATH=$WORKSPACE_PATH
# DOZZLE_URL=
# DOZZLE_TOKEN=
EOF

echo "✓ Saved: $ENV_FILE"
echo ""

# --- Install launchd/systemd ---
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
  echo "To start:"
  echo "  systemctl --user daemon-reload"
  echo "  systemctl --user enable --now y0mcp-$AGENT_NAME"
fi
