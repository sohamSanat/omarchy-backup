const assert = require("node:assert/strict");
const M = require("../SlotModel.js");

let checks = 0;
const ok = (cond, msg) => { assert.ok(cond, msg); checks++; };
const eq = (a, b, msg) => { assert.deepEqual(a, b, msg); checks++; };

// ---------------------------------------------------------------- parsing

eq(M.slotNumberFromWorkspace("special:scratch-3"), 3, "parses a slot number");
eq(M.slotNumberFromWorkspace("special:scratch-9"), 9, "parses the last slot");
eq(M.slotNumberFromWorkspace("special:scratch-1"), 1, "parses the first slot");

// Omarchy's own Super+S uses `special:scratchpad`.
eq(M.slotNumberFromWorkspace("special:scratchpad"), 1, "maps Omarchy's built-in scratchpad to slot 1");
eq(M.slotNumberFromWorkspace("special:scratch"), 1, "maps special:scratch to slot 1");
eq(M.slotNumberFromWorkspace("special:special"), 1, "maps special:special to slot 1");
eq(M.slotNumberFromWorkspace("special"), 1, "maps special to slot 1");
eq(M.slotNumberFromWorkspace("special:scratch-0"), 0, "rejects slot 0");
eq(M.slotNumberFromWorkspace("special:scratch-10"), 0, "rejects out-of-range slots");
eq(M.slotNumberFromWorkspace("special:scratch-2x"), 0, "rejects non-numeric tails");
eq(M.slotNumberFromWorkspace("special:scratch-"), 0, "rejects an empty tail");
eq(M.slotNumberFromWorkspace("2"), 0, "rejects a bare number");
eq(M.slotNumberFromWorkspace(null), 0, "survives null");
eq(M.slotNumberFromWorkspace(undefined), 0, "survives undefined");

eq(M.workspaceForSlot(4), "special:scratch-4", "builds a workspace name");

// ---------------------------------------------------------------- declared

const decl = M.normalizeDeclared([
  { slot: 2, name: "Notes", command: "obsidian" },
  { slot: 99, name: "Nope", command: "bad" },      // out of range
  { slot: "x", name: "Nope", command: "bad" },     // not a number
  { slot: 2, name: "Duplicate", command: "other" } // first wins
]);
eq(Object.keys(decl).length, 1, "drops malformed declarations");
eq(decl[2].name, "Notes", "first declaration of a slot wins");

// A typo'd entry costs that slot, not the whole deck.
eq(M.normalizeDeclared(null), {}, "survives a null declared list");
eq(M.normalizeDeclared("nonsense"), {}, "survives a non-array declared list");

// --------------------------------------------------- array-like inputs
//
// Regression: a list read out of shell.json reaches the model as a
// QVariantList, which is indexable and has .length but fails Array.isArray.
// Guarding with Array.isArray alone silently dropped every declared slot in
// the real shell while these tests — which only passed real arrays — stayed
// green. Anything array-shaped has to work.
const arrayLike = (items) => {
  const o = { length: items.length };
  items.forEach((v, i) => { o[i] = v; });
  return o; // deliberately NOT an Array
};

ok(!Array.isArray(arrayLike([1, 2])), "the fixture really is not an Array");
eq(M.toArray(arrayLike(["a", "b"])), ["a", "b"], "converts an array-like to a real array");
eq(M.toArray(null), [], "toArray survives null");
eq(M.toArray("abc"), [], "a string is not a list of slots");
eq(M.toArray({ nope: 1 }), [], "an object with no length is not a list");
eq(M.toArray({ length: -1 }), [], "a negative length is not a list");
eq(M.toArray({ length: 1.5 }), [], "a fractional length is not a list");

const fromQml = M.normalizeDeclared(arrayLike([{ slot: 7, name: "Files", command: "nautilus" }]));
eq(fromQml[7].name, "Files", "declared slots survive arriving as a QVariantList");

let qmlSlots = M.buildSlots(
  arrayLike([{ name: "special:scratch-1", windows: arrayLike([{ address: "0x1", title: "kitty" }]) }]),
  arrayLike([{ slot: 7, name: "Files", command: "nautilus" }])
);
eq(qmlSlots.map(s => s.n), [1, 7], "buildSlots handles array-like occupancy and declarations");
eq(qmlSlots[0].count, 1, "array-like window lists are counted");
eq(M.defaultSlot(arrayLike(qmlSlots), ""), 1, "defaultSlot handles an array-like slot list");
eq(M.cycleSlot(arrayLike(qmlSlots), "", 1), 1, "cycleSlot handles an array-like slot list");

// ---------------------------------------------------------------- building

