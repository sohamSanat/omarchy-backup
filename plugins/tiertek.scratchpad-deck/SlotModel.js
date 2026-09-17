// SlotModel.js — turns Hyprland's live workspace list into the deck's slots.
//
// Pure functions: no QML, no I/O. Everything about *what a slot is* lives here
// so it can be unit tested (tests/test-slot-model.cjs) rather than by opening
// the panel and squinting at it.
//
// A slot is a Hyprland special workspace named `special:scratch-N`. Hyprland
// creates those on demand and destroys them the moment their last window
// closes, so a slot's identity cannot live in the compositor — the declared
// list below is what makes slot 3 still mean "Music" when nothing is running.

var WORKSPACE_PREFIX = "special:scratch-";
var MIN_SLOT = 1;
var MAX_SLOT = 9;

// Array.isArray is not enough here. Values that reach this model from the QML
// side are not always real JS arrays: a list read out of shell.json arrives as
// a QVariantList, which is array-LIKE (indexable, has .length) but fails
// Array.isArray. Guarding with Array.isArray alone silently threw away every
// declared slot while the unit tests — which only ever pass real arrays —
// stayed green. Normalize to a real array once, here, and let the rest of the
// model assume it got one.
function toArray(value) {
  if (value === null || value === undefined) return [];
  if (Array.isArray(value)) return value;
  if (typeof value === "string") return [];
  var n = value.length;
  if (typeof n !== "number" || n < 0 || n !== Math.floor(n)) return [];
  var out = [];
  for (var i = 0; i < n; i++) out.push(value[i]);
  return out;
}

// `special:scratch-3` -> 3.
// Omarchy's built-in scratchpad is `special:scratchpad` (or `special:scratch`, `special:special`, `special`).
// Map built-in scratchpads to slot 1 so any stashed window appears in the deck's first card.
function slotNumberFromWorkspace(name) {
  var text = String(name || "");
  if (text === "special:scratchpad" || text === "special:scratch" || text === "special:special" || text === "special") return 1;
  if (text.indexOf(WORKSPACE_PREFIX) !== 0) return 0;
  var tail = text.slice(WORKSPACE_PREFIX.length);
  if (!/^[0-9]+$/.test(tail)) return 0;
  var n = parseInt(tail, 10);
  return n >= MIN_SLOT && n <= MAX_SLOT ? n : 0;
}

function workspaceForSlot(n) {
  return WORKSPACE_PREFIX + String(n);
}

// Hyprland reports the app id as `class`; a missing class must not become the
// string "undefined". `toplevel` is carried through untouched: the deck needs
// the live Quickshell object to point a ScreencopyView at, and this model has
// no business inspecting it (which is also what keeps it testable under node,
// where no such object exists).
function normalizeWindow(win) {
  var w = win || {};
  return {
    address: String(w.address || ""),
    title: String(w.title || ""),
    appId: String(w.appId || w["class"] || ""),
    toplevel: w.toplevel || null
  };
}

function isValidSlot(n) {
  var v = Number(n);
  return isFinite(v) && v >= MIN_SLOT && v <= MAX_SLOT && v === Math.floor(v);
}

// Declared slots come from the user's shell.json widget entry. Anything
// malformed is dropped rather than rendered as a broken card — a typo in a
// config file should cost you that one slot, not the whole deck.
function normalizeDeclared(rows) {
  var out = {};
  var list = toArray(rows);
  for (var i = 0; i < list.length; i++) {
    var row = list[i] || {};
    var n = Number(row.slot);
    if (!isValidSlot(n)) continue;
    // First declaration of a slot wins, so a duplicated entry cannot make the
    // deck's contents depend on array order.
    if (out[n]) continue;
    out[n] = {
      n: n,
      name: String(row.name || ""),
      command: String(row.command || "")
    };
  }
  return out;
}

