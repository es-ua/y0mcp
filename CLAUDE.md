# y0mcp — CLAUDE.md

## Что строим

**y0mcp** — экосистема open source MCP плагинов для Claude Code.
Сайт: `y0mcp.dev`

Первый плагин — **y0slack**: Slack channel plugin для Claude Code.
Позволяет управлять dev-проектами через Slack используя свою claude.ai подписку.
Каждый Claude Code агент запускается в своей репе и подключается к своему Slack каналу.
Запросы на подтверждение от Claude приходят прямо в Slack.
Токены обновляются автоматически — переавторизация не нужна.

GitHub: `github.com/[owner]/y0mcp`

---

## Структура моно-репы

```
y0mcp/
├── CLAUDE.md
├── README.md                  ← обзор экосистемы y0mcp
├── .claude-plugin/
│   └── marketplace.json       ← каталог плагинов для маркетплейса
├── plugins/
│   ├── y0slack/               ← Slack channel plugin (v1)
│   ├── y0discord/             ← future
│   └── y0dozzle/              ← future
├── scripts/
├── docs/
└── site/                      ← y0mcp.dev (Astro Starlight)
```

---

## Проблема которую решаем (y0slack v1)

- Claude Code Channels не поддерживает Slack
- Нет multi-project routing через Slack каналы
- Нет permission relay — нужно сидеть у консоли
- При нескольких параллельных сессиях OAuth токены конфликтуют

y0slack решает все четыре проблемы.

---

## Архитектура

```
Локальная машина (Mac/Linux, не спит)
│
├── launchd/systemd: token-refresh (каждые 2 часа)
│   └── обновляет OAuth токен под file lock
│       предотвращает race condition при нескольких агентах
│
├── launchd/systemd: y0mcp-project-a
│   claude --channels plugin:y0slack@y0mcp
│   в директории ~/projects/project-a
│   └── Slack #project-a
│       ├── команды → Claude Code
│       ├── ответы → Slack
│       ├── permission запросы → Slack (реакция ✅/❌)
│       ├── heartbeat при старте/падении → Slack
│       └── Dozzle логи (опционально)
│
├── launchd/systemd: y0mcp-project-b
│   └── Slack #project-b ...
│
└── launchd/systemd: y0mcp-project-c
    └── Slack #project-c ...
```

**Требования к машине:**
- Mac Studio / Mac Mini / Linux desktop — из коробки
- Ноутбук открытый: `caffeinate` или отключить сон
- Ноутбук закрытый: VPS (Hetzner CAX11 ~€3/mo)

**Параллельные сессии:** несколько Claude Code процессов на одной машине
работают без конфликтов при условии что token-refresh job запущен.

---

## Структура проекта

```
y0mcp/
├── .gitignore                     (первый файл)
├── README.md
├── LICENSE                        (MIT)
├── CLAUDE.md                      (этот файл)
├── .claude-plugin/
│   └── marketplace.json           ← каталог плагинов для маркетплейса
│
├── plugins/
│   └── slack/
│       ├── plugin.json
│       ├── package.json
│       ├── tsconfig.json
│       ├── server.ts
│       ├── pairing.ts
│       ├── permissions.ts
│       ├── token.ts               (проверка токена)
│       ├── dozzle.ts
│       └── README.md
│
├── scripts/
│   ├── install.sh                 (полная установка)
│   ├── setup-token-refresh.sh     (только token refresh job)
│   ├── new-agent.sh               (создать нового агента)
│   ├── token-refresh.sh           (сам скрипт обновления токена)
│   └── templates/
│       ├── launchd.plist.template (Mac)
│       ├── systemd.service.template (Linux)
│       └── agent.env.example
│
└── docs/
    ├── setup-slack-app.md
    ├── multi-project.md
    ├── always-on.md
    ├── token-refresh.md
    └── roadmap-cloud.md
```

---

## .gitignore (создай первым)

```gitignore
.env
*.env
.claude/
access.json
node_modules/
dist/
.cache/
.DS_Store
*.log
*.lock
```

---

## .claude-plugin/marketplace.json

