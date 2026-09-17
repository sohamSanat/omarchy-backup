import assert from 'node:assert/strict'
import test from 'node:test'

import { extractQuotedInfo, extractContextInfo, messageText } from '../lib/message.js'

test('extractQuotedInfo extracts stanzaId and quoted text from extendedTextMessage', () => {
  const msg = {
    extendedTextMessage: {
      text: 'This is my reply',
      contextInfo: {
        stanzaId: 'MSG-12345',
        participant: '919876543210@s.whatsapp.net',
        quotedMessage: {
          conversation: 'Original message text'
        }
      }
    }
  }

  const ci = extractContextInfo(msg)
  assert.ok(ci)
  assert.equal(ci.stanzaId, 'MSG-12345')
  assert.equal(ci.participant, '919876543210@s.whatsapp.net')

  const quoted = extractQuotedInfo(msg)
  assert.ok(quoted)
  assert.equal(quoted.id, 'MSG-12345')
  assert.equal(quoted.participant, '919876543210@s.whatsapp.net')
  assert.equal(messageText(quoted.quotedMessage), 'Original message text')
})

test('extractQuotedInfo handles imageMessage with contextInfo', () => {
  const msg = {
    imageMessage: {
      caption: 'Look at this photo',
      contextInfo: {
        stanzaId: 'MSG-67890',
        participant: '123456789@s.whatsapp.net',
        quotedMessage: {
          conversation: 'What is that?'
        }
      }
    }
  }

  const quoted = extractQuotedInfo(msg)
  assert.ok(quoted)
  assert.equal(quoted.id, 'MSG-67890')
  assert.equal(quoted.participant, '123456789@s.whatsapp.net')
  assert.equal(messageText(quoted.quotedMessage), 'What is that?')
})

test('extractQuotedInfo returns null when no contextInfo exists', () => {
  const msg = {
    conversation: 'Plain text without reply'
  }

  const quoted = extractQuotedInfo(msg)
  assert.equal(quoted, null)
})
