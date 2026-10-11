// Turns the records emitted by scripts/keybinds into "which global shortcut
// opens this tile?" lookups. Pure functions; the QML side owns the process
// and passes the text in.
//
// Two indexes come out:
//   menuIndex:  menu item id  → pretty combo   ("Super+Ctrl+C" on Capture)
//   appIndex:   desktop id    → pretty combo   ("Super+Enter" on the terminal)
//
// Matching is deliberately best-effort. A tile with no hint is fine; a tile
// with a wrong hint teaches the wrong thing, so every rule below is exact
// rather than fuzzy.

.pragma library

function parseRecords(text) {
  var binds = []
  var defaults = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i]
    if (!line) continue
    var parts = line.split("\t")
    if (parts[0] === "bind") {
      var combo = String(parts[1] || "").trim()
      if (!combo) continue
      binds.push({
        combo: combo,
        pretty: prettyCombo(combo),
        description: String(parts[2] || "").trim(),
        dispatcher: String(parts[3] || "").trim(),
        arg: parts.slice(4).join("\t").trim()
      })
    } else if (parts[0] === "default") {
      defaults[String(parts[1] || "")] = String(parts[2] || "").trim()
    }
  }
  return { binds: binds, defaults: defaults }
}

// "SUPER SHIFT CTRL + SPACE" → "Super+Shift+Ctrl+Space"
var KEY_NAMES = {
  "RETURN": "Enter", "SPACE": "Space", "ESCAPE": "Esc", "BACKSPACE": "Bksp",
  "DELETE": "Del", "PRINT": "Print", "TAB": "Tab", "SLASH": "/", "PERIOD": ".",
  "COMMA": ",", "MINUS": "-", "EQUAL": "=", "GRAVE": "`", "UP": "↑", "DOWN": "↓",
  "LEFT": "←", "RIGHT": "→", "HOME": "Home", "END": "End", "INSERT": "Ins",
  "PAGE_UP": "PgUp", "PAGE_DOWN": "PgDn", "BRACKETLEFT": "[", "BRACKETRIGHT": "]",
  "SEMICOLON": ";", "APOSTROPHE": "'", "BACKSLASH": "\\"
}

function prettyKey(key) {
  var k = String(key || "").trim()
  var upper = k.toUpperCase()
  if (KEY_NAMES[upper]) return KEY_NAMES[upper]
  if (upper.indexOf("XF86") === 0) return k.substring(4)
  if (upper.length === 1) return upper
  // "F1", "F12" stay as they are; longer names get title case.
  if (/^F\d{1,2}$/.test(upper)) return upper
  return upper.charAt(0) + upper.substring(1).toLowerCase()
}

function prettyCombo(combo) {
  var s = String(combo || "").trim()
  var plus = s.lastIndexOf(" + ")
  var mods = plus >= 0 ? s.substring(0, plus) : ""
  var key = plus >= 0 ? s.substring(plus + 3) : s
  var out = []
  var modList = mods.split(/\s+/)
  for (var i = 0; i < modList.length; i++) {
    var m = modList[i].toUpperCase()
    if (!m) continue
    if (m === "SUPER") out.push("Super")
    else if (m === "SHIFT") out.push("Shift")
    else if (m === "CTRL" || m === "CONTROL") out.push("Ctrl")
    else if (m === "ALT") out.push("Alt")
    else out.push(m)
  }
  out.push(prettyKey(key))
  return out.join("+")
}

// Lower is preferred. Media/power keys (XF86*) are real shortcuts but not
// ones to teach when a Super combo opens the same thing, so they rank last.
function modCount(combo) {
  var s = String(combo || "")
  var plus = s.lastIndexOf(" + ")
  var key = plus < 0 ? s : s.substring(plus + 3)
  if (key.toUpperCase().indexOf("XF86") === 0) return 99
  if (plus < 0) return 0
  return s.substring(0, plus).split(/\s+/).filter(function(x) { return x }).length
}