```json
{
  "name": "y0mcp",
  "version": "0.1.0",
  "description": "Slack channel plugin for Claude Code. Multi-project, permission relay, always-on.",
  "owner": {
    "name": "y0mcp",
    "email": "",
    "url": "https://github.com/[owner]/y0mcp"
  },
  "plugins": [
    {
      "name": "slack",
      "description": "Connect Claude Code to Slack. Permission relay, Dozzle logs, token refresh.",
      "version": "0.1.0",
      "category": "communication",
      "tags": ["slack", "channels", "multi-project", "devops", "permissions"],
      "author": {
        "name": "y0mcp",
        "url": "https://github.com/[owner]/y0mcp"
      },
      "source": {
        "source": "git-subdir",
        "url": "https://github.com/[owner]/y0mcp.git",
        "ref": "main",
        "path": "plugins/slack"
      }
    }
  ]
}
```

---

## plugins/slack/plugin.json

```json
{
  "name": "slack",
  "version": "0.1.0",
  "description": "Slack channel plugin for Claude Code with permission relay and token refresh",
  "author": { "name": "y0mcp", "url": "https://github.com/[owner]/y0mcp" },
  "runtime": "bun",
  "main": "server.ts",
  "channel": true,
  "configuration": {
    "SLACK_BOT_TOKEN":    { "required": true,  "secret": true },
    "SLACK_APP_TOKEN":    { "required": true,  "secret": true },
    "SLACK_CHANNEL_ID":   { "required": true  },
    "SLACK_CHANNEL_NAME": { "required": false },
    "AGENT_NAME":         { "required": false },
    "DOZZLE_URL":         { "required": false },
    "DOZZLE_TOKEN":       { "required": false, "secret": true }
  }
}
```

---

## plugins/slack/package.json

```json
{
  "name": "@y0mcp/y0slack",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "start": "bun server.ts",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "latest",
    "@slack/bolt": "^3.19.0",
    "zod": "^3.22.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@types/node": "latest"
  }
}
```

---

## plugins/slack/server.ts

Изучи официальный контракт:
- https://code.claude.com/docs/en/channels-reference
- https://github.com/anthropics/claude-plugins-official/tree/main/external_plugins/telegram

### Импорты и MCP Server

```typescript
import { Server } from '@modelcontextprotocol/sdk/server/index.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { App } from '@slack/bolt'
import { z } from 'zod'
import { loadAccess, isAllowed, generatePairingCode, addToAllowlist } from './pairing.js'
import { handlePermissionRelay, resolvePermission } from './permissions.js'
import { checkTokenHealth } from './token.js'
import { getDozzleLogs } from './dozzle.js'

const CHANNEL_ID = process.env.SLACK_CHANNEL_ID!
const CHANNEL_NAME = process.env.SLACK_CHANNEL_NAME || CHANNEL_ID
const AGENT_NAME = process.env.AGENT_NAME || 'default'

const server = new Server(
  { name: 'y0mcp-slack', version: '0.1.0' },
  {
    capabilities: {
      experimental: {
        'claude/channel': {},
        'claude/channel/permission': {}
      }
    },
    instructions: `You are connected to Slack channel #${CHANNEL_NAME}.
Working directory is the current project directory.
${process.env.DOZZLE_URL ? `Container logs available via dozzle_logs tool.` : ''}
Use Slack markdown: *bold*, \`code\`, \`\`\`blocks\`\`\`.
Permission requests for risky actions are sent to Slack automatically — wait for ✅/❌ before proceeding.`
  }
)
```

### Slack App

```typescript
const app = new App({
  token: process.env.SLACK_BOT_TOKEN!,
  appToken: process.env.SLACK_APP_TOKEN!,
  socketMode: true,
})

