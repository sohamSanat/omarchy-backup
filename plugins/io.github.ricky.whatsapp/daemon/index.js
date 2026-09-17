import { chmodSync, copyFileSync, existsSync, readdirSync, readFileSync, rmSync, writeFileSync, unlinkSync } from 'node:fs'
import { spawn } from 'node:child_process'
import { extname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import makeWASocket, {
  Browsers,
  DisconnectReason,
  fetchLatestBaileysVersion,
  jidDecode,
  jidEncode,
  jidNormalizedUser,
  makeCacheableSignalKeyStore,
  useMultiFileAuthState,
  USyncQuery,
  USyncUser
} from 'baileys'
import QRCode from 'qrcode'

import { authDir, ensureDirs, mediaDir, pidFile, qrPngFileFor, qrTxtFile, socketPath, stateDir } from './lib/paths.js'
import { logger, waLogger } from './lib/logger.js'
import { Store, normalizeJid } from './lib/store.js'
import { Notifier } from './lib/notify.js'
import { Bus } from './lib/server.js'
import { extractImage, extractQuotedInfo, isGroupJid, isIgnorableChat, isPhotoPlaceholder, isSilent, messageText, messageType, prettyJid } from './lib/message.js'
import { existingMediaPath, mediaPathFor, MediaCache } from './lib/media.js'
import {
  applyChatNotificationPreferences,
  isChatMuted,
  muteExpiryDelayMs,
  shouldNotifyChat
} from './lib/preferences.js'
import { watchPluginState as observePluginState } from './lib/plugin-state.js'

const __dirname = fileURLToPath(new URL('.', import.meta.url))

// Ensure Baileys does not drop peer retry receipts due to recipient attribute
function ensureBaileysPatched() {
  try {
    const target = join(__dirname, 'node_modules', 'baileys', 'lib', 'Socket', 'messages-recv.js')
    if (!existsSync(target)) return
    let content = readFileSync(target, 'utf8')
    const unpatched = "const fromMe = !attrs.recipient || ((attrs.type === 'sender') && isNodeFromMe);"
    const patched = "const fromMe = !attrs.recipient || attrs.type === 'retry' || ((attrs.type === 'sender') && isNodeFromMe);"
    if (content.includes(unpatched)) {
      content = content.replace(unpatched, patched)
      writeFileSync(target, content, 'utf8')
      logger.info('baileys: auto-patched retry receipt handling in messages-recv.js')
    }
  } catch (err) {
    logger.warn({ err }, 'baileys: failed to patch messages-recv.js')
  }
}
ensureBaileysPatched()

const RECONNECT_BASE_MS = 2000
const RECONNECT_MAX_MS = 60000
// WhatsApp hands out a batch of ~6 QR refs and then closes the socket with 408.
// That is the normal rhythm of pairing, not a failure, so the next batch is one
// quick reconnect away rather than an exponential backoff.
const PAIRING_RETRY_MS = 1500
// 515 means "handshake done, reconnect now" and arrives right after a successful
// scan. Waiting here would stall the login the user just completed.
const RESTART_RETRY_MS = 250
// Pairing does not run forever. Without this the daemon regenerates a QR every
// 20s for as long as it is enabled, hammering WhatsApp's pairing endpoint for an
// account that may never be linked.
const PAIRING_WINDOW_MS = Math.max(
  15000,
  Number(process.env.OMARCHY_WHATSAPP_PAIRING_WINDOW_MS) || 5 * 60 * 1000
)
const MAX_QR_PER_PAIRING = 32
const PRINT_QR = process.env.OMARCHY_WHATSAPP_PRINT_QR === '1'

// Messages predating this run are backlog, not news: they were already
// notified by the phone, so replaying them as toasts on every daemon start
// would be noise.
const startedAt = Math.floor(Date.now() / 1000)

// proto.WebMessageInfo.Status: 0 error, 1 pending, 2 server, 3 delivered, 4 read, 5 played.
const MSG_PENDING = 1
const MSG_SERVER_ACK = 2
const MSG_DELIVERED = 3
const MSG_READ = 4
const MSG_PLAYED = 5

// In-memory cache of recent proto.Messages (sent and received) for fulfilling
// Baileys retry requests and rich quotes with 100% fidelity.
const MAX_MESSAGE_CACHE = 1000
const messageCache = new Map()

function cacheMessage(id, rawMsg) {
  if (!id || !rawMsg) return
  if (messageCache.size >= MAX_MESSAGE_CACHE) {
    const firstKey = messageCache.keys().next().value
    messageCache.delete(firstKey)
  }
  messageCache.set(id, rawMsg)
}

// Signal sessions are per-peer-device negotiation state. When a contact
// relinks their phone (or after a WhatsApp outage), the session both sides
// believed was current goes stale: messages the panel sends are accepted by the
// server (grey tick) but encrypted with a key the peer no longer holds.
// Genuine crypto failures (Bad MAC or No session) are recorded and automatically
// healed without requiring manual intervention.
// Note: MessageCounterError is normal replay protection for duplicate offline
// stanzas in libsignal-protocol and is intentionally NOT treated as session failure.
const brokenSessions = new Map() // remoteJid -> { count, lastSeen }
const autoHealTimers = new Map() // remoteJid -> timestamp
let cryptoErrorCount = 0
let lastCryptoError = ''

function rememberCryptoFailure(jid, message) {
  if (!jid) return
  const entry = brokenSessions.get(jid) || { count: 0, lastSeen: 0 }
  entry.count += 1
  entry.lastSeen = Date.now()
  brokenSessions.set(jid, entry)
  cryptoErrorCount += 1
  lastCryptoError = String(message || 'signal session error').slice(0, 240)
  pushState()
}

function scheduleAutoHeal(jid) {
  if (!jid) return
  const norm = normalizeJid(jid)
  if (!norm) return
  const lastHeal = autoHealTimers.get(norm) || 0
  const now = Date.now()
  if (now - lastHeal < 60_000) return
  autoHealTimers.set(norm, now)

  logger.info({ jid: norm }, 'session: auto-healing Signal session for contact')
  setTimeout(async () => {
    try {
      if (!sock || connection !== 'open') return
      clearSignalSessions(norm)
      await rekeyAllSessions(norm)
      brokenSessions.delete(norm)
      if (brokenSessions.size === 0) {
        cryptoErrorCount = 0
        lastCryptoError = ''
        pushState()
      }
      logger.info({ jid: norm }, 'session: auto-heal completed for contact')
    } catch (err) {
      logger.warn({ err, jid: norm }, 'session: auto-heal encountered an error')
    }
  }, 1000).unref?.()
}

// Watch the logger handed to Baileys so session breakage on any peer is noticed
// and healed automatically. This only records state; it never alters or swallows log lines.
function wrapWaLogger(base) {
  return new Proxy(base, {
    get(target, prop) {
      if (typeof prop !== 'string') return target[prop]
      const value = target[prop]
      if (typeof value !== 'function' || !['error', 'fatal', 'warn'].includes(prop)) return value
      return (...args) => {
        try {
          const obj = args.find((a) => a && typeof a === 'object') || {}
          const err = obj.err || obj
          const remoteJid = typeof obj.key === 'string' ? obj.key : obj.key?.remoteJid || ''
          const message = String(err?.message || err?.name || err?.type || '')
          if (
            /Bad MAC/.test(message) ||
            (err?.type === 'SessionError' && /No session/.test(message))
          ) {
            const jid = String(remoteJid || '')
            rememberCryptoFailure(jid, `${err.type || err.name || 'CryptoError'}: ${message}`)
            if (jid) scheduleAutoHeal(jid)
          }
        } catch {
          // Watching must never take logging down with it.
        }
        return value.apply(target, args)
      }
    }
  })
}
const watchedWaLogger = wrapWaLogger(waLogger)

const store = new Store()
const notifier = new Notifier()
const media = new MediaCache()
const bus = new Bus(socketPath)

let sock = null
let connection = 'idle'
let qrVersion = 0
let hasQr = false
let currentQrPng = ''
// Pairing window bookkeeping, plus the live creds so a 401 can be told apart
// from "this pairing attempt was rejected".
let pairingStartedAt = 0
let qrCount = 0
let pairingStopped = true
let pairingWanted = false
let creds = null
let needsLogin = false
let lastError = ''
let reconnectAttempts = 0
let reconnectTimer = null
let connecting = false
let stopping = false
let connectGen = 0
let chatsFlushTimer = null
let lastStateJson = ''
let resolvingNames = false
let refreshInFlight = false
// `repair` wipes and rebuilds the key store; a concurrent second run could
// delete sessions the first just wrote, so it must be single-flight.
let repairInFlight = false
const groupNames = new Map()
const wantedChats = new Set()
/** @type {Map<string, NodeJS.Timeout>} */
const muteExpiryTimers = new Map()
const APP_STATE_COLLECTIONS = [
  'critical_block',
  'critical_unblock_low',
  'regular_high',
  'regular_low',
  'regular'
]

function clearMuteExpiry(jid) {
  const timer = muteExpiryTimers.get(jid)
  if (!timer) return
  clearTimeout(timer)
  muteExpiryTimers.delete(jid)
}

// Timed mutes must refresh the bar badge when they elapse, even with no new
// WhatsApp event. Always mutes (-1) never arm a timer.
function scheduleMuteExpiry(chat) {
  if (!chat?.jid) return
  clearMuteExpiry(chat.jid)
  const delay = muteExpiryDelayMs(chat)
  if (delay === null) return
  if (delay === 0) {
    chat.muted = false
    return
  }
  const timer = setTimeout(() => {
    muteExpiryTimers.delete(chat.jid)
    const current = store.chat(chat.jid)
    if (!current || isChatMuted(current)) return
    current.muted = false
    store.markDirty()
    pushState()
    pushChatsSoon()
  }, Math.min(delay, 2_147_483_647))
  timer.unref?.()
  muteExpiryTimers.set(chat.jid, timer)
}

// Baileys timestamps arrive as number | Long | string depending on where in the
// protocol they came from.
function toTs(value) {
  if (value === null || value === undefined) return 0
  if (typeof value === 'number') return Math.floor(value)
  if (typeof value === 'string') return Math.floor(Number(value) || 0)
  if (typeof value.toNumber === 'function') return Math.floor(value.toNumber())
  if (typeof value.low === 'number') return Math.floor(value.low)
  return 0
}

function isLinked() {
  return !!(creds?.registered || creds?.me?.id || store.me?.id)
}

function state() {
  return {
    t: 'state',
    connection,
    needsLogin,
    hasQr,
    qrVersion,
    qrPng: hasQr ? currentQrPng : '',
    pairingStopped,
    linked: isLinked(),
    me: store.me,
    unread: store.totalUnread(),
    lastError,
    cryptoErrorCount,
    lastCryptoError,
    repairHint: cryptoErrorCount > 0
      ? `stale signal sessions with ${brokenSessions.size} contact(s); run: omarchy-whatsapp-ctl repair`
      : '',
    daemonPid: process.pid
  }
}

function snapshot() {
  return { ...state(), t: 'state', chats: store.chatList(60) }
}

function pushState() {
  const next = state()
  const key = JSON.stringify(next)
  if (key === lastStateJson) return
  lastStateJson = key
  bus.broadcast(next)
}

function pushChats(limit = 60) {
  bus.broadcast({ t: 'chats', chats: store.chatList(limit), unread: store.totalUnread() })
}

function pushChatsSoon() {
  if (chatsFlushTimer) return
  chatsFlushTimer = setTimeout(() => {
    chatsFlushTimer = null
    pushChats()
  }, 300)
  chatsFlushTimer.unref?.()
}

async function pullLatestFromWhatsApp() {
  if (!sock || connection !== 'open') return false
  if (typeof sock.resyncAppState === 'function') {
    await sock.resyncAppState(APP_STATE_COLLECTIONS, false)
  }
  if (typeof sock.cleanDirtyBits === 'function') {
    await sock.cleanDirtyBits('account_sync')
  }
  return true
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

function senderNameFor(chatJid, message) {
  if (message.key?.fromMe) return store.me?.name || 'You'
  const participant = message.key?.participant || message.participant
  if (isGroupJid(chatJid) && participant) {
    return store.lookupName(participant)
      || store.lookupName(message.key?.participantPn)
      || message.pushName
      || prettyJid(participant)
  }
  return store.lookupName(chatJid) || message.pushName || prettyJid(chatJid)
}

function learnAliasesFromMessage(raw) {
  const key = raw?.key || {}
  if (key.remoteJid && (key.remoteJidAlt || key.senderPn)) {
    store.alias(key.remoteJid, key.remoteJidAlt || key.senderPn)
  }
  if (key.senderLid && key.senderPn) store.alias(key.senderLid, key.senderPn)
  if (key.participant && key.participantPn) store.alias(key.participant, key.participantPn)
  if (key.participantLid && key.participantPn) store.alias(key.participantLid, key.participantPn)
}

function storedToWaContent(message) {
  if (!message) return undefined
  if (message.media) {
    const node = { mimetype: message.media.mimetype }
    if (message.text && !isPhotoPlaceholder(message.text)) node.caption = message.text
    if (message.media.kind === 'sticker') return { stickerMessage: node }
    if (message.media.kind === 'video') return { videoMessage: node }
    return { imageMessage: node }
  }
  if (!message.text) return undefined
  return { conversation: message.text }
}

async function getStoredMessage(key) {
  if (!key?.id) return undefined
  const cached = messageCache.get(key.id)
  if (cached) return cached
  const canonical = store.canonicalJid(key.remoteJid) || key.remoteJid
  const found = store.findMessage(key.remoteJid, key.id) || (canonical ? store.findMessage(canonical, key.id) : null)
  return storedToWaContent(found)
}

const RECENT_APPEND_WINDOW_S = 5 * 60

function isRecentIncoming(message) {
  const ts = message?.ts || 0
  return ts >= Math.max(0, startedAt - RECENT_APPEND_WINDOW_S)
}

// Convert a raw Baileys message into the flat shape the panel renders and the
// store persists.
function publicMessage(message) {
  if (!message) return message
  const { media: _ignored, ...rest } = message
  return rest
}

function asStatus(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value
  if (value && typeof value.toNumber === 'function') {
    const n = value.toNumber()
    return Number.isFinite(n) ? n : 0
  }
  const n = Number(value)
  return Number.isFinite(n) ? n : 0
}

function statusFromReceipt(receipt) {
  if (!receipt || typeof receipt !== 'object') return 0
  const type = receipt.receiptType || receipt.type
  if (receipt.readTimestamp || type === 'read' || type === 'read-self') return MSG_READ
  if (type === 'played') return MSG_PLAYED
  if (type === 'sender') return MSG_SERVER_ACK
  if (receipt.receiptTimestamp || type === undefined || type === 'inactive' || type === 'peer_msg') {
    return MSG_DELIVERED
  }
  return 0
}

function applyMessageStatus(jid, id, status) {
  const next = asStatus(status)
  if (!id || next < MSG_PENDING) return false
  const canonical = store.canonicalJid(jid) || normalizeJid(jid) || jid
  const found = store.findMessage(canonical, id)
  if (!found) return false
  if (next <= (found.status || 0)) return false
  found.status = next
  store.markDirty()
  const chatJid = store.canonicalJid(found.key?.remoteJid) || found.key?.remoteJid || canonical
  bus.broadcast({ t: 'messageStatus', jid: chatJid, id, status: next })
  if (chatJid !== canonical) {
    bus.broadcast({ t: 'messageStatus', jid: canonical, id, status: next })
  }
  return true
}

function flatten(chatJid, message) {
  const ts = toTs(message.messageTimestamp)
  const image = extractImage(message.message)
  const id = message.key?.id || `${ts}-${Math.random().toString(36).slice(2, 8)}`
  const flat = {
    id,
    ts,
    fromMe: !!message.key?.fromMe,
    text: image ? (image.caption || messageText(message.message)) : messageText(message.message),
    type: messageType(message.message),
    senderName: senderNameFor(chatJid, message),
    senderJid: message.key?.participant ? jidNormalizedUser(message.key.participant) : '',
    status: asStatus(message.status),
    key: {
      remoteJid: message.key?.remoteJid || chatJid,
      id: message.key?.id || '',
      fromMe: !!message.key?.fromMe,
      participant: message.key?.participant || undefined
    }
  }
  if (image) {
    const { caption, ...payload } = image
    flat.media = payload
    flat.imagePath = existingMediaPath({ id, media: payload, imagePath: '' })
  }

  const quotedInfo = extractQuotedInfo(message.message)
  if (quotedInfo) {
    const existingQuoted = store.findMessage(chatJid, quotedInfo.id)
    const normParticipant = quotedInfo.participant ? (jidNormalizedUser(quotedInfo.participant) || quotedInfo.participant) : ''

    let isFromMe = false
    if (existingQuoted) {
      isFromMe = !!existingQuoted.fromMe
    } else if (normParticipant) {
      const myId = store.me?.id ? jidNormalizedUser(store.me.id) : ''
      const myPn = myId ? myId.split('@')[0].split(':')[0] : ''
      const partPn = normParticipant.split('@')[0].split(':')[0]
      if (myPn && partPn && myPn === partPn) isFromMe = true
    } else if (!isGroupJid(chatJid) && message.key?.fromMe === false) {
      isFromMe = true
    }

    let quotedText = ''
    if (existingQuoted && existingQuoted.text) {
      quotedText = existingQuoted.text
    } else if (quotedInfo.quotedMessage) {
      const qImage = extractImage(quotedInfo.quotedMessage)
      quotedText = qImage ? (qImage.caption || messageText(quotedInfo.quotedMessage)) : messageText(quotedInfo.quotedMessage)
    }

    let senderName = ''
    if (isFromMe) {
      senderName = 'You'
    } else if (existingQuoted && existingQuoted.senderName) {
      senderName = existingQuoted.senderName
    } else if (normParticipant) {
      senderName = store.lookupName(normParticipant) || prettyJid(normParticipant)
    } else if (!isGroupJid(chatJid)) {
      senderName = store.lookupName(chatJid) || prettyJid(chatJid)
    }

    flat.quoted = {
      id: quotedInfo.id,
      fromMe: isFromMe,
      senderName: senderName || (isFromMe ? 'You' : 'Message'),
      senderJid: normParticipant,
      text: quotedText || ''
    }
  }

  return flat
}

async function resolveGroupName(jid) {
  if (!isGroupJid(jid) || groupNames.has(jid) || !sock) return
  groupNames.set(jid, true)
  try {
    const metadata = await sock.groupMetadata(jid)
    if (metadata?.subject) {
      store.rememberName(jid, metadata.subject)
      pushChats()
    }
  } catch (err) {
    logger.debug({ err, jid }, 'group metadata lookup failed')
  }
}

function ingest(chatJid, raw) {
  if (isIgnorableChat(chatJid)) return null
  if (isSilent(raw.message)) return null

  if (raw?.key?.id && raw.message) {
    cacheMessage(raw.key.id, raw.message)
  }

  learnAliasesFromMessage(raw)
  const hintedPn = raw?.key?.remoteJidAlt || raw?.key?.senderPn
  if (hintedPn) store.alias(chatJid, hintedPn)
  const canonicalTarget = store.canonicalJid(chatJid) || store.canonicalJid(hintedPn) || chatJid
  if (String(canonicalTarget).endsWith('@lid')) scheduleLidResolve(canonicalTarget)

  const message = flatten(canonicalTarget, raw)
  if (!message.ts) message.ts = Math.floor(Date.now() / 1000)

  const existed = !!store.findMessage(canonicalTarget, message.id)

  store.upsertMessage(canonicalTarget, message)
  const chat = store.touchChat(canonicalTarget, message)

  if (!chat.isGroup && !raw.key?.fromMe && raw.pushName) {
    store.rememberPushName(canonicalTarget, raw.pushName)
  }

  const participant = raw.key?.participant || raw.participant
  if (chat.isGroup && !raw.key?.fromMe && participant && raw.pushName) {
    store.rememberPushName(participant, raw.pushName)
  }

  resolveGroupName(canonicalTarget)

  if (message.fromMe) store.setUnread(canonicalTarget, 0)

  const chatKey = normalizeJid(canonicalTarget)
  if (message.media && !message.imagePath && (wantedChats.has(chatKey) || wantedChats.has(canonicalTarget))) {
    media.enqueue(canonicalTarget, message)
  }
  return { message, canonicalTarget, existed }
}

function applyChatMetadata(rawChats) {
  let unreadChanged = false
  for (const raw of rawChats || []) {
    const jid = raw?.id
    if (!jid || isIgnorableChat(jid)) continue
    const canonical = store.canonicalJid(jid) || normalizeJid(jid) || jid
    if (raw.pnJid) store.alias(canonical, raw.pnJid)
    if (raw.lidJid) store.alias(canonical, raw.lidJid)
    const chat = store.chat(canonical)
    if (raw.name) store.rememberName(canonical, raw.name)

    if (raw.unreadCount !== undefined && raw.unreadCount !== null) {
      let count = 0
      if (typeof raw.unreadCount === 'number') {
        // In WhatsApp protocol, unreadCount = -1 means "marked as unread" on another device
        count = raw.unreadCount < 0 ? 1 : raw.unreadCount
      }
      if (chat.unread !== count) {
        store.setUnread(canonical, count)
        unreadChanged = true
      }
      chat.lastUnreadSync = Date.now()
    } else if (raw.unread === true || raw.markedUnread === true) {
      if (chat.unread === 0) {
        store.setUnread(canonical, 1)
        unreadChanged = true
      }
      chat.lastUnreadSync = Date.now()
    } else if (raw.unread === false || raw.read === true) {
      if (chat.unread !== 0) {
        store.setUnread(canonical, 0)
        unreadChanged = true
      }
      chat.lastUnreadSync = Date.now()
    }

    if (raw.conversationTimestamp !== undefined) {
      const ts = toTs(raw.conversationTimestamp)
      if (ts > (chat.lastTs || 0)) chat.lastTs = ts
    }
    applyChatNotificationPreferences(chat, raw)
    if (raw.muteEndTime !== undefined) scheduleMuteExpiry(chat)
    // A message and its app-state preference update can be delivered in the
    // same buffered batch. If the message queued a toast first, honor the
    // newly synced mute/archive state before the coalesce timer fires.
    if (chat.archived || isChatMuted(chat)) {
      notifier.cancel(chat.jid)
      notifier.cancel(canonical)
      if (canonical !== jid) notifier.cancel(jid)
    }
    if (raw.pinned !== undefined) chat.pinned = !!raw.pinned
  }
  store.applyNamesToChats()
  store.markDirty()
  return unreadChanged
}

function asLidJid(value) {
  if (!value) return ''
  const raw = String(value)
  if (raw.includes('@')) return normalizeJid(raw)
  return `${raw}@lid`
}

const pendingLidResolves = new Set()

function scheduleLidResolve(jid) {
  const lid = asLidJid(jid)
  if (!lid.endsWith('@lid')) return
  if (store.canonicalJid(lid).endsWith('@s.whatsapp.net')) return
  if (pendingLidResolves.has(lid)) return
  pendingLidResolves.add(lid)
  resolveOneLid(lid)
    .catch((err) => logger.debug({ err, jid: lid }, 'lid resolve failed'))
    .finally(() => pendingLidResolves.delete(lid))
}

async function resolveOneLid(lid) {
  if (!sock || connection !== 'open') return
  const query = new USyncQuery().withContactProtocol().withLIDProtocol()
  query.withUser(new USyncUser().withLid(lid).withId(lid))
  const result = await sock.executeUSyncQuery(query)
  let merged = false
  for (const row of result?.list || []) {
    const resolvedLid = asLidJid(row.lid || (String(row.id || '').endsWith('@lid') ? row.id : ''))
    const pn = String(row.id || '').endsWith('@s.whatsapp.net') ? row.id : ''
    if (resolvedLid && pn) {
      store.alias(resolvedLid, pn)
      merged = true
    }
  }
  if (merged) {
    store.applyNamesToChats()
    pushChats()
  }
}

async function resolveContactLids() {
  if (!sock || connection !== 'open' || resolvingNames) return
  resolvingNames = true
  try {
    const phones = [...store.names.keys()].filter((jid) => jid.endsWith('@s.whatsapp.net'))
    for (let i = 0; i < phones.length; i += 25) {
      if (!sock || connection !== 'open') return
      try {
        const rows = await sock.onWhatsApp(...phones.slice(i, i + 25))
        for (const row of rows || []) {
          if (row?.jid && row?.lid) store.alias(row.jid, asLidJid(row.lid))
        }
      } catch (err) {
        logger.debug({ err }, 'contact lid lookup failed')
        break
      }
    }

    const unknownLids = store.sortedChats()
      .filter((chat) => chat.jid.endsWith('@lid') && !store.lookupName(chat.jid))
      .slice(0, 50)
    if (unknownLids.length) {
      try {
        const query = new USyncQuery().withContactProtocol().withLIDProtocol()
        for (const chat of unknownLids) {
          query.withUser(new USyncUser().withLid(chat.jid).withId(chat.jid))
        }
        const result = await sock.executeUSyncQuery(query)
        for (const row of result?.list || []) {
          const lid = asLidJid(row.lid || (String(row.id || '').endsWith('@lid') ? row.id : ''))
          const pn = String(row.id || '').endsWith('@s.whatsapp.net') ? row.id : ''
          if (lid && pn) store.alias(lid, pn)
        }
      } catch (err) {
        logger.debug({ err }, 'lid usync failed')
      }
    }

    if (store.applyNamesToChats()) {
      logger.info({ names: store.names.size, aliases: store.aliases.size }, 'resolved contact names')
      pushChats()
    }
  } finally {
    resolvingNames = false
  }
}

// --- Session repair -----------------------------------------------------------
//
// Sessions and sender keys are pure negotiation state, unlike creds.json (the
// linked login) and the pre-keys (our identity on the wire). Relinking a phone,
// a WhatsApp outage, or an older session left behind by a previous run makes
// them go stale, and then messages silently stop decrypting on one side. The
// fix is to wipe that state and let every peer re-key from a fresh prekey
// bundle — exactly what the official apps do when they resync encryption.

function clearSignalSessions(onlyJid = '') {
  let removed = 0
  const targetUsers = new Set()
  if (onlyJid) {
    const norm = normalizeJid(onlyJid) || onlyJid
    const u1 = jidDecode(norm)?.user
    if (u1) targetUsers.add(u1)
    const alias = store.aliases.get(norm)
    if (alias) {
      const u2 = jidDecode(normalizeJid(alias))?.user
      if (u2) targetUsers.add(u2)
    }
  }
  try {
    for (const name of readdirSync(authDir)) {
      if (!name.startsWith('session-') && !name.startsWith('sender-key')) continue
      if (targetUsers.size) {
        let matches = false
        for (const u of targetUsers) {
          if (name.startsWith(`session-${u}.`) || name.includes(`--${u}--`)) {
            matches = true
            break
          }
        }
        if (!matches) continue
      }
      unlinkSync(join(authDir, name))
      removed += 1
    }
  } catch (err) {
    logger.warn({ err }, 'repair: wiping sessions failed')
  }
  return removed
}

// Fold a raw jid (anything the store has seen) into the peer map, remembering
// both addressing forms under every user key they touch — the phone number and
// the linked-id of the same account are separate signal users, and a peer whose
// client sends with its LID needs a session asserted under the LID user too.
function addPeerJid(peers, raw, alt) {
  const pairs = []
  for (const value of [raw, alt]) {
    if (!value) continue
    const { user } = jidDecode(String(value)) || {}
    if (user) pairs.push([user, String(value)])
  }
  if (!pairs.length) return
  const forms = { pn: '', lid: '' }
  for (const [, value] of pairs) {
    if (value.endsWith('@lid')) forms.lid = value
    else if (value.endsWith('@s.whatsapp.net')) forms.pn = value
  }
  for (const [user] of pairs) {
    const entry = peers.get(user) || { pn: '', lid: '' }
    if (forms.pn) entry.pn = forms.pn
    if (forms.lid) entry.lid = forms.lid
    peers.set(user, entry)
  }
}

// Re-establish fresh Signal sessions with every known peer — all aliased
// contacts, every chat, and every group member — by fetching current prekey
// bundles and injecting them, exactly as Baileys does on a normal send. Nothing
// user-visible is sent to anyone; the peer is not notified.
async function rekeyAllSessions(onlyJid = '') {
  if (!sock || connection !== 'open') return 0
  const peers = new Map()

  if (onlyJid) {
    const norm = normalizeJid(onlyJid) || onlyJid
    let resolved = false
    for (const [from, to] of store.aliases) {
      if (from === onlyJid || from === norm || to === onlyJid || to === norm) {
        addPeerJid(peers, from, to)
        resolved = true
      }
    }
    if (!resolved) {
      addPeerJid(peers, onlyJid)
      const mate = store.aliases.get(norm)
      if (mate) addPeerJid(peers, mate)
    }
  } else {
    for (const [from, to] of store.aliases) {
      addPeerJid(peers, from, to)
    }
    for (const chat of store.chats.values()) {
      addPeerJid(peers, chat.jid)
    }

    // Lid-addressed groups re-key every participant from fresh metadata so
    // members who only ever appear in group send-key fanout are covered too.
    for (const chat of store.chats.values()) {
      if (!chat.isGroup) continue
      try {
        const meta = await sock.groupMetadata(chat.jid)
        for (const participant of meta?.participants || []) {
          addPeerJid(peers, participant?.id, participant?.lid)
          addPeerJid(peers, participant?.lid)
        }
      } catch {
        // Best-effort; 1:1 peers above already cover most of the account.
      }
    }
  }

  // Resolve the current device list for every peer (both addressing forms).
  // The server normalizes every device row to the phone-number user, so after
  // fetching devices we assert each device under *every* form the account is
  // known by — peers that address messages with their linked-id need a session
  // stored under the LID user too, or their incoming messages won't decrypt.
  const requested = []
  for (const pair of peers.values()) {
    if (pair.pn) requested.push(pair.pn)
    if (pair.lid) requested.push(pair.lid)
  }
  const deviceJids = new Set()
  for (let i = 0; i < requested.length; i += 25) {
    const chunk = requested.slice(i, i + 25)
    const serverOf = new Map()
    for (const jid of chunk) {
      const { user } = jidDecode(jid) || {}
      if (user) serverOf.set(user, jid.endsWith('@lid') ? 'lid' : 's.whatsapp.net')
    }
    const devices = await sock.getUSyncDevices(chunk, false, false).catch(() => [])
    for (const device of devices || []) {
      if (!device?.user || device.device === undefined) continue
      const forms = new Set()
      if (serverOf.get(device.user)) forms.add(serverOf.get(device.user))
      const peer = peers.get(device.user)
      if (peer) {
        if (peer.lid) forms.add('lid')
        if (peer.pn) forms.add('s.whatsapp.net')
      }
      if (!forms.size) forms.add('s.whatsapp.net')
      for (const server of forms) {
        const userPart = server === 'lid' && peer?.lid ? (jidDecode(peer.lid)?.user || device.user) : device.user
        deviceJids.add(jidEncode(userPart, server, device.device))
      }
    }
  }

  if (deviceJids.size) {
    // Keep batches small: the encrypt-IQ for a batch of ~100 linked-id jids
    // routinely exceeded the query timeout and aborted the whole re-key. 25
    // stays well under it, and one slow batch must not sink the rest.
    const allDeviceJids = [...deviceJids]
    let failedBatches = 0
    for (let i = 0; i < allDeviceJids.length; i += 25) {
      try {
        await sock.assertSessions(allDeviceJids.slice(i, i + 25), true)
      } catch (err) {
        failedBatches += 1
        logger.debug({ err, offset: i }, 'repair: session batch re-key failed, continuing')
      }
    }
    if (failedBatches) {
      logger.warn({ failedBatches, total: Math.ceil(allDeviceJids.length / 25) }, 'repair: some session batches failed; any next send still re-keys automatically')
    }
  }
  return deviceJids.size
}

function applyContacts(contacts) {
  for (const contact of contacts || []) {
    if (!contact?.id && !contact?.lid && !contact?.jid) continue
    const ids = [contact.id, contact.lid, contact.jid].filter(Boolean).map((id) => normalizeJid(id) || id)
    for (let i = 1; i < ids.length; i++) store.alias(ids[0], ids[i])
    const addressBookName = contact.name || contact.verifiedName
    const pushName = contact.notify
    if (addressBookName) {
      for (const id of ids) store.rememberContactName(id, addressBookName)
    } else if (pushName) {
      for (const id of ids) store.rememberPushName(id, pushName)
    }
  }
  store.applyNamesToChats()
}

// Open a pairing window. Every QR the daemon shows is counted against it, so an
// unlinked account cannot keep the pairing endpoint busy indefinitely.
function startPairing(reason) {
  pairingWanted = true
  pairingStopped = false
  pairingStartedAt = Date.now()
  qrCount = 0
  logger.info({ reason }, 'pairing: window open')
}

// Stop refreshing and drop the QR rather than leave an expired code on screen
// pretending to be scannable. Login in the panel or `omarchy-whatsapp login`
// both reopen the window.
function stopPairing() {
  const shown = qrCount
  pairingWanted = false
  pairingStopped = true
  pairingStartedAt = 0
  qrCount = 0
  connectGen += 1
  connecting = false
  cancelReconnect()
  clearQr()
  connection = 'idle'
  needsLogin = true
  logger.info({ qrCount: shown }, 'pairing: no scan within the window, pausing QR refresh')
  pushState()
  destroySocket('pairing paused')
}

async function writeQr(qr) {
  if (pairingStopped) return
  if (pairingStartedAt === 0) startPairing('first qr')

  qrCount += 1
  if (qrCount > MAX_QR_PER_PAIRING || Date.now() - pairingStartedAt > PAIRING_WINDOW_MS) {
    stopPairing()
    return
  }

  const version = qrVersion + 1
  const target = qrPngFileFor(version)
  try {
    await QRCode.toFile(target, qr, { margin: 2, width: 512, color: { dark: '#000000ff', light: '#ffffffff' } })
    // A readable QR is a linkable account, so keep it owner-only even though
    // the state directory is already 0700.
    chmodSync(target, 0o600)
    const terminal = await QRCode.toString(qr, { type: 'terminal', small: true })
    writeFileSync(qrTxtFile, terminal, { mode: 0o600 })
    if (PRINT_QR) process.stdout.write(`\n${terminal}\n`)

    const previous = currentQrPng
    currentQrPng = target
    hasQr = true
    qrVersion = version
    connection = 'qr'
    needsLogin = true
    pushState()
    if (previous && previous !== target) removeFile(previous)
    logger.info('login: scan the QR from the WhatsApp bar panel or run `omarchy-whatsapp login`')
  } catch (err) {
    logger.error({ err }, 'login: could not render QR')
  }
}

function removeFile(path) {
  try {
    unlinkSync(path)
  } catch {
    // Nothing to clear.
  }
}

function clearQr() {
  hasQr = false
  if (currentQrPng) removeFile(currentQrPng)
  currentQrPng = ''
  removeFile(qrTxtFile)
}

function cancelReconnect() {
  if (!reconnectTimer) return
  clearTimeout(reconnectTimer)
  reconnectTimer = null
}

function destroySocket(reason) {
  const old = sock
  sock = null
  if (!old) return
  try {
    old.ev?.removeAllListeners?.()
  } catch {
    // Already gone.
  }
  try {
    old.end(reason ? new Error(reason) : undefined)
  } catch {
    // Already closed.
  }
  try {
    old.ws?.close?.()
  } catch {
    // Already closed.
  }
}

// `delayOverride` covers the disconnects that are part of normal operation
// (QR batch ended, post-pair restart). Those must not consume the backoff
// budget reserved for genuine network trouble.
function scheduleReconnect(delayOverride, options) {
  if (stopping || reconnectTimer || connecting) return
  if (pairingStopped && !isLinked()) return
  const countsAsFailure = !options || options.countsAsFailure !== false
  const delay = delayOverride !== undefined
    ? delayOverride
    : Math.min(RECONNECT_MAX_MS, RECONNECT_BASE_MS * 2 ** Math.min(reconnectAttempts, 5))
  if (countsAsFailure) reconnectAttempts += 1
  logger.info({ delay, reason: options?.reason || 'failure' }, 'connection: reconnecting')
  reconnectTimer = setTimeout(() => {
    reconnectTimer = null
    connect().catch((err) => {
      logger.error({ err }, 'connection: reconnect failed')
      scheduleReconnect()
    })
  }, delay)
  reconnectTimer.unref?.()
}

async function connect() {
  if (connecting || stopping) return
  if (!isLinked() && !pairingWanted) {
    needsLogin = true
    pairingStopped = true
    connection = 'idle'
    pushState()
    return
  }

  connecting = true
  connectGen += 1
  const gen = connectGen
  lastError = ''
  if (!isLinked()) {
    connection = 'connecting'
    pushState()
  }

  try {
    destroySocket('replaced')
    await sleep(400)
    if (stopping || gen !== connectGen) {
      if (gen === connectGen) connecting = false
      return
    }

    const { state: authState, saveCreds } = await useMultiFileAuthState(authDir)
    creds = authState.creds
    if (!isLinked() && !pairingWanted) {
      needsLogin = true
      pairingStopped = true
      connection = 'idle'
      connecting = false
      pushState()
      return
    }

    const { version } = await fetchLatestBaileysVersion().catch(() => ({ version: undefined }))
    if (stopping || gen !== connectGen) {
      if (gen === connectGen) connecting = false
      return
    }

    sock = makeWASocket({
      version,
      auth: {
        creds: authState.creds,
        keys: makeCacheableSignalKeyStore(authState.keys, waLogger)
      },
      logger: watchedWaLogger,
      // The phone keeps pushing its own notifications while this device stays
      // "offline", so the user never loses phone alerts by linking Omarchy.
      markOnlineOnConnect: false,
      browser: Browsers.ubuntu('Omarchy'),
      syncFullHistory: false,
      generateHighQualityLinkPreview: false,
      fireInitQueries: true,
      connectTimeoutMs: 30000,
      defaultQueryTimeoutMs: 30000,
      // Link previews and media thumbnails are never rendered here.
      shouldSyncHistoryMessage: () => true,
      // Lets Baileys retry / poll-decrypt using messages we already stored.
      getMessage: getStoredMessage
    })
    const thisSocket = sock

    sock.ev.on('creds.update', (update) => {
      if (sock !== thisSocket) return
      saveCreds(update)
      creds = { ...creds, ...update }
    })

    sock.ev.on('connection.update', (update) => {
      if (sock !== thisSocket) return
      const { connection: next, lastDisconnect, qr } = update
      if (qr) writeQr(qr)

      if (next === 'open') {
        connecting = false
        connection = 'open'
        needsLogin = false
        pairingWanted = false
        pairingStopped = false
        pairingStartedAt = 0
        qrCount = 0
        reconnectAttempts = 0
        lastError = ''
        clearQr()
        const user = thisSocket.user
        store.me = user
          ? { id: jidNormalizedUser(user.id), name: user.name || user.verifiedName || prettyJid(user.id) }
          : store.me
        if (user?.lid && user?.id) store.alias(user.id, user.lid)
        store.markDirty()
        logger.info({ me: store.me?.id }, 'connection: open')
        pushState()
        pushChats()
        setTimeout(() => {
          pullLatestFromWhatsApp()
            .catch((err) => logger.debug({ err }, 'startup resync failed'))
            .finally(() => {
              pushState()
              pushChats()
            })
          resolveContactLids().catch((err) => logger.debug({ err }, 'contact resolve failed'))
        }, 800).unref?.()
        return
      }

      if (next === 'close') {
        const statusCode = lastDisconnect?.error?.output?.statusCode
        lastError = lastDisconnect?.error?.message || ''
        connecting = false
        if (sock === thisSocket) sock = null

        if (statusCode === DisconnectReason.loggedOut) {
          // 401 means two very different things. If this device was actually
          // paired, the phone unlinked it and the credentials are dead. If it
          // was never paired, the server merely rejected this pairing attempt —
          // wiping there would throw away the chat cache for nothing.
          if (creds?.registered) {
            logger.warn('connection: device unlinked from the phone, clearing credentials')
            wipeAuth()
            creds = null
            needsLogin = true
            pairingWanted = false
            pairingStopped = true
            connection = 'idle'
            clearQr()
            pushState()
            pushChats()
          } else if (pairingWanted && !pairingStopped) {
            logger.warn('connection: pairing attempt rejected, retrying')
            needsLogin = true
            pushState()
            scheduleReconnect(PAIRING_RETRY_MS, { reason: 'pairing rejected', countsAsFailure: false })
          } else {
            needsLogin = true
            connection = 'idle'
            pushState()
          }
          return
        }

        if (pairingStopped && !isLinked()) {
          // Stay 'idle' rather than 'close': nothing is retrying, so reporting a
          // closed connection would read as a fault instead of a paused pairing.
          connection = 'idle'
          pushState()
          return
        }

        // Both of these are routine, not faults.
        if (statusCode === DisconnectReason.restartRequired) {
          logger.info('connection: restart required, reconnecting immediately')
          scheduleReconnect(RESTART_RETRY_MS, { reason: 'restart required', countsAsFailure: false })
          return
        }

        if (needsLogin && pairingWanted && statusCode === DisconnectReason.timedOut) {
          // Baileys uses 408 for both "QR refs ended" and "connection lost";
          // while unlinked and mid-pairing it is always the former.
          logger.info('connection: QR batch ended, requesting a fresh one')
          scheduleReconnect(PAIRING_RETRY_MS, { reason: 'qr batch ended', countsAsFailure: false })
          return
        }

        if (statusCode === DisconnectReason.connectionReplaced) {
          logger.warn('connection: session replaced, waiting before retry')
          scheduleReconnect(8000, { reason: 'session replaced' })
          return
        }

        logger.warn({ statusCode, lastError }, 'connection: closed')
        scheduleReconnect()
      }
    })

    sock.ev.on('messaging-history.set', ({ chats, contacts, messages, isLatest }) => {
      if (sock !== thisSocket) return
      const before = store.totalUnread()
      applyContacts(contacts)
      applyChatMetadata(chats)
      for (const raw of messages || []) {
        const jid = raw?.key?.remoteJid
        if (jid) ingest(jid, raw)
      }
      logger.info({ chats: chats?.length || 0, messages: messages?.length || 0, isLatest }, 'history sync')
      for (const [jid, list] of store.messages) {
        if (!wantedChats.has(jid) && !wantedChats.has(normalizeJid(jid))) continue
        for (const message of list) {
          if (message.media && !existingMediaPath(message)) media.enqueue(jid, message)
        }
      }
      pushChatsSoon()
      if (store.totalUnread() !== before) pushState()
    })

    sock.ev.on('chats.upsert', (chats) => {
      if (sock !== thisSocket) return
      const before = store.totalUnread()
      applyChatMetadata(chats)
      pushChatsSoon()
      if (store.totalUnread() !== before) pushState()
    })

    sock.ev.on('chats.update', (updates) => {
      if (sock !== thisSocket) return
      const before = store.totalUnread()
      const unreadChanged = applyChatMetadata(updates)
      pushChatsSoon()
      if (unreadChanged || store.totalUnread() !== before) pushState()
    })

    sock.ev.on('chats.delete', (jids) => {
      if (sock !== thisSocket) return
      for (const jid of jids || []) {
        store.chats.delete(jid)
        store.messages.delete(jid)
      }
      store.markDirty()
      pushChatsSoon()
    })

    sock.ev.on('chats.phoneNumberShare', ({ lid, jid }) => {
      if (sock !== thisSocket) return
      if (lid && jid) {
        store.alias(lid, jid)
        store.applyNamesToChats()
        pushChatsSoon()
      }
    })

    sock.ev.on('contacts.upsert', (contacts) => {
      if (sock !== thisSocket) return
      applyContacts(contacts)
      pushChatsSoon()
    })

    sock.ev.on('contacts.update', (contacts) => {
      if (sock !== thisSocket) return
      applyContacts(contacts)
      pushChatsSoon()
    })

    sock.ev.on('groups.update', (updates) => {
      if (sock !== thisSocket) return
      for (const update of updates || []) {
        if (update?.id && update.subject) store.rememberName(update.id, update.subject)
      }
      pushChatsSoon()
    })

    sock.ev.on('messages.upsert', ({ messages, type }) => {
      if (sock !== thisSocket) return
      const before = store.totalUnread()
      let ingested = false
      for (const raw of messages || []) {
        const jid = raw?.key?.remoteJid
        if (!jid) continue
        const result = ingest(jid, raw)
        if (!result) continue
        ingested = true
        const { message, canonicalTarget, existed } = result
        const live = type === 'notify' || (!existed && isRecentIncoming(message))
        if (live && !existed && !message.fromMe) {
          const chat = store.chat(canonicalTarget)
          const currentUnread = chat.unread || 0
          const now = Date.now()
          if (currentUnread === 0) store.setUnread(canonicalTarget, 1)
          else if (!(currentUnread === 1 && chat.lastUnreadSync && (now - chat.lastUnreadSync < 5000))) {
            store.bumpUnread(canonicalTarget)
          }
          chat.lastUnreadSync = now
          if (message.ts >= startedAt) {
            const title = chat.isGroup ? (chat.name || 'Group') : (message.senderName || chat.name)
            const body = chat.isGroup ? `${message.senderName}: ${message.text}` : message.text
            notifier.queue({
              jid: canonicalTarget,
              title,
              body,
              shouldNotify: () => shouldNotifyChat(store.chat(canonicalTarget))
            })
          }
        }
        if (!live) continue
        if (message.media && !message.imagePath) media.enqueue(canonicalTarget, message)
        bus.broadcast({
          t: 'message',
          jid: canonicalTarget,
          message: publicMessage(message),
          chat: store.chat(canonicalTarget),
          unread: store.totalUnread()
        })
      }
      const unreadChanged = store.totalUnread() !== before
      if (ingested) pushChatsSoon()
      if (unreadChanged) pushState()
    })

    sock.ev.on('messages.update', (updates) => {
      if (sock !== thisSocket) return
      const before = store.totalUnread()
      let unreadCleared = false
      for (const update of updates || []) {
        const jid = update?.key?.remoteJid || update?.remoteJid
        if (!jid) continue
        const canonical = store.canonicalJid(jid) || normalizeJid(jid) || jid

        const u = update.update || update
        if (u.readTimestamp || u.status === 3 || u.status === 4 || u.type === 'read-self') {
          store.setUnread(canonical, 0)
          unreadCleared = true
        }

        const id = update?.key?.id || update?.id
        if (!id) continue
        const status = asStatus(u.status) || (u.readTimestamp ? MSG_READ : 0)
        applyMessageStatus(canonical, id, status)
      }
      if (unreadCleared || store.totalUnread() !== before) {
        pushChatsSoon()
        pushState()
      }
    })

    sock.ev.on('message-receipt.update', (updates) => {
      if (sock !== thisSocket) return
      const before = store.totalUnread()
      let unreadCleared = false
      for (const update of updates || []) {
        const jid = update?.key?.remoteJid
        if (!jid) continue
        const canonical = store.canonicalJid(jid) || normalizeJid(jid) || jid

        const receipt = update.receipt || {}
        const receiptType = receipt.receiptType || receipt.type
        const isReadReceipt = receipt.readTimestamp || receiptType === 'read' || receiptType === 'read-self'

        if (isReadReceipt) {
          store.setUnread(canonical, 0)
          unreadCleared = true
        }

        const id = update?.key?.id
        if (!id) continue
        applyMessageStatus(canonical, id, statusFromReceipt(receipt))
      }
      if (unreadCleared || store.totalUnread() !== before) {
        pushChatsSoon()
        pushState()
      }
    })
  } catch (err) {
    if (gen !== connectGen) return
    connecting = false
    lastError = String(err?.message || err)
    logger.error({ err }, 'connection: setup failed')
    pushState()
    scheduleReconnect()
  }
}

function wipeAuth() {
  try {
    rmSync(authDir, { recursive: true, force: true })
  } catch (err) {
    logger.warn({ err }, 'auth: wipe failed')
  }
  ensureDirs()
  store.clear()
  groupNames.clear()
  try {
    rmSync(mediaDir, { recursive: true, force: true })
  } catch {
    // Cache may already be gone.
  }
}

// Mark a chat read on this device and across the account, then drop any toast
// still waiting in the coalesce window.
async function markRead(jid) {
  notifier.cancel(jid)
  store.setUnread(jid, 0)
  pushChats()
  pushState()
  if (!sock || connection !== 'open' || connecting) return

  const list = store.messages.get(jid) || []
  const unreadKeys = list.filter((m) => !m.fromMe).slice(-20).map((m) => m.key).filter((k) => k?.id)
  if (unreadKeys.length) {
    try {
      await sock.readMessages(unreadKeys)
    } catch (err) {
      logger.debug({ err, jid }, 'read receipts failed')
    }
  }

  const newest = list[list.length - 1]
  if (newest?.key?.id) {
    try {
      await sock.chatModify(
        { markRead: true, lastMessages: [{ key: newest.key, messageTimestamp: newest.ts }] },
        jid
      )
    } catch (err) {
      logger.debug({ err, jid }, 'chatModify markRead failed')
    }
  }
}

async function refreshMissingImages(jid, list) {
  if (!sock || connection !== 'open') return
  if (typeof sock.requestPlaceholderResend !== 'function') return
  const missing = list.filter((message) => (
    (message.type === 'imageMessage' || message.type === 'stickerMessage')
    && !message.media
    && message.key?.id
  ))
  for (const message of missing.slice(-12)) {
    try {
      await sock.requestPlaceholderResend(message.key)
    } catch (err) {
      logger.debug({ err, id: message.id }, 'media: placeholder resend failed')
    }
  }
}

async function handleCommand(payload, reply) {
  const { t, id } = payload
  switch (t) {
    case 'hello':
      reply(snapshot())
      return

    case 'ping':
      reply({ t: 'pong', id })
      return

    case 'chats':
      reply({ t: 'chats', chats: store.chatList(payload.limit || 60), unread: store.totalUnread() })
      return

    case 'refresh': {
      const limit = payload.limit || 60
      const messageLimit = payload.messageLimit || 60
      const jid = payload.jid ? String(payload.jid) : ''
      if (!refreshInFlight && sock && connection === 'open') {
        refreshInFlight = true
        try {
          await pullLatestFromWhatsApp()
        } catch (err) {
          logger.debug({ err }, 'refresh: whatsapp sync failed')
        } finally {
          refreshInFlight = false
        }
      }
      const chats = store.chatList(limit)
      const unread = store.totalUnread()
      pushState()
      bus.broadcast({ t: 'chats', chats, unread })
      if (jid) {
        const canonical = store.canonicalJid(jid) || jid
        const list = store.messageList(canonical, messageLimit)
        wantedChats.add(canonical)
        wantedChats.add(normalizeJid(jid))
        reply({
          t: 'messages',
          jid,
          chat: store.chat(canonical),
          messages: list.map(publicMessage),
          unread
        })
        for (const message of list) {
          if (message.media && !existingMediaPath(message)) media.enqueue(canonical, message)
        }
      } else {
        reply({ t: 'chats', chats, unread })
      }
      return
    }

    case 'messages':
      if (!payload.jid) throw new Error('messages: jid required')
      {
        const canonical = store.canonicalJid(payload.jid) || payload.jid
        const list = store.messageList(canonical, payload.limit || 60)
        wantedChats.add(canonical)
        wantedChats.add(normalizeJid(payload.jid))
        reply({
          t: 'messages',
          jid: payload.jid,
          chat: store.chat(canonical),
          messages: list.map(publicMessage)
        })
        for (const message of list) {
          if (message.media && !existingMediaPath(message)) media.enqueue(canonical, message)
        }
        refreshMissingImages(canonical, list).catch((err) => {
          logger.debug({ err, jid: canonical }, 'media: history refresh failed')
        })
      }
      return

    case 'send': {
      const rawJid = payload.jid
      const text = String(payload.text || '')
      const imagePath = payload.image ? String(payload.image) : ''
      if (!rawJid) throw new Error('send: jid required')
      if (!text.trim() && !imagePath) throw new Error('send: empty message')
      if (imagePath && !existsSync(imagePath)) throw new Error(`send: image file not found: ${imagePath}`)
      if (!sock || connection !== 'open') throw new Error('send: not connected to WhatsApp')

      const targetJid = store.resolveDeliveryJid(rawJid) || rawJid
      const canonical = store.canonicalJid(targetJid) || store.canonicalJid(rawJid) || rawJid
      const isGroup = isGroupJid(targetJid) || isGroupJid(rawJid)
      const options = {}
      let quotedMsgObj = null
      if (payload.quoted) {
        const quoted = store.findMessage(canonical, payload.quoted)
          || store.findMessage(targetJid, payload.quoted)
          || store.findMessage(rawJid, payload.quoted)
        if (quoted) {
          const quotedKey = {
            remoteJid: targetJid,
            id: quoted.key?.id || quoted.id,
            fromMe: !!quoted.fromMe,
            participant: isGroup ? (quoted.key?.participant || quoted.senderJid || undefined) : undefined
          }
          const content = messageCache.get(quoted.id) || storedToWaContent(quoted) || { conversation: quoted.text || '' }
          options.quoted = { key: quotedKey, message: content }
          quotedMsgObj = quoted
        }
      }

      const waContent = imagePath
        ? {
            image: { url: imagePath },
            caption: text || undefined
          }
        : { text }

      const sent = await sock.sendMessage(targetJid, waContent, options)
      if (sent) {
        if (sent.key?.id && sent.message) {
          cacheMessage(sent.key.id, sent.message)
        }
        if (imagePath && sent.key?.id) {
          const ext = extname(imagePath).toLowerCase()
          const mime = ext === '.png' ? 'image/png' : (ext === '.webp' ? 'image/webp' : (ext === '.gif' ? 'image/gif' : 'image/jpeg'))
          const cachedTarget = mediaPathFor(sent.key.id, mime)
          try {
            copyFileSync(imagePath, cachedTarget)
          } catch (err) {
            logger.warn({ err, imagePath }, 'media: failed to cache sent image')
          }
        }

        // generateWAMessage stamps PENDING. relayMessage has already succeeded
        // here, so the server has the stanza — show a single tick immediately.
        if (asStatus(sent.status) < MSG_SERVER_ACK) sent.status = MSG_SERVER_ACK
        const res = ingest(targetJid, sent)
        if (res) {
          const { message, canonicalTarget } = res
          if (imagePath && !message.imagePath) {
            const ext = extname(imagePath).toLowerCase()
            const mime = ext === '.png' ? 'image/png' : (ext === '.webp' ? 'image/webp' : (ext === '.gif' ? 'image/gif' : 'image/jpeg'))
            const cachedTarget = mediaPathFor(sent.key.id, mime)
            if (existsSync(cachedTarget)) message.imagePath = cachedTarget
            else message.imagePath = imagePath
            store.upsertMessage(canonicalTarget, message)
          }
          if (quotedMsgObj && !message.quoted) {
            message.quoted = {
              id: quotedMsgObj.id,
              fromMe: !!quotedMsgObj.fromMe,
              senderName: quotedMsgObj.fromMe ? 'You' : (quotedMsgObj.senderName || 'Message'),
              senderJid: quotedMsgObj.senderJid || '',
              text: quotedMsgObj.text || ''
            }
            store.upsertMessage(canonicalTarget, message)
          }
          if ((message.status || 0) < MSG_SERVER_ACK) {
            message.status = MSG_SERVER_ACK
            store.upsertMessage(canonicalTarget, message)
          }
          bus.broadcast({ t: 'message', jid: rawJid, message: publicMessage(message), chat: store.chat(canonicalTarget), unread: store.totalUnread() })
          if (rawJid !== canonicalTarget) {
            bus.broadcast({ t: 'message', jid: canonicalTarget, message: publicMessage(message), chat: store.chat(canonicalTarget), unread: store.totalUnread() })
          }
          if (targetJid !== rawJid && targetJid !== canonicalTarget) {
            bus.broadcast({ t: 'message', jid: targetJid, message: publicMessage(message), chat: store.chat(canonicalTarget), unread: store.totalUnread() })
          }
          applyMessageStatus(canonicalTarget, message.id, MSG_SERVER_ACK)
          pushChats()
        }
      }
      reply({ t: 'ack', id, ok: true, jid: rawJid })
      return
    }

    case 'read':
      if (!payload.jid) throw new Error('read: jid required')
      await markRead(payload.jid)
      reply({ t: 'ack', id, ok: true, jid: payload.jid })
      return

    case 'typing': {
      if (!payload.jid || !sock || connection !== 'open') {
        reply({ t: 'ack', id, ok: false })
        return
      }
      const presence = payload.state === 'paused' ? 'paused' : 'composing'
      try {
        await sock.sendPresenceUpdate(presence, payload.jid)
      } catch (err) {
        logger.debug({ err }, 'presence update failed')
      }
      reply({ t: 'ack', id, ok: true })
      return
    }

    // Notification clicks land here: the daemon is already the fan-out point to
    // every bar panel, so it tells them which chat to open.
    case 'focus':
      if (!payload.jid) throw new Error('focus: jid required')
      bus.broadcast({ t: 'focus', jid: payload.jid })
      reply({ t: 'ack', id, ok: true, jid: payload.jid })
      return

    case 'pair': {
      const phone = String(payload.phone || '').replace(/[^\d]/g, '')
      if (!phone) throw new Error('pair: phone number required')
      if (!sock) throw new Error('pair: socket not ready')
      const code = await sock.requestPairingCode(phone)
      reply({ t: 'pairCode', id, code })
      return
    }

    case 'login':
      if (isLinked() && connection === 'open') {
        reply({ t: 'ack', id, ok: true, already: true })
        return
      }
      reconnectAttempts = 0
      cancelReconnect()
      startPairing('user login')
      connecting = false
      await connect()
      reply({ t: 'ack', id, ok: true })
      return

    case 'reconnect':
      reconnectAttempts = 0
      cancelReconnect()
      if (!isLinked()) startPairing('manual reconnect')
      connecting = false
      await connect()
      reply({ t: 'ack', id, ok: true })
      return

        case 'repair': {
      if (!sock || connection !== 'open') throw new Error('repair: not connected to WhatsApp')
      if (repairInFlight) {
        reply({ t: 'ack', id, ok: false, message: 'repair already running' })
        return
      }
      const jid = payload.jid ? String(payload.jid) : ''
      repairInFlight = true
      {
        const removed = clearSignalSessions(jid)
        let rekeyed = 0
        try {
          rekeyed = await rekeyAllSessions(jid)
        } catch (err) {
          logger.warn({ err, jid }, 'repair: proactive re-key incomplete (next send to any contact still re-keys automatically)')
        }
        brokenSessions.clear()
        cryptoErrorCount = 0
        lastCryptoError = ''
        reply({ t: 'ack', id, ok: true, removed, rekeyed, reconnecting: true, targeted: !!jid, jid })
        setTimeout(async () => {
          repairInFlight = false
          if (stopping) return
          reconnectAttempts = 0
          cancelReconnect()
          connecting = false
          try {
            await connect()
          } catch (err) {
            logger.warn({ err }, 'repair: reconnect failed, will retry')
          }
        }, 300).unref?.()
        return
      }
    }

    case 'logout':
      try {
        await sock?.logout()
      } catch (err) {
        logger.debug({ err }, 'logout call failed, clearing local state anyway')
      }
      cancelReconnect()
      destroySocket('logout')
      wipeAuth()
      creds = null
      needsLogin = true
      pairingWanted = false
      pairingStopped = true
      connection = 'idle'
      connecting = false
      clearQr()
      pushState()
      pushChats()
      reply({ t: 'ack', id, ok: true })
      return

    default:
      reply({ t: 'error', for: String(t || ''), id, message: `unknown command: ${t}` })
  }
}

let closePluginStateWatch = () => {}

function shutdown(signal) {
  if (stopping) return
  stopping = true
  logger.info({ signal }, 'shutting down')
  cancelReconnect()
  closePluginStateWatch()
  for (const jid of [...muteExpiryTimers.keys()]) clearMuteExpiry(jid)
  notifier.cancelAll()
  store.persist()
  bus.close()
  destroySocket('shutdown')
  setTimeout(() => process.exit(0), 200).unref?.()
}

function stopWhenPluginIsDisabled() {
  if (stopping) return
  logger.info('plugin disabled; stopping the WhatsApp service')
  const stopper = spawn(
    'systemctl',
    ['--user', 'disable', '--now', 'omarchy-whatsapp.service'],
    { detached: true, stdio: 'ignore' }
  )
  stopper.unref()
  shutdown('plugin-disabled')
}

function startPluginStateWatch() {
  closePluginStateWatch = observePluginState(stopWhenPluginIsDisabled)
}

// A killed daemon leaves versioned QR images behind. They are useless to the
// next run and each one can link the account, so clear them at startup.
function purgeStaleQrFiles() {
  try {
    for (const name of readdirSync(stateDir)) {
      if (/^qr\.\d+\.png$/.test(name)) removeFile(join(stateDir, name))
    }
  } catch (err) {
    logger.debug({ err }, 'startup: could not purge stale QR files')
  }
}

function claimPid() {
  let displaced = false
  try {
    const old = Number(readFileSync(pidFile, 'utf8'))
    if (old && old !== process.pid) {
      try {
        process.kill(old, 0)
        logger.warn({ pid: old }, 'startup: stopping leftover daemon that would fight this session')
        process.kill(old, 'SIGTERM')
        displaced = true
      } catch {
        // Already gone.
      }
    }
  } catch {
    // No pid file yet.
  }
  writeFileSync(pidFile, String(process.pid), { mode: 0o600 })
  return displaced
}

async function main() {
  ensureDirs()
  startPluginStateWatch()
  if (stopping) return
  if (claimPid()) await sleep(1500)
  purgeStaleQrFiles()
  store.load()
  for (const chat of store.chats.values()) scheduleMuteExpiry(chat)

  media.getSocket = () => sock
  media.onReady = (jid, message) => {
    store.markDirty()
    bus.broadcast({ t: 'messageMedia', jid, id: message.id, imagePath: message.imagePath || '' })
  }

  bus.snapshot = snapshot
  bus.onCommand = handleCommand
  try {
    await bus.listen()
  } catch (err) {
    if (err.code === 'EALREADYRUNNING') {
      logger.error(err.message)
      process.exit(3)
    }
    throw err
  }

  try {
    const { state: authState } = await useMultiFileAuthState(authDir)
    creds = authState.creds
  } catch (err) {
    logger.warn({ err }, 'startup: could not read auth state')
  }

  needsLogin = !isLinked()
  pairingWanted = false
  pairingStopped = needsLogin
  connection = needsLogin ? 'idle' : 'connecting'
  pushState()

  // The window is otherwise only tested when the next QR arrives, and WhatsApp's
  // first ref lives for a minute, so the pause would land late.
  const pairingWatchdog = setInterval(() => {
    if (stopping || pairingStopped || !pairingWanted) return
    if (!needsLogin || connection === 'open') return
    if (pairingStartedAt === 0) return
    if (Date.now() - pairingStartedAt > PAIRING_WINDOW_MS) stopPairing()
  }, 5000)
  pairingWatchdog.unref?.()

  for (const signal of ['SIGINT', 'SIGTERM', 'SIGHUP']) process.on(signal, () => shutdown(signal))
  process.on('uncaughtException', (err) => logger.error({ err }, 'uncaught exception'))
  process.on('unhandledRejection', (err) => logger.error({ err }, 'unhandled rejection'))

  if (!needsLogin) await connect()
}

main().catch((err) => {
  logger.error({ err }, 'daemon failed to start')
  process.exit(1)
})
