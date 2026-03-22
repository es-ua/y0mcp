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