let currentTs: string | undefined
```

### Входящие сообщения

```typescript
app.message(async ({ message }) => {
  if (message.channel !== CHANNEL_ID) return
  if (message.subtype === 'bot_message') return

  const text = 'text' in message ? (message.text || '') : ''
  const userId = 'user' in message ? message.user! : 'unknown'
  const ts = 'ts' in message ? message.ts! : ''

  currentTs = ts

  // паринг
  if (!isAllowed(userId)) {
    const code = generatePairingCode(userId)
    await app.client.chat.postMessage({
      channel: CHANNEL_ID,
      text: `Pairing request from <@${userId}>.\nEnter in Claude Code terminal: \`/pair ${code}\``,
    })
    console.log(`[y0mcp] Pairing: /pair ${code}`)
    return
  }

  // typing indicator
  await app.client.reactions.add({
    channel: CHANNEL_ID, timestamp: ts, name: 'thinking_face'
  }).catch(() => {})

  // форвард в Claude Code
  await server.notification({
    method: 'notifications/claude/channel',
    params: {
      content: `<channel source="slack" sender="${userId}" channel="${CHANNEL_ID}" ts="${ts}">${text}</channel>`,
      meta: { channelId: CHANNEL_ID, ts, userId }
    }
  })
})
```

### Реакции — permission relay

```typescript
app.event('reaction_added', async ({ event }) => {
  if (event.item.channel !== CHANNEL_ID) return
  const emoji = event.reaction
  if (emoji === 'white_check_mark' || emoji === 'x') {
    await resolvePermission(event.item.ts, emoji === 'white_check_mark')
  }
})
```

### Tool: reply

```typescript
server.tool('reply', {
  message: z.string(),
  in_thread: z.boolean().optional()
}, async ({ message, in_thread }) => {
  for (const chunk of splitMessage(message, 3000)) {
    await app.client.chat.postMessage({
      channel: CHANNEL_ID,
      text: chunk,
      thread_ts: in_thread ? currentTs : undefined,
      mrkdwn: true
    })
  }
  return { content: [{ type: 'text', text: 'sent' }] }
})
```

### Tool: react

```typescript
server.tool('react', {
  emoji: z.string(),
  ts: z.string().optional()
}, async ({ emoji, ts }) => {
  await app.client.reactions.add({
    channel: CHANNEL_ID,
    timestamp: ts || currentTs!,
    name: emoji
  })
  return { content: [{ type: 'text', text: 'reacted' }] }
})
```

### Tool: request_permission

```typescript
server.tool('request_permission', {
  request_id: z.string(),
  action: z.string(),
  description: z.string(),
  risk_level: z.enum(['low', 'medium', 'high'])
}, async ({ request_id, action, description, risk_level }) => {
  const emoji = { low: '🟢', medium: '🟡', high: '🔴' }[risk_level]

  const result = await app.client.chat.postMessage({
    channel: CHANNEL_ID,
    text: `${emoji} *Permission required*\n\n*Action:* \`${action}\`\n*Reason:* ${description}\n\nReact ✅ to approve or ❌ to deny\n_Timeout: 5 minutes_`,
    mrkdwn: true
  })

  const approved = await handlePermissionRelay(request_id, result.ts!, 5 * 60 * 1000)

  await app.client.chat.update({
    channel: CHANNEL_ID,
    ts: result.ts!,
    text: approved
      ? `✅ *Approved* — \`${action}\``
      : `❌ *Denied* — \`${action}\``
  })

  return { content: [{ type: 'text', text: approved ? 'approved' : 'denied' }] }
})
```

### Tool: dozzle_logs

```typescript
if (process.env.DOZZLE_URL) {
  server.tool('dozzle_logs', {
    container: z.string(),
    lines: z.number().default(100)
  }, async ({ container, lines }) => {
    const logs = await getDozzleLogs(
      process.env.DOZZLE_URL!, container, lines, process.env.DOZZLE_TOKEN
    )
    return { content: [{ type: 'text', text: logs }] }
  })
}
```

### splitMessage

```typescript
function splitMessage(text: string, max: number): string[] {
  if (text.length <= max) return [text]
  const chunks: string[] = []
  const lines = text.split('\n')
  let cur = ''
  for (const line of lines) {
    if ((cur + '\n' + line).length > max) {
      if (cur) chunks.push(cur.trim())
      cur = line
    } else {
      cur = cur ? cur + '\n' + line : line
    }
  }
  if (cur) chunks.push(cur.trim())
  return chunks
}
```

### Запуск с heartbeat и проверкой токена

```typescript
await loadAccess()

// проверить здоровье токена при старте
const tokenStatus = await checkTokenHealth()
if (tokenStatus.expiresInMinutes < 60) {
  console.warn(`[y0mcp] ⚠️ Token expires in ${tokenStatus.expiresInMinutes} minutes`)
}

await app.start()

