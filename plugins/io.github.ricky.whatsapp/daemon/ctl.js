#!/usr/bin/env node
// Thin NDJSON client for the daemon socket. No dependencies, so it works before
// `npm install` has ever run in daemon/.

import net from 'node:net'
import { socketPath } from './lib/paths.js'

const [command, ...args] = process.argv.slice(2)

const USAGE = `Usage: omarchy-whatsapp-ctl <command> [args]

  status                 connection state, linked account, unread count
  chats [limit]          most recent chats as JSON
  refresh [jid] [limit]  resync chats from WhatsApp, then dump the list
  messages <jid> [limit] a chat's recent messages as JSON
  send <jid> <text...>   send a text message
  read <jid>             mark a chat read
  focus <jid>            select that chat in every open bar panel
  login                  start QR pairing (stops after 5 minutes)
  pair <phone>           request an 8-digit pairing code instead of a QR
  reconnect              drop the socket and reconnect
  repair [jid]            reset stale encrypted sessions and re-key contacts;
                          with a jid, only that contact (fast re-key)
  logout                 unlink this device and clear local credentials
  ping                   check the daemon is alive
`

if (!command || command === '-h' || command === '--help') {
  process.stdout.write(USAGE)
  process.exit(command ? 0 : 1)
}

function buildRequest() {
  switch (command) {
    case 'status':
      return { t: 'hello' }
    case 'ping':
      return { t: 'ping' }
    case 'chats':
      return { t: 'chats', limit: Number(args[0]) || 40 }
    case 'refresh':
      return { t: 'refresh', jid: args[0] || undefined, limit: Number(args[1]) || 40 }
    case 'messages':
      if (!args[0]) fail('messages: jid required')
      return { t: 'messages', jid: args[0], limit: Number(args[1]) || 60 }
    case 'send': {
      let replyId = undefined
      let imagePath = undefined
      const cleanArgs = []
      for (let i = 0; i < args.length; i++) {
        if ((args[i] === '--reply' || args[i] === '--quote') && i + 1 < args.length) {
          replyId = args[++i]
        } else if ((args[i] === '--image' || args[i] === '--attach' || args[i] === '-i') && i + 1 < args.length) {
          imagePath = args[++i]
        } else {
          cleanArgs.push(args[i])
        }
      }
      if (cleanArgs.length < 1) fail('send: jid required (usage: send <jid> [text...] [--image <path>] [--reply <id>])')
      if (cleanArgs.length < 2 && !imagePath) fail('send: message text or --image required')
      const payload = { t: 'send', jid: cleanArgs[0] }
      if (cleanArgs.length > 1) payload.text = cleanArgs.slice(1).join(' ')
      if (replyId) payload.quoted = replyId
      if (imagePath) payload.image = imagePath
      return payload
    }
    case 'read':
      if (!args[0]) fail('read: jid required')
      return { t: 'read', jid: args[0] }
    case 'focus':
      if (!args[0]) fail('focus: jid required')
      return { t: 'focus', jid: args[0] }
    case 'login':
      return { t: 'login' }
    case 'pair':
      if (!args[0]) fail('pair: phone number required')
      return { t: 'pair', phone: args[0] }
    case 'reconnect':
      return { t: 'reconnect' }
    case 'repair':
      return { t: 'repair', jid: args[0] || undefined }
    case 'logout':
      return { t: 'logout' }
    default:
      fail(`unknown command: ${command}\n\n${USAGE}`)
  }
}

function fail(message) {
  process.stderr.write(`omarchy-whatsapp-ctl: ${message}\n`)
  process.exit(1)
}

const request = buildRequest()
const socket = net.connect(socketPath)
let buffer = ''
let settled = false

// Large accounts re-key hundreds of peers; allow the repair plenty of time.
const timeout = setTimeout(() => {
  if (settled) return
  settled = true
  socket.destroy()
  fail('timed out waiting for the daemon')
}, 300000)

socket.on('connect', () => socket.write(`${JSON.stringify(request)}\n`))

socket.on('data', (chunk) => {
  buffer += chunk.toString('utf8')
  let index = buffer.indexOf('\n')
  while (index !== -1) {
    const line = buffer.slice(0, index).trim()
    buffer = buffer.slice(index + 1)
    index = buffer.indexOf('\n')
    if (!line) continue

    let payload
    try {
      payload = JSON.parse(line)
    } catch {
      continue
    }

    // Every client gets a `state` push on connect (for `status` that *is* the
    // answer) and, while commands run, the daemon broadcasts live activity to
    // every connected client: chats updates, incoming messages, status ticks,
    // media paths, focus requests. Those are all noise to a one-shot CLI caller
    // — only the direct reply to this command settles it.
    const broadcastTypes = new Set(['state', 'chats', 'message', 'messageStatus', 'messageMedia', 'focus', 'pairCode'])
    if (payload.t === 'state' && command !== 'status') continue
    if (command !== 'status' && broadcastTypes.has(payload.t)) continue

    settled = true
    clearTimeout(timeout)
    process.stdout.write(`${JSON.stringify(payload, null, 2)}\n`)
    socket.end()
    process.exit(payload.t === 'error' || payload.ok === false ? 1 : 0)
  }
})

socket.on('error', (err) => {
  if (settled) return
  settled = true
  clearTimeout(timeout)
  if (err.code === 'ENOENT' || err.code === 'ECONNREFUSED') {
    fail('daemon is not running. Start it with: systemctl --user start omarchy-whatsapp')
  }
  fail(String(err.message || err))
})

socket.on('close', () => {
  if (settled) return
  settled = true
  clearTimeout(timeout)
  fail('daemon closed the connection without answering')
})