const occupancy = [
  { name: "special:scratch-1", windows: [{ address: "0x1", title: "kitty", class: "kitty" }] },
  { name: "special:scratch-3", windows: [
      { address: "0x2", title: "Spotify", class: "spotify" },
      { address: "0x3", title: "Extra", class: "spotify" }
  ] },
  { name: "special:scratchpad", windows: [{ address: "0x4", title: "builtin", class: "foo" }] }
];

let slots = M.buildSlots(occupancy, [{ slot: 5, name: "Music", command: "spotify" }]);
eq(slots.map(s => s.n), [1, 3, 5], "occupied and declared slots, ascending");
eq(slots[0].count, 2, "counts windows from both scratchpad workspaces");
eq(slots[1].count, 2, "counts multiple windows");
ok(slots[0].occupied, "slot with windows is occupied");
ok(!slots[2].occupied, "declared-but-empty slot is not occupied");
ok(slots[2].declared, "declared-but-empty slot is still drawn");
eq(slots[2].command, "spotify", "carries the launch command");
eq(slots[0].workspace, "special:scratch-1", "carries its workspace name");

const standaloneOccupancy = [
  { name: "special:scratchpad", windows: [{ address: "0x4", title: "builtin", class: "foo" }] }
];
let standaloneSlots = M.buildSlots(standaloneOccupancy, []);
eq(standaloneSlots.length, 1, "finds standalone Omarchy scratchpad");
eq(standaloneSlots[0].n, 1, "standalone scratchpad maps to slot 1");
eq(standaloneSlots[0].workspace, "special:scratchpad", "carries special:scratchpad workspace name");
eq(standaloneSlots[0].count, 1, "counts window in standalone scratchpad");

// Hyprland reports the app id as `class`; the model normalizes it.
eq(slots[0].windows[0].appId, "kitty", "maps class onto appId");

// The deck points a ScreencopyView at this object, so it has to survive the
// trip through the model untouched.
const marker = { iAm: "a live toplevel" };
const carried = M.buildSlots(
  [{ name: "special:scratch-1", windows: [{ address: "0x1", title: "t", toplevel: marker }] }], []
);
ok(carried[0].windows[0].toplevel === marker, "carries the live toplevel reference through");
eq(M.buildSlots([{ name: "special:scratch-1", windows: [{ address: "0x1" }] }], [])[0].windows[0].toplevel,
   null, "a window with no toplevel yields null, not undefined");

// A live window's title beats the configured name.
slots = M.buildSlots(
  [{ name: "special:scratch-2", windows: [{ address: "0x9", title: "todo.md", class: "obsidian" }] }],
  [{ slot: 2, name: "Notes", command: "obsidian" }]
);
eq(slots[0].name, "todo.md", "running title beats the declared name");

// An empty slot falls back to its declared name, then to a generic label.
slots = M.buildSlots([], [{ slot: 2, name: "Notes", command: "obsidian" }]);
eq(slots[0].name, "Notes", "empty declared slot uses its declared name");
slots = M.buildSlots([], [{ slot: 2, command: "obsidian" }]);
eq(slots[0].name, "Slot 2", "unnamed declared slot gets a generic label");

// An emptied workspace still exists in Hyprland for a moment; it must not
// leave a ghost card behind.
eq(M.buildSlots([{ name: "special:scratch-4", windows: [] }], []).length, 0,
   "an empty undeclared slot draws nothing");

eq(M.buildSlots(null, null), [], "survives null inputs");

// ---------------------------------------------------------------- default

slots = M.buildSlots(occupancy, [{ slot: 5, name: "Music", command: "spotify" }]);
eq(M.defaultSlot(slots, "special:scratch-3"), 3, "a visible slot is the default (so the key closes it)");
eq(M.defaultSlot(slots, ""), 1, "nothing visible falls to the lowest occupied slot");
eq(M.defaultSlot(M.buildSlots([], [{ slot: 7, command: "kitty" }]), ""), 7,
   "with nothing running, a declared slot is the default");
eq(M.defaultSlot([], ""), 0, "no slots at all yields no default");

// ---------------------------------------------------------------- cycling

eq(M.cycleSlot(slots, "special:scratch-1", 1), 3, "cycles forward past the declared-empty slot");
eq(M.cycleSlot(slots, "special:scratch-3", 1), 1, "cycles forward with wraparound");
eq(M.cycleSlot(slots, "special:scratch-1", -1), 3, "cycles backward with wraparound");
eq(M.cycleSlot(slots, "", 1), 1, "cycling from nowhere starts at the first occupied slot");
eq(M.cycleSlot(M.buildSlots([], [{ slot: 5, command: "x" }]), "", 1), 0,
   "cycling never lands on an empty slot and launches something");
eq(M.cycleSlot([], "", 1), 0, "cycling with no slots yields nothing");

console.log("test-slot-model: " + checks + " checks passed");