// heartbeat в Slack при старте
await app.client.chat.postMessage({
  channel: CHANNEL_ID,
  text: `🟢 *y0mcp agent started*\n` +
        `Agent: \`${AGENT_NAME}\` | Channel: #${CHANNEL_NAME}\n` +
        `${process.env.DOZZLE_URL ? `Dozzle: ${process.env.DOZZLE_URL}\n` : ''}` +
        `${tokenStatus.expiresInMinutes < 120
          ? `⚠️ Token expires in ${tokenStatus.expiresInMinutes} min — run \`scripts/token-refresh.sh\``
          : `Token valid for ~${Math.round(tokenStatus.expiresInMinutes / 60)}h`}`,
  mrkdwn: true
})

console.log(`[y0mcp] ✓ Agent: ${AGENT_NAME}`)
console.log(`[y0mcp] ✓ Channel: #${CHANNEL_NAME}`)
console.log(`[y0mcp] ✓ Permission relay: enabled`)
console.log(`[y0mcp] Token expires in: ${tokenStatus.expiresInMinutes} min`)

// heartbeat при падении — через process exit handler
process.on('SIGTERM', async () => {
  await app.client.chat.postMessage({
    channel: CHANNEL_ID,
    text: `🔴 *y0mcp agent stopped* (${AGENT_NAME})\n_launchd/systemd will restart automatically_`
  }).catch(() => {})
  process.exit(0)
})

process.on('uncaughtException', async (err) => {
  await app.client.chat.postMessage({
    channel: CHANNEL_ID,
    text: `🔴 *y0mcp agent crashed* (${AGENT_NAME})\nError: \`${err.message}\`\n_Restarting..._`
  }).catch(() => {})
  process.exit(1)
})

const transport = new StdioServerTransport()
await server.connect(transport)
```

---

## plugins/slack/token.ts

Проверка здоровья OAuth токена:

```typescript
import { readFile } from 'fs/promises'
import { homedir } from 'os'
import { join } from 'path'

interface TokenStatus {
  valid: boolean
  expiresInMinutes: number
  expiresAt: Date | null
}

export async function checkTokenHealth(): Promise<TokenStatus> {
  try {
    // Mac хранит в Keychain, Linux/Windows в файле
    const credPath = join(homedir(), '.claude', '.credentials.json')
    const data = JSON.parse(await readFile(credPath, 'utf-8'))
    const oauth = data.claudeAiOauth

    if (!oauth?.expiresAt) {
      return { valid: false, expiresInMinutes: 0, expiresAt: null }
    }

    const expiresAt = new Date(oauth.expiresAt)
    const expiresInMinutes = Math.round((expiresAt.getTime() - Date.now()) / 60000)

    return {
      valid: expiresInMinutes > 0,
      expiresInMinutes: Math.max(0, expiresInMinutes),
      expiresAt
    }
  } catch {
    // токен в Keychain (Mac) — не можем проверить напрямую
    return { valid: true, expiresInMinutes: 999, expiresAt: null }
  }
}
```

---

## plugins/slack/permissions.ts

```typescript
interface Pending {
  requestId: string
  messageTs: string
  resolve: (approved: boolean) => void
  timer: Timer
}

const byId = new Map<string, Pending>()
const byTs = new Map<string, Pending>()

export async function handlePermissionRelay(
  requestId: string,
  messageTs: string,
  timeoutMs: number
): Promise<boolean> {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      byId.delete(requestId)
      byTs.delete(messageTs)
      resolve(false) // таймаут → deny
    }, timeoutMs)

    const entry = { requestId, messageTs, resolve, timer }
    byId.set(requestId, entry)
    byTs.set(messageTs, entry)
  })
}

export async function resolvePermission(messageTs: string, approved: boolean) {
  const entry = byTs.get(messageTs)
  if (!entry) return
  clearTimeout(entry.timer)
  byId.delete(entry.requestId)
  byTs.delete(messageTs)
  entry.resolve(approved)
}
```

---

## plugins/slack/pairing.ts

```typescript
import { readFile, writeFile, mkdir } from 'fs/promises'
import { homedir } from 'os'
import { join } from 'path'

const dir = join(homedir(), '.y0mcp', process.env.AGENT_NAME || 'default')
const file = join(dir, 'access.json')

interface Access {
  allowlist: string[]
  pendingPairs: Record<string, string>
}

let access: Access = { allowlist: [], pendingPairs: {} }

export async function loadAccess() {
  try {
    access = JSON.parse(await readFile(file, 'utf-8'))
  } catch {
    await mkdir(dir, { recursive: true })
  }
}

