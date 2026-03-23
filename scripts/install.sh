#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
Y0PS_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔══════════════════════════════╗"
echo "║      y0mcp installer         ║"
echo "╚══════════════════════════════╝"
echo ""

# 1. Check Claude Code
if ! command -v claude &> /dev/null; then
  echo "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code
fi

# 2. Check Bun
if ! command -v bun &> /dev/null; then
  echo "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  source ~/.bashrc
fi

# 3. Install plugin dependencies
echo "Installing plugin dependencies..."
cd "$Y0PS_DIR/plugins/slack"
bun install

# 4. Check Claude auth
if [ ! -f "$HOME/.claude/.credentials.json" ]; then
  echo ""
  echo "⚠️  Not logged in to Claude Code."
  echo "Run: claude"
  echo "Then re-run this script."
  exit 1
fi

echo "✓ Claude Code authenticated"

# 5. Install token refresh
echo "Setting up token refresh..."
bash "$SCRIPT_DIR/setup-token-refresh.sh"

# 6. Create data directory
mkdir -p "$HOME/.y0mcp"

echo ""
echo "✓ y0mcp installed!"
echo ""
echo "Next steps in Claude Code terminal:"
echo "  /plugin marketplace add es-ua/y0mcp"
echo "  /plugin install y0slack@y0mcp"
echo ""
echo "Then create an agent:"
echo "  bash scripts/new-agent.sh"
echo ""
echo "See: https://y0mcp.dev/guides/quickstart/"
