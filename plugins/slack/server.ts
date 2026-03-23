import { Server } from '@modelcontextprotocol/sdk/server/index.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { App } from '@slack/bolt'
import { z } from 'zod'
import { loadAccess, isAllowed, generatePairingCode, addToAllowlist } from './pairing.js'
import { handlePermissionRelay, resolvePermission } from './permissions.js'
import { checkTokenHealth } from './token.js'
import { getDozzleLogs } from './dozzle.js'

const CHANNEL_ID = process.env.SLACK_CHANNEL_ID!
const AGENT_NAME = process.env.AGENT_NAME || 'default'
let CHANNEL_NAME = CHANNEL_ID // resolved at startup via API

// MCP uses stdout for JSON-RPC — all logs must go to stderr
const log = (...args: unknown[]) => console.error('[y0mcp]', ...args)
const warn = (...args: unknown[]) => console.error('[y0mcp] ⚠️', ...args)

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

// Slack App
const app = new App({
  token: process.env.SLACK_BOT_TOKEN!,
  appToken: process.env.SLACK_APP_TOKEN!,
  socketMode: true,
  // Bolt logs to stdout by default — redirect to stderr to avoid corrupting MCP transport
  logger: {
    debug: (...args: unknown[]) => {},
    info: (...args: unknown[]) => console.error('[bolt]', ...args),
    warn: (...args: unknown[]) => console.error('[bolt]', ...args),
    error: (...args: unknown[]) => console.error('[bolt]', ...args),
    setLevel: () => {},
    getLevel: () => 'info' as any,
    setName: () => {},
  },
})

let currentTs: string | undefined

// Incoming messages
app.message(async ({ message }) => {
  if (message.channel !== CHANNEL_ID) return
  if (message.subtype === 'bot_message') return

  const text = 'text' in message ? (message.text || '') : ''
  const userId = 'user' in message ? message.user! : 'unknown'
  const ts = 'ts' in message ? message.ts! : ''

  currentTs = ts

  // pairing
  if (!isAllowed(userId)) {
    const code = generatePairingCode(userId)
    await app.client.chat.postMessage({
      channel: CHANNEL_ID,
      text: `Pairing request from <@${userId}>.\nEnter in Claude Code terminal: \`/pair ${code}\``,
    })
    log(`Pairing: /pair ${code}`)
    return
  }

  // typing indicator
  await app.client.reactions.add({
    channel: CHANNEL_ID, timestamp: ts, name: 'thinking_face'
  }).catch(() => {})

  // forward to Claude Code
  await server.notification({
    method: 'notifications/claude/channel',
    params: {
      content: `<channel source="slack" sender="${userId}" channel="${CHANNEL_ID}" ts="${ts}">${text}</channel>`,
      meta: { channelId: CHANNEL_ID, ts, userId }
    }
  })
})

// Reactions — permission relay
app.event('reaction_added', async ({ event }) => {
  if (event.item.channel !== CHANNEL_ID) return
  const emoji = event.reaction
  if (emoji === 'white_check_mark' || emoji === 'x') {
    await resolvePermission(event.item.ts, emoji === 'white_check_mark')
  }
})

// Tool: reply
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

// Tool: react
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

// Tool: request_permission
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

// Tool: dozzle_logs (conditional)
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

// splitMessage helper
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

// Startup
await loadAccess()

// Check token health on start
const tokenStatus = await checkTokenHealth()
if (tokenStatus.expiresInMinutes < 60) {
  warn(`Token expires in ${tokenStatus.expiresInMinutes} minutes`)
}

await app.start()

// Resolve channel name from Slack API
try {
  const info = await app.client.conversations.info({ channel: CHANNEL_ID })
  CHANNEL_NAME = info.channel?.name || CHANNEL_ID
} catch {
  warn(`Could not resolve channel name for ${CHANNEL_ID}`)
}

// Heartbeat on start
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

log(`✓ Agent: ${AGENT_NAME}`)
log(`✓ Channel: #${CHANNEL_NAME}`)
log(`✓ Permission relay: enabled`)
log(`Token expires in: ${tokenStatus.expiresInMinutes} min`)

// Heartbeat on shutdown
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