async function save() {
  await writeFile(file, JSON.stringify(access, null, 2))
}

export function isAllowed(userId: string) {
  return access.allowlist.includes(userId)
}

export function generatePairingCode(userId: string): string {
  const code = Math.random().toString(36).substring(2, 8).toUpperCase()
  access.pendingPairs[code] = userId
  save()
  return code
}

export async function addToAllowlist(code: string): Promise<string | null> {
  const userId = access.pendingPairs[code]
  if (!userId) return null
  access.allowlist.push(userId)
  delete access.pendingPairs[code]
  await save()
  return userId
}
```

---

## plugins/slack/dozzle.ts

```typescript
export async function getDozzleLogs(
  baseUrl: string, container: string, lines: number, token?: string
): Promise<string> {
  const url = `${baseUrl}/api/containers/${container}/logs?tail=${lines}`
  const headers: Record<string, string> = { 'Accept': 'application/json' }
  if (token) headers['Authorization'] = `Bearer ${token}`
  try {
    const res = await fetch(url, { headers })
    if (!res.ok) return `Dozzle error: ${res.status} ${res.statusText}`
    return await res.text()
  } catch (e) {
    return `Cannot connect to Dozzle at ${baseUrl}: ${e}`
  }
}
```

---

## scripts/token-refresh.sh

Скрипт обновления OAuth токена. Запускается launchd/systemd каждые 2 часа.
Использует file lock чтобы несколько агентов не конфликтовали.

```bash
#!/bin/bash
# y0mcp token refresh script
# Runs every 2 hours via launchd/systemd

set -e

LOCK_FILE="$HOME/.y0mcp/token-refresh.lock"
CREDENTIALS="$HOME/.claude/.credentials.json"
LOG="$HOME/.y0mcp/token-refresh.log"
BUFFER_MINUTES=30  # обновить за 30 минут до истечения

mkdir -p "$HOME/.y0mcp"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"
}

