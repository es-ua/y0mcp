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
      resolve(false) // timeout → deny
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
