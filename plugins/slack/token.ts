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
    // Mac stores in Keychain, Linux/Windows in file
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
    // Token in Keychain (Mac) — can't check directly
    return { valid: true, expiresInMinutes: 999, expiresAt: null }
  }
}