// Commands that mean the same thing on either side of a comparison.
function normalizeCommand(cmd) {
  var s = String(cmd || "").trim().replace(/\s+/g, " ")
  s = s.replace(/^uwsm-app -- /, "").replace(/^uwsm app -- /, "")
  s = s.replace(/^\$OMARCHY_PATH\/bin\//, "").replace(/^\/usr\/share\/omarchy\/bin\//, "")
  s = s.replace(/^~\/\.local\/share\/omarchy\/bin\//, "")
  // The emoji menu item calls a wrapper; the keybind summons the plugin directly.
  if (s === "omarchy-menu-emoji") s = "omarchy-shell shell toggle omarchy.emojis"
  s = s.replace(/^omarchy-shell shell summon /, "omarchy-shell shell toggle ")
  return s
}

// Every `omarchy-menu toggle|summon <route>` (or `omarchy menu ...`) inside a
// bind's exec string. A bind like `stop-recording || omarchy-menu toggle x`
// still yields `x`.
function menuRoutesIn(arg) {
  var routes = []
  var re = /omarchy(?:-menu|\s+menu)\s+(?:toggle|summon)(?:\s+([A-Za-z0-9_.\-]+))?/g
  var m
  while ((m = re.exec(String(arg || ""))) !== null) routes.push(m[1] || "root")
  return routes
}

// Prefer the bind with the fewest modifiers when several open the same thing;
// the records are already priority-sorted, so ties keep the first one.
function assign(index, key, bind) {
  if (!key) return
  var current = index[key]
  if (!current || modCount(bind.combo) < current.mods) index[key] = { pretty: bind.pretty, mods: modCount(bind.combo) }
}

function flatten(index) {
  var out = {}
  for (var k in index) out[k] = index[k].pretty
  return out
}

// items / itemOrder: the merged menu model. resolveRoute(route) → item id.
function menuIndex(items, itemOrder, binds, resolveRoute) {
  var index = {}
  var actionToId = {}
  for (var o = 0; o < itemOrder.length; o++) {
    var entry = items[itemOrder[o]]
    if (!entry || !entry.action || entry.kind === "app") continue
    var key = normalizeCommand(entry.action)
    if (!actionToId[key]) actionToId[key] = entry.id
  }

  for (var i = 0; i < binds.length; i++) {
    var bind = binds[i]
    if (bind.dispatcher !== "exec" || !bind.arg) continue

    var routes = menuRoutesIn(bind.arg)
    for (var r = 0; r < routes.length; r++) {
      if (routes[r] === "root") continue
      var id = resolveRoute(routes[r])
      var target = items[id]
      if (!target) continue
      if (target.kind === "link" && target.target && items[target.target]) id = target.target
      assign(index, id, bind)
    }
    if (routes.length) continue

    var exact = actionToId[normalizeCommand(bind.arg)]
    if (exact) assign(index, exact, bind)
  }
  return flatten(index)
}

function lastSegment(desktopId) {
  var s = String(desktopId || "").toLowerCase()
  if (s.slice(-8) === ".desktop") s = s.slice(0, -8)
  var dot = s.lastIndexOf(".")
  return dot >= 0 ? s.substring(dot + 1) : s
}

function quotedTokens(arg) {
  var out = []
  var re = /'([^']+)'|"([^"]+)"/g
  var m
  while ((m = re.exec(String(arg || ""))) !== null) out.push(m[1] || m[2])
  return out
}

function stripUrl(url) {
  return String(url || "").toLowerCase().replace(/\/+$/, "")
}

