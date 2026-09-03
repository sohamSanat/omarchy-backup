// Option handling and the automatic decisions.
//
// No drawing knowledge lives here — renderer.js holds the qrgen app's own
// generator, and this file decides what to hand it. It is pure JavaScript with
// no QML dependencies so the same functions can be exercised under node — which
// is why there is no `.pragma library` here: it would make the file unloadable
// outside QML, and these decisions are worth being able to test directly.

function colorToHex(c) {
  if (!c) return ""
  if (typeof c === "string") {
    var s = c.trim()
    if (/^#[0-9a-fA-F]{8}$/.test(s)) return ("#" + s.slice(3)).toLowerCase()
    return s.toLowerCase()
  }
  if (typeof c === "object" && c.r !== undefined) {
    var r = Math.round(c.r * 255).toString(16)
    var g = Math.round(c.g * 255).toString(16)
    var b = Math.round(c.b * 255).toString(16)
    if (r.length < 2) r = "0" + r
    if (g.length < 2) g = "0" + g
    if (b.length < 2) b = "0" + b
    return ("#" + r + g + b).toLowerCase()
  }
  var str = String(c).trim()
  if (/^#[0-9a-fA-F]{8}$/.test(str)) return ("#" + str.slice(3)).toLowerCase()
  return str.toLowerCase()
}

function defaults() {
  return {
    level: "M",
    margin: 4,
    body: "square",
    eyeFrame: "square",
    eyeBall: "square",
    foreground: "",
    background: "",
    transparentBackground: false,
    eyeFrameColour: "",
    eyeBallColour: "",
    assetPath: "",
    assetScale: 0.22,
    assetPadding: 0.6,
    assetClear: true,
    assetBackdrop: true,
    compress: false,
    compressTarget: "hamr",
    compressEmoji: false,
    // All three measured rather than guessed at. Compression is the one with a
    // consequence outside the code — it rewrites the link into a redirect
    // through ha.mr — so the panel always says when it has done so, and the
    // switch is right there to turn off.
    correctionAuto: true,
    marginAuto: true,
    compressAuto: false
  }
}

var LEVELS = ["L", "M", "Q", "H"]

function correctionLevels() {
  return [
    { value: "L", label: "L — 7%" },
    { value: "M", label: "M — 15%" },
    { value: "Q", label: "Q — 25%" },
    { value: "H", label: "H — 30%" }
  ]
}

function normalizedLevel(value, fallback) {
  var wanted = String(value || "").toUpperCase()
  for (var i = 0; i < LEVELS.length; i++) if (LEVELS[i] === wanted) return wanted
  return fallback || "M"
}

function clamp(value, low, high) {
  var number = Number(value)
  if (isNaN(number)) return low
  return Math.min(high, Math.max(low, number))
}

function modulesFor(version) { return version * 4 + 17 }

// Above version 6 a centre asset starts landing on the middle alignment
// pattern. That is structure rather than payload, so no amount of error
// correction puts it back and the code simply stops scanning. When there is an
// asset, staying under that line matters more than any other saving.
var ASSET_SAFE_VERSION = 6

// ---- the plan ------------------------------------------------------------
//
// One pass decides everything the renderer needs: which payload goes in, how
// much correction, how wide a quiet zone. Whatever is set to automatic is
// measured rather than guessed — a QR code's size is a step function of its
// payload, so the only way to know whether compression helps is to encode it
// both ways and compare.

function plan(state, candidates, versionOf) {
  var link = String(state.link || "").trim()
  if (link === "") return null

  var hasAsset = String(state.assetPath || "") !== ""
  var floor = hasAsset ? "Q" : "L"

  var plain = {
    compress: false, target: null, emoji: false,
    text: link, alphanumeric: false, shareURL: "", payload: ""
  }

  var available = (candidates && candidates.length) ? candidates.slice() : []
  var options = []

  if (state.compressAuto === true) {
    options.push(plain)
    options = options.concat(available)
  } else if (state.compress === true) {
    for (var i = 0; i < available.length; i++) {
      if (available[i].target === state.compressTarget
          && available[i].emoji === (state.compressEmoji === true)) options.push(available[i])
    }
    // Compression was asked for and the payload is not here yet (or could not
    // be made). Falling back to the plain link would quietly encode something
    // other than what the controls say.
    if (options.length === 0) return { pending: true }
  } else {
    options.push(plain)
  }

  for (var j = 0; j < options.length; j++) {
    options[j].version = versionOf(options[j].text, floor, options[j].alphanumeric)
  }
  options = options.filter(function(option) { return option.version > 0 })
  if (options.length === 0) return { pending: true }

  // Smaller wins; ties go to whatever depends on the least. A plain link needs
  // nothing to keep working, a redirect needs its redirector, and emoji needs
  // the reader to render it — so that is the order the preferences run in.
  options.sort(function(a, b) {
    if (hasAsset) {
      var aSafe = a.version <= ASSET_SAFE_VERSION ? 0 : 1
      var bSafe = b.version <= ASSET_SAFE_VERSION ? 0 : 1
      if (aSafe !== bSafe) return aSafe - bSafe
    }
    if (a.version !== b.version) return a.version - b.version
    if (a.compress !== b.compress) return a.compress ? 1 : -1
    if (a.emoji !== b.emoji) return a.emoji ? 1 : -1
    return (a.target === "hamr" ? 0 : 1) - (b.target === "hamr" ? 0 : 1)
  })

  var chosen = options[0]
  var plainOption = null
  for (var k = 0; k < options.length; k++) if (!options[k].compress) plainOption = options[k]

  // ---- correction
  var correction = normalizedLevel(state.level, "M")
  var correctionNote = ""
  if (state.correctionAuto === true) {
    var base = versionOf(chosen.text, floor, chosen.alphanumeric)
    correction = floor
    for (var level = LEVELS.length - 1; level > LEVELS.indexOf(floor); level--) {
      if (versionOf(chosen.text, LEVELS[level], chosen.alphanumeric) === base) {
        correction = LEVELS[level]
        break
      }
    }
    correctionNote = hasAsset && correction === floor
      ? "the least the centre asset can be read through"
      : correction === "H"
        ? "the most this code can carry"
        : "the strongest level that does not make the code bigger"
  }

  // ---- quiet zone
  var margin = Math.round(clamp(state.margin, 0, 16))
  var marginNote = ""
  if (state.marginAuto === true) {
    margin = 4
    marginNote = "the four modules the specification asks for"
  }

  // ---- compression
  var compressNote = ""
  if (state.compressAuto === true) {
    if (!chosen.compress) {
      compressNote = available.length > 0
        ? "off · compressing would not make a smaller code"
        : "off"
    } else if (plainOption && plainOption.version > chosen.version) {
      compressNote = modulesFor(chosen.version) + "×" + modulesFor(chosen.version)
        + " instead of " + modulesFor(plainOption.version) + "×" + modulesFor(plainOption.version)
      if (hasAsset && plainOption.version > ASSET_SAFE_VERSION && chosen.version <= ASSET_SAFE_VERSION) {
        compressNote += " · keeps the asset off the centre alignment pattern"
      }
    } else {
      compressNote = modulesFor(chosen.version) + "×" + modulesFor(chosen.version)
    }
  }

  return {
    pending: false,
    text: chosen.text,
    alphanumeric: chosen.alphanumeric === true,
    shareURL: chosen.shareURL || "",
    payload: chosen.payload || "",
    correction: correction,
    correctionNote: correctionNote,
    margin: margin,
    marginNote: marginNote,
    compress: chosen.compress === true,
    compressTarget: chosen.target,
    compressEmoji: chosen.emoji === true,
    compressNote: compressNote
  }
}

// What renderer.js takes. Mirrors qrgen's own QrOptions; the asset arrives
// already inlined, because reading a file is the panel's job and not this
// file's.
function renderOptions(state, resolved, assetDataUri) {
  return {
    correction: resolved.correction,
    margin: resolved.margin,
    shapes: {
      body: String(state.body || "square"),
      eyeFrame: String(state.eyeFrame || "square"),
      eyeBall: String(state.eyeBall || "square")
    },
    colors: {
      foreground: String(state.foreground || "#111827"),
      background: String(state.background || "#ffffff"),
      transparentBackground: state.transparentBackground === true,
      eyeFrame: String(state.eyeFrameColour || ""),
      eyeBall: String(state.eyeBallColour || "")
    },
    logo: {
      src: assetDataUri || null,
      name: "",
      scale: clamp(state.assetScale, 0.05, 0.4),
      padding: clamp(state.assetPadding, 0, 3),
      clear: state.assetClear === true,
      backdrop: state.assetBackdrop === true,
      radius: 0.15
    }
  }
}

// ---- captions ------------------------------------------------------------
//
// Each reads as a sentence rather than a value, because the interesting part is
// not what was chosen but why: a caption saying "L" is worse than no caption.

function levelLabel(value) {
  var levels = correctionLevels()
  for (var i = 0; i < levels.length; i++) if (levels[i].value === value) return levels[i].label
  return String(value || "")
}

function describeCorrection(resolved) {
  if (!resolved || !resolved.correction) return ""
  var text = levelLabel(resolved.correction)
  return resolved.correctionNote ? text + " · " + resolved.correctionNote : text
}

function describeMargin(resolved) {
  if (!resolved || resolved.margin === undefined || resolved.margin === null) return ""
  var count = Number(resolved.margin)
  var text = count + (count === 1 ? " module" : " modules")
  return resolved.marginNote ? text + " · " + resolved.marginNote : text
}

function describeCompression(resolved, targetLabel) {
  if (!resolved) return ""
  if (resolved.compress !== true) return resolved.compressNote || "off"
  var text = targetLabel || resolved.compressTarget || "compressed"
  if (resolved.compressEmoji === true) text += ", emoji"
  return resolved.compressNote ? text + " · " + resolved.compressNote : text
}

function describe(result, resolved) {
  if (!result || result.ok !== true) return ""
  var parts = ["version " + result.version, result.size + "×" + result.size]
  if (resolved && resolved.payload) parts.push(resolved.payload.length + " char payload")
  return parts.join(" · ")
}

if (typeof module !== "undefined") {
  module.exports = {
    defaults: defaults, correctionLevels: correctionLevels, normalizedLevel: normalizedLevel,
    clamp: clamp, plan: plan, renderOptions: renderOptions, describe: describe,
    describeCorrection: describeCorrection, describeMargin: describeMargin,
    describeCompression: describeCompression, colorToHex: colorToHex
  }
}
