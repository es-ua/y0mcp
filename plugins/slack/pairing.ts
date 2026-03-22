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