// Names a bind's exec target as the user would recognize it. Returns a list
// of {type, value} probes tried in order against every desktop entry.
function appProbes(bind, defaults) {
  var arg = normalizeCommand(bind.arg)
  var probes = []
  var m

  // omarchy-launch-terminal / -browser / -editor go through the configured
  // default; show the shortcut on whatever that currently is.
  if ((m = arg.match(/^omarchy-launch-(terminal|browser|editor)(\s|$)/))) {
    if (arg.indexOf("--private") >= 0 || /^omarchy-launch-terminal-/.test(arg)) return []
    var value = defaults[m[1]]
    if (value) probes.push({ type: "exec", value: value.toLowerCase() })
    return probes
  }
  if ((m = arg.match(/^omarchy-launch-(?:or-focus-)?(tui|webapp)\s/))) {
    var tokens = quotedTokens(arg)
    for (var t = 0; t < tokens.length; t++) {
      if (/^https?:\/\//i.test(tokens[t])) probes.push({ type: "url", value: stripUrl(tokens[t]) })
      else probes.push({ type: "exec", value: tokens[t].toLowerCase() })
    }
    return probes
  }
  if ((m = arg.match(/^omarchy-launch-or-focus\s/))) {
    var toks = quotedTokens(arg)
    // '^obsidian$' 'uwsm-app -- obsidian' → the command's binary name
    for (var q = toks.length - 1; q >= 0; q--) {
      var cmd = normalizeCommand(toks[q]).split(" ")[0]
      if (cmd && cmd.charAt(0) !== "^") { probes.push({ type: "exec", value: cmd.toLowerCase() }); break }
    }
    return probes
  }
  if ((m = arg.match(/^omarchy-launch-([a-z0-9-]+)$/))) {
    probes.push({ type: "name", value: m[1].toLowerCase() })
    probes.push({ type: "id", value: m[1].toLowerCase() })
    return probes
  }
  if (arg.indexOf("omarchy-") === 0 || arg.indexOf("hyprctl") === 0) return []
  if (arg.indexOf("|") >= 0 || arg.indexOf("&&") >= 0) return []
  // Plain `some-app --flag` binds: the binary name.
  var bin = arg.split(" ")[0]
  if (bin && /^[a-z0-9._-]+$/i.test(bin)) probes.push({ type: "exec", value: bin.toLowerCase() })
  return probes
}

function execBinary(execString) {
  var s = String(execString || "").trim()
  // Skip env assignments and wrappers to reach the program being run.
  var parts = s.split(/\s+/)
  for (var i = 0; i < parts.length; i++) {
    var p = parts[i].replace(/^"|"$/g, "")
    if (!p || p.indexOf("=") > 0 && p.indexOf("/") < 0) continue
    if (p === "env" || p === "uwsm-app" || p === "--" || p === "uwsm") continue
    var slash = p.lastIndexOf("/")
    return (slash >= 0 ? p.substring(slash + 1) : p).toLowerCase()
  }
  return ""
}

function entryMatches(entry, probe) {
  var id = String(entry.id || "").toLowerCase()
  var name = String(entry.name || "").toLowerCase()
  var exec = String(entry.execString || "").toLowerCase()
  if (probe.type === "url") {
    var urls = exec.match(/https?:\/\/[^\s'"]+/g) || []
    for (var u = 0; u < urls.length; u++) if (stripUrl(urls[u]) === probe.value) return true
    return false
  }
  if (probe.type === "exec") {
    if (execBinary(exec) === probe.value) return true
    if (lastSegment(id) === probe.value || id === probe.value) return true
    // TUI entries wrap the program: `... -e btop` / `omarchy-launch-tui 'btop'`
    var words = exec.replace(/['"]/g, " ").split(/\s+/)
    for (var w = 0; w < words.length; w++) if (words[w] === probe.value) return true
    return false
  }
  if (probe.type === "id") return lastSegment(id) === probe.value || id === probe.value
  if (probe.type === "name") return name === probe.value || name.replace(/\s+/g, "") === probe.value
  return false
}

// entries: array of DesktopEntry-like objects {id, name, execString}.
function appIndex(entries, binds, defaults) {
  var index = {}
  var byName = {}
  for (var e = 0; e < entries.length; e++) {
    var n = String(entries[e].name || "").toLowerCase()
    if (n && !byName[n]) byName[n] = entries[e]
  }

  for (var i = 0; i < binds.length; i++) {
    var bind = binds[i]
    if (bind.dispatcher !== "exec" || !bind.arg) continue
    if (menuRoutesIn(bind.arg).length) continue

    var probes = appProbes(bind, defaults || {})
    var matched = null
    for (var p = 0; p < probes.length && !matched; p++) {
      for (var k = 0; k < entries.length; k++) {
        if (entryMatches(entries[k], probes[p])) { matched = entries[k]; break }
      }
    }
    // Last resort: the bind's own description is the app's name ("Signal").
    if (!matched && bind.description) {
      var candidate = byName[bind.description.toLowerCase()]
      if (candidate && probes.length) matched = candidate
    }
    if (matched) assign(index, String(matched.id || ""), bind)
  }
  return flatten(index)
}

// A random "did you know" for the footer, drawn from the top of the
// priority-sorted records so it is something worth learning.
function randomTip(binds, exclude) {
  var pool = []
  var limit = Math.min(binds.length, 60)
  for (var i = 0; i < limit; i++) {
    var b = binds[i]
    if (!b.description) continue
    if (/workspace|^Volume|^Brightness|^Mute/i.test(b.description)) continue
    if (exclude && exclude[b.combo]) continue
    pool.push(b)
  }
  if (!pool.length) return null
  return pool[Math.floor(Math.random() * pool.length)]
}
