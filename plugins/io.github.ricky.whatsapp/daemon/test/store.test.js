import assert from 'node:assert/strict'
import test from 'node:test'

import { Store } from '../lib/store.js'

test('unread total excludes muted and archived chats but includes expired mutes', () => {
  const store = new Store()

  store.setUnread('active@s.whatsapp.net', 2)

  const muted = store.setUnread('muted@s.whatsapp.net', 4)
  muted.muteEndTime = -1
  muted.muted = true

  const archived = store.setUnread('archived@s.whatsapp.net', 8)
  archived.archived = true

  const expired = store.setUnread('expired@s.whatsapp.net', 16)
  expired.muteEndTime = 1
  expired.muted = true

  assert.equal(store.totalUnread(), 18)
})

test('alias merge preserves an active mute from the secondary chat', () => {
  const store = new Store()
  const lid = store.chat('123@lid')
  lid.muteEndTime = -1
  lid.muted = true

  store.alias('123@lid', '555@s.whatsapp.net')

  const canonical = store.chat('555@s.whatsapp.net')
  assert.equal(canonical.muteEndTime, -1)
  assert.equal(canonical.muted, true)
})

test('alias merge prefers Always mute over a shorter primary timed mute', () => {
  const store = new Store()
  const phone = store.chat('555@s.whatsapp.net')
  phone.muteEndTime = Math.floor(Date.now() / 1000) + 60
  phone.muted = true

  const lid = store.chat('123@lid')
  lid.muteEndTime = -1
  lid.muted = true

  store.alias('123@lid', '555@s.whatsapp.net')

  const canonical = store.chat('555@s.whatsapp.net')
  assert.equal(canonical.muteEndTime, -1)
  assert.equal(canonical.muted, true)
})

test('resolveDeliveryJid correctly prioritizes LID for modern WhatsApp 1:1 threads', () => {
  const store = new Store()

  // 1. Group JID returns group directly
  assert.equal(store.resolveDeliveryJid('120363020983435052@g.us'), '120363020983435052@g.us')

  // 2. Explicit LID returns LID directly
  assert.equal(store.resolveDeliveryJid('114327851900986@lid'), '114327851900986@lid')

  // 3. Regular phone number without LID alias or LID messages returns PN
  assert.equal(store.resolveDeliveryJid('918250701183@s.whatsapp.net'), '918250701183@s.whatsapp.net')

  // 4. Phone number with LID alias returns LID
  store.alias('919046173654@s.whatsapp.net', '114327851900986@lid')
  assert.equal(store.resolveDeliveryJid('919046173654@s.whatsapp.net'), '114327851900986@lid')

  // 5. Phone number whose chat has messages with LID remoteJid returns LID
  const store2 = new Store()
  store2.upsertMessage('919999999999@s.whatsapp.net', {
    id: 'MSG1',
    ts: 1000,
    text: 'hello',
    key: { remoteJid: '222333444@lid', id: 'MSG1', fromMe: false }
  })
  assert.equal(store2.resolveDeliveryJid('919999999999@s.whatsapp.net'), '222333444@lid')
})