# file lock — только один процесс обновляет токен
(
  flock -n 9 || { log "Another refresh in progress, skipping"; exit 0; }

  log "Checking token health..."

  # проверить нужно ли обновление
  if [ -f "$CREDENTIALS" ]; then
    EXPIRES_AT=$(cat "$CREDENTIALS" | python3 -c "
import json, sys
data = json.load(sys.stdin)
oauth = data.get('claudeAiOauth', {})
print(oauth.get('expiresAt', 0))
" 2>/dev/null || echo 0)

    NOW_MS=$(($(date +%s) * 1000))
    BUFFER_MS=$((BUFFER_MINUTES * 60 * 1000))
    EXPIRES_MS=$EXPIRES_AT

    if [ "$EXPIRES_MS" -gt "$((NOW_MS + BUFFER_MS))" ]; then
      REMAINING_MIN=$(( (EXPIRES_MS - NOW_MS) / 60000 ))
      log "Token valid for ${REMAINING_MIN} more minutes, skipping refresh"
      exit 0
    fi

    log "Token expires soon, refreshing..."
  fi

  # обновить через claude CLI
  if claude auth refresh 2>/dev/null; then
    log "✓ Token refreshed successfully"
  else
    log "⚠️ Auto-refresh failed — manual re-login may be required"
    log "Run: claude /login"
  fi

) 9>"$LOCK_FILE"
```

---

## scripts/setup-token-refresh.sh

Устанавливает автоматическое обновление токена.

```bash
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
```

---

## scripts/new-agent.sh

Создать нового агента интерактивно:

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
Y0PS_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔══════════════════════════════╗"
echo "║     y0mcp — new agent         ║"
echo "╚══════════════════════════════╝"
echo ""

read -p "Agent name (e.g. project-a): " AGENT_NAME
read -p "Slack channel ID (C...): " SLACK_CHANNEL_ID
read -p "Slack channel name (e.g. project-a): " SLACK_CHANNEL_NAME
read -p "Project path (e.g. ~/projects/project-a): " WORKSPACE_PATH
read -p "Dozzle URL (optional, press Enter to skip): " DOZZLE_URL

WORKSPACE_PATH="${WORKSPACE_PATH/#\~/$HOME}"

# создать .env
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

# установить launchd/systemd
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
    <string>source ${ENV_FILE} && cd ${WORKSPACE_PATH} && claude --dangerously-load-development-channels --channels plugin:y0slack@y0mcp</string>
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
ExecStart=$(which claude) --dangerously-load-development-channels --channels plugin:y0slack@y0mcp
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
```

---

## scripts/install.sh

Полная установка на чистую машину:

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
Y0PS_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔══════════════════════════════╗"
echo "║      y0mcp installer          ║"
echo "╚══════════════════════════════╝"
echo ""

# 1. Проверить Claude Code
if ! command -v claude &> /dev/null; then
  echo "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code
fi

# 2. Проверить Bun
if ! command -v bun &> /dev/null; then
  echo "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  source ~/.bashrc
fi

# 3. Установить зависимости плагина
echo "Installing plugin dependencies..."
cd "$Y0PS_DIR/plugins/slack"
bun install

# 4. Проверить авторизацию Claude
if [ ! -f "$HOME/.claude/.credentials.json" ]; then
  echo ""
  echo "⚠️  Not logged in to Claude Code."
  echo "Run: claude"
  echo "Then re-run this script."
  exit 1
fi

echo "✓ Claude Code authenticated"

# 5. Установить token refresh
echo "Setting up token refresh..."
bash "$SCRIPT_DIR/setup-token-refresh.sh"

# 6. Создать папку для данных
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
```

---

## README.md

### Header

```markdown
# y0mcp

Control your dev projects from Slack using your claude.ai subscription.

Multi-project routing. Permission relay. Always-on with auto token refresh.
No API key required — works with claude.ai Pro/Max.
```

Badges: MIT, Claude Code, Slack, macOS/Linux

### Why y0mcp

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

### How it works

```
You → Slack #project-a → y0mcp → Claude Code in ~/projects/project-a
                               ↕ permission relay (✅/❌ in Slack)
                               → Dozzle API (optional)
```

### Quick Start

**1. Добавить маркетплейс и установить плагин** — в Claude Code терминале:
```
/plugin marketplace add es-ua/y0mcp
/plugin install y0slack@y0mcp
```

**2. Создать Slack App** — см. [Setup Slack App](https://y0mcp.dev/guides/slack-app/)

**3. Создать агента:**
```bash
bash scripts/new-agent.sh
```

**4. Запустить:**
```bash
# Mac
launchctl load ~/Library/LaunchAgents/dev.y0mcp.my-project.plist

# Linux
systemctl --user enable --now y0mcp-my-project
```

**5. Pairing** — написать боту в Slack → получить код → `/pair ABC123` в терминале

### Permission relay

```
🔴 Permission required

Action: `rm -rf ./node_modules`
Reason: Cleaning before reinstall

React ✅ to approve or ❌ to deny (timeout: 5 min)
```

### Always-on

- Agents start automatically on login
- Auto-restart on crash (KeepAlive)
- OAuth token refreshed every 2 hours

### Multiple projects

Each agent is independent — separate Slack channel, separate repo, separate process.
Run as many as you need. Token refresh uses file locking to prevent conflicts.

### Requirements

- macOS or Linux
- Claude Code CLI (claude.ai login)
- claude.ai Pro or Max subscription
- Slack workspace (admin access to create apps)

### Security

- Socket Mode — no public URL exposed
- Pairing — only you can message the agent
- Permission relay — approve/deny risky actions from Slack
- Token refresh under file lock — no race conditions

### Roadmap

- v1: Slack + permission relay + always-on ← now
- v2: Hosted `mcp.y0mcp.dev` — connect agents to cloud, API keys, subscriptions

---

## docs/setup-slack-app.md

Пошаговый гайд (один Slack App на все агенты):

1. api.slack.com/apps → Create New App → From scratch
2. Socket Mode → Enable → Generate App Token (`xapp-`) → сохрани
3. OAuth & Permissions → Bot Token Scopes:
   - `channels:history`
   - `channels:read`
   - `groups:history` (private каналы)
   - `groups:read` (private каналы)
   - `chat:write`
   - `chat:write.public`
   - `reactions:add`
   - `reactions:read`
   - `reactions:write`
4. Event Subscriptions → Enable → Subscribe to bot events:
   - `message.channels` (public каналы)
   - `message.groups` (private каналы)
   - `reaction_added`
5. Install to Workspace → Bot Token (`xoxb-`) → сохрани
6. В каждом Slack канале: `/invite @имя-бота`

Один Bot Token и один App Token используются для всех агентов.
Каждый агент фильтрует сообщения по своему `SLACK_CHANNEL_ID`.

---

## Важные детали

- `.gitignore` создаёшь первым
- `agents/*.env` не коммитится — там токены
- `access.json` хранится в `~/.y0mcp/{AGENT_NAME}/` — не в репе
- Credentials читаются из `~/.claude/` автоматически
- Один Slack App (один Bot Token) на все агенты — агенты разделяются по channel_id
- После создания всех файлов: `git status` не должен показывать секреты

---

## Известные ограничения

- Channels работает только в CLI, не в VS Code расширении
- research preview: `--dangerously-load-development-channels` нужен до принятия в маркетплейс
- Известные баги: #36802, #37072 в anthropics/claude-code

---

## Сайт — site/

Astro Starlight сайт в папке `site/`. Контент берётся из `docs/`.

### Структура

```
site/
├── astro.config.mjs
├── package.json
├── tsconfig.json
└── src/
    ├── content/
    │   └── docs/          ← симлинк или копия из ../docs/
    ├── assets/
    │   ├── logo.svg
    │   └── og-image.png
    └── pages/
        └── index.astro    ← кастомный лендинг поверх Starlight
```

### Инициализация

```bash
cd site
npm create astro@latest . -- --template starlight
npm install
```

### astro.config.mjs

```js
import { defineConfig } from 'astro/config'
import starlight from '@astrojs/starlight'
import sitemap from '@astrojs/sitemap'

export default defineConfig({
  site: 'https://y0mcp.dev',
  integrations: [
    sitemap(),
    starlight({
      title: 'y0mcp',
      description: 'Control your dev projects from Slack using your claude.ai subscription.',
      logo: { src: './src/assets/logo.svg' },
      social: {
        github: 'https://github.com/[owner]/y0mcp',
        discord: 'https://discord.gg/[invite]',
      },
      sidebar: [
        {
          label: 'Getting Started',
          items: [
            { label: 'Quick Start', slug: 'guides/quickstart' },
            { label: 'Setup Slack App', slug: 'guides/slack-app' },
            { label: 'Always-on Setup', slug: 'guides/always-on' },
          ]
        },
        {
          label: 'Guides',
          items: [
            { label: 'Multiple Projects', slug: 'guides/multi-project' },
            { label: 'Permission Relay', slug: 'guides/permissions' },
            { label: 'Dozzle Logs', slug: 'guides/dozzle' },
            { label: 'Token Refresh', slug: 'guides/token-refresh' },
          ]
        },
        {
          label: 'Reference',
          items: [
            { label: 'Configuration', slug: 'reference/config' },
            { label: 'Roadmap', slug: 'reference/roadmap' },
          ]
        }
      ],
      customCss: ['./src/styles/custom.css'],
    }),
  ],
})
```

### src/pages/index.astro — кастомный лендинг

Не используй дефолтную Starlight главную. Сделай кастомную страницу:

```astro
---
import StarlightPage from '@astrojs/starlight/components/StarlightPage.astro'
---

<StarlightPage frontmatter={{ title: 'y0mcp', template: 'splash' }}>

  <!-- Hero -->
  <section class="hero">
    <h1>Control your dev projects<br/>from <span class="slack">Slack</span></h1>
    <p>
      Multi-project routing. Permission relay. Always-on.<br/>
      Works with your claude.ai Pro/Max subscription — no API key required.
    </p>
    <div class="cta">
      <a href="/guides/quickstart" class="btn-primary">Get Started</a>
      <a href="https://github.com/[owner]/y0mcp" class="btn-secondary">GitHub</a>
      <a href="https://discord.gg/[invite]" class="btn-discord">Discord</a>
    </div>
  </section>

  <!-- Демо — Slack переписка -->
  <section class="demo">
    <!-- Покажи реалистичный mock Slack чата:
         Пользователь: "check nginx logs on staging"
         y0mcp bot: "Last 50 lines from nginx on staging: ..."
         Пользователь: "fix the 502 errors"
         y0mcp bot: 🔴 Permission required / Action: restart nginx / React ✅ to approve
         Пользователь: [ставит ✅]
         y0mcp bot: "✅ nginx restarted. 502 errors resolved."
    -->
  </section>

  <!-- Сравнение -->
  <section class="comparison">
    <h2>Why y0mcp</h2>
    <table>
      <thead>
        <tr>
          <th></th>
          <th>OpenClaw</th>
          <th>Claude Code Channels</th>
          <th>y0mcp</th>
        </tr>
      </thead>
      <tbody>
        <tr><td>Slack</td><td>✓</td><td>✗</td><td>✓</td></tr>
        <tr><td>Multi-project routing</td><td>✓</td><td>✗</td><td>✓</td></tr>
        <tr><td>Permission relay in Slack</td><td>✗</td><td>✗</td><td>✓</td></tr>
        <tr><td>claude.ai subscription</td><td>✗</td><td>✓</td><td>✓</td></tr>
        <tr><td>API key required</td><td>✓</td><td>✗</td><td>✗</td></tr>
        <tr><td>Auto token refresh</td><td>✗</td><td>✗</td><td>✓</td></tr>
        <tr><td>Always-on (launchd/systemd)</td><td>✗</td><td>✗</td><td>✓</td></tr>
      </tbody>
    </table>
  </section>

  <!-- Install -->
  <section class="install">
    <h2>Get started in minutes</h2>
    <pre><code># In Claude Code terminal:
/plugin marketplace add es-ua/y0mcp
/plugin install y0slack@y0mcp</code></pre>
  </section>

  <!-- Три фичи -->
  <section class="features">
    <div class="feature">
      <h3>💬 Slack-native</h3>
      <p>One agent per project. Each agent listens to its own Slack channel.
         Switch between projects by switching channels.</p>
    </div>
    <div class="feature">
      <h3>🔐 Permission relay</h3>
      <p>Claude asks before risky actions. Approve or deny with a reaction
         directly in Slack — no terminal needed.</p>
    </div>
    <div class="feature">
      <h3>🟢 Always-on</h3>
      <p>Agents run as launchd/systemd services. Auto-restart on crash.
         OAuth tokens refresh automatically every 2 hours.</p>
    </div>
  </section>

  <!-- Discord CTA -->
  <section class="community">
    <h2>Join the community</h2>
    <p>Questions, ideas, show your setup</p>
    <a href="https://discord.gg/[invite]" class="btn-discord">Join Discord</a>
  </section>

</StarlightPage>
```

### src/styles/custom.css

Добавь кастомные стили поверх Starlight темы:
- Цвета под y0mcp бренд (тёмная тема, акцент — фиолетовый или зелёный)
- Стили для `.hero`, `.demo`, `.comparison`, `.features`, `.install`
- Mock Slack UI для демо секции — тёмный фон, аватары, сообщения
- Responsive

### src/content/docs/

Создай следующие файлы (контент из `../docs/`):

```
guides/
├── quickstart.md
├── slack-app.md
├── always-on.md
├── multi-project.md
├── permissions.md
├── dozzle.md
└── token-refresh.md
reference/
├── config.md
└── roadmap.md
```

Каждый файл — frontmatter + markdown контент адаптированный из `../docs/`.

### package.json для site/

```json
{
  "name": "y0mcp-site",
  "type": "module",
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview"
  },
  "dependencies": {
    "astro": "^5.0.0",
    "@astrojs/starlight": "latest",
    "@astrojs/sitemap": "latest"
  }
}
```

### Деплой на Vercel/Cloudflare

В корне репы создай `vercel.json`:

```json
{
  "buildCommand": "cd site && npm install && npm run build",
  "outputDirectory": "site/dist",
  "framework": "astro"
}
```

Или Cloudflare Pages:
- Build command: `cd site && npm install && npm run build`
- Build output: `site/dist`

### Обновить структуру проекта

Добавь `site/` в общую структуру репы и в `.gitignore` добавь:

```
site/node_modules/
site/dist/
site/.astro/
```

---

## Когда всё готово

Скажи мне. Я:
1. Создам Slack App и получу токены
2. Запущу `/plugin marketplace add es-ua/y0mcp`
3. Запущу `/plugin install y0slack@y0mcp`
4. Запущу `bash scripts/new-agent.sh` и заполню данные агента
5. Запущу агента и сделаю pairing в Slack

Жди моих команд на каждом шаге.