// occupancy: [{ name: "special:scratch-2", windows: [ ... ] }, ...]
// declared:  [{ slot: 2, name: "Notes", command: "obsidian" }, ...]
//
// Returns every slot worth drawing, ascending. A slot earns a card by holding
// windows or by being declared; an undeclared empty slot is just a workspace
// that does not exist, and drawing nine of those would bury the two the user
// actually uses.
function buildSlots(occupancy, declared) {
  var byNumber = {};
  var workspaceNameByNumber = {};
  var decl = normalizeDeclared(declared);

  var rows = toArray(occupancy);
  for (var i = 0; i < rows.length; i++) {
    var row = rows[i] || {};
    var n = slotNumberFromWorkspace(row.name);
    if (n === 0) continue;
    var windows = [];
    var raw = toArray(row.windows);
    for (var j = 0; j < raw.length; j++) windows.push(normalizeWindow(raw[j]));
    byNumber[n] = (byNumber[n] || []).concat(windows);
    if (!workspaceNameByNumber[n] && row.name && windows.length > 0) {
      workspaceNameByNumber[n] = String(row.name);
    }
  }

  var numbers = {};
  var key;
  for (key in byNumber) if (byNumber[key].length > 0) numbers[key] = true;
  for (key in decl) numbers[key] = true;

  var slots = [];
  for (key in numbers) {
    var num = Number(key);
    var windows2 = byNumber[num] || [];
    var d = decl[num] || null;
    var ws = workspaceNameByNumber[num] || workspaceForSlot(num);
    slots.push({
      n: num,
      workspace: ws,
      windows: windows2,
      count: windows2.length,
      occupied: windows2.length > 0,
      declared: !!d,
      command: d ? d.command : "",
      // A running window's own title beats the configured name: the label is
      // there to tell two scratchpads apart, and "Notes" is less useful than
      // the note you actually have open.
      name: windows2.length > 0
        ? (windows2[0].title || (d ? d.name : "") || windows2[0].appId || ("Slot " + num))
        : (d && d.name ? d.name : ("Slot " + num))
    });
  }

  slots.sort(function(a, b) { return a.n - b.n; });
  return slots;
}

// Which slot a bare toggle should land on. Prefer the one already showing (so
// the same key closes it), else the lowest occupied slot, else the lowest
// declared one — a first press on a cold machine should still start something.
function defaultSlot(slots, visibleWorkspace) {
  var list = toArray(slots);
  if (list.length === 0) return 0;
  var visible = slotNumberFromWorkspace(visibleWorkspace);
  for (var i = 0; i < list.length; i++) if (list[i].n === visible) return visible;
  for (i = 0; i < list.length; i++) if (list[i].occupied) return list[i].n;
  return list[0].n;
}

// Step to the next/previous slot with windows in it, wrapping. Empty declared
// slots are skipped: cycling is a "show me my other running scratchpad"
// gesture, and landing on a placeholder that launches an app would be a
// destructive surprise.
function cycleSlot(slots, currentWorkspace, direction) {
  var occupied = [];
  var list = toArray(slots);
  for (var i = 0; i < list.length; i++) if (list[i].occupied) occupied.push(list[i].n);
  if (occupied.length === 0) return 0;

  var current = slotNumberFromWorkspace(currentWorkspace);
  var at = occupied.indexOf(current);
  if (at < 0) return occupied[0];
  var step = direction < 0 ? -1 : 1;
  var next = (at + step + occupied.length) % occupied.length;
  return occupied[next];
}

if (typeof module !== "undefined") module.exports = {
  toArray: toArray,
  WORKSPACE_PREFIX: WORKSPACE_PREFIX,
  MIN_SLOT: MIN_SLOT,
  MAX_SLOT: MAX_SLOT,
  slotNumberFromWorkspace: slotNumberFromWorkspace,
  workspaceForSlot: workspaceForSlot,
  isValidSlot: isValidSlot,
  normalizeDeclared: normalizeDeclared,
  buildSlots: buildSlots,
  defaultSlot: defaultSlot,
  cycleSlot: cycleSlot
};
