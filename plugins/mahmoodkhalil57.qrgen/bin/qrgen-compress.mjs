// Compress a link with ha.mr, and report every way it could be done.
//
// This is a separate process, and the only part of the plugin that needs a
// JavaScript runtime, for one reason: ha.mr's compressor is arbitrary-precision
// arithmetic built on BigInt, and QML's engine has no BigInt. Everything else —
// the QR code itself — runs inside the shell.
//
// One call returns all the candidates rather than one, so deciding between them
// (see the panel's automatic compression) costs one process, not six.
//
//   qrgen-compress --link <url> [--site-root <url>] [--targets hamr,site]
//
// Output: {"ok":true,"candidates":[{target,emoji,qrText,alphanumeric,shareURL,payload}]}
//         {"ok":false,"error":"..."}

import { compress } from "../vendor/hamr/compress.js";
import { outputAlphabetASCII, outputAlphabetQR, outputAlphabetEmoji } from "../vendor/hamr/alphabets.js";

const argv = process.argv.slice(2);
const flag = (name, fallback = "") => {
  const at = argv.indexOf(name);
  return at === -1 ? fallback : (argv[at + 1] ?? fallback);
};

const fail = (message) => {
  process.stdout.write(JSON.stringify({ ok: false, error: message }) + "\n");
  process.exit(0); // a link that cannot be compressed is an answer, not a crash
};

const link = flag("--link");
if (!link) fail("Nothing to compress");

// Where a site-hosted redirect would point. Empty means the site target is not
// offered at all — which is the default, because a plugin should not quietly
// route other people's links through somebody's personal domain.
const siteRoot = flag("--site-root");

/**
 * The same validation ha.mr's own front end does. A bare "example.com" is
 * accepted; anything that is not http(s) is not.
 */
function validate (input) {
  const hasProtocol = /^\w+:\/\//.test(input);
  let url;
  try {
    url = new URL(hasProtocol ? input : "http://" + input);
  } catch {
    throw new Error("That does not look like a valid link");
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new Error(`Only http and https links can be compressed, not ${url.protocol.replace(":", "")}`);
  }
  if (url.username || url.password) {
    throw new Error("Links with credentials in them cannot be compressed");
  }
  return url;
}

try {
  validate(link);
} catch (error) {
  fail(error.message);
}

// Three alphabets, three trade-offs — the reasoning is ha.mr's and qrgen's, and
// is worth repeating where the choice is made:
//
// QR    - the most characters, but every one of them sits in QR's alphanumeric
//         mode at 5.5 bits, which makes the smallest code.
// ASCII - about 15% fewer characters at 8 bits each. For links people read.
// Emoji - by far the fewest symbols, but a symbol averages 11 UTF-8 bytes and a
//         QR code is charged by the byte. A way to make a link look short, not
//         a way to make a code small.
let qrPayload, asciiPayload, emojiPayload;
try {
  qrPayload = compress(link, outputAlphabetQR);
  asciiPayload = compress(link, outputAlphabetASCII);
  emojiPayload = compress(link, outputAlphabetEmoji);
} catch (error) {
  fail(error instanceof Error ? error.message : "Could not compress the link");
}

const candidates = [];

const wanted = flag("--targets", "hamr").split(",").map((t) => t.trim()).filter(Boolean);

if (wanted.includes("hamr")) {
  // Upper case throughout so the whole URL — prefix included — stays in QR's
  // alphanumeric mode. That, plus a 13-character prefix, is why it is by far
  // the smallest option.
  candidates.push({
    target: "hamr", emoji: false,
    qrText: `HTTP://HA.MR/${qrPayload}`,
    alphanumeric: true,
    shareURL: `http://ha.mr#${asciiPayload}`,
    payload: qrPayload
  });
  // Emoji never goes in a path — it would be percent-encoded into something
  // enormous — so it takes the fragment, and the QR and share links coincide.
  candidates.push({
    target: "hamr", emoji: true,
    qrText: `http://ha.mr#${emojiPayload}`,
    alphanumeric: false,
    shareURL: `http://ha.mr#${emojiPayload}`,
    payload: emojiPayload
  });
}

if (wanted.includes("site") && siteRoot) {
  try {
    const root = new URL(siteRoot);
    // http:// rather than https:// saves a character; hosts that care upgrade it.
    const prefix = `http://${root.host}${root.pathname}r/`;
    candidates.push({
      target: "site", emoji: false,
      qrText: `${prefix}${qrPayload}`,
      alphanumeric: false,
      shareURL: `${root.href}r/#${asciiPayload}`,
      payload: qrPayload
    });
    candidates.push({
      target: "site", emoji: true,
      qrText: `${root.href}r/#${emojiPayload}`,
      alphanumeric: false,
      shareURL: `${root.href}r/#${emojiPayload}`,
      payload: emojiPayload
    });
  } catch {
    // A site root that will not parse simply does not become a candidate.
  }
}

if (candidates.length === 0) fail("No redirect target is configured");

process.stdout.write(JSON.stringify({ ok: true, candidates }) + "\n");
