-- Scratchpad Deck keybindings.
--
-- Append this whole block to ~/.config/hypr/bindings.lua, then reload with
--   omarchy restart hyprland
--
-- It is a snippet rather than a standalone file on purpose: Omarchy loads
-- exactly one user bindings file (`require("hypr.bindings")`), after its own
-- defaults. That ordering is what lets the unbinds below replace stock
-- bindings. Dropping a new .lua into ~/.config/hypr/ does nothing unless you
-- also require it from hyprland.lua.
--
-- The BEGIN/END markers exist so this block can be found and removed again.

-- BEGIN tiertek.scratchpad-deck
local deck = os.getenv("HOME") .. "/.config/omarchy/plugins/tiertek.scratchpad-deck/bin/scratchpad-deck"

-- Omarchy binds Super+S to its single `special:scratchpad`, which the deck
-- deliberately ignores — it only tracks the numbered special:scratch-1..9.
-- Leaving the stock bindings in place is the worst of both worlds: Super+Alt+S
-- would stash windows somewhere the deck cannot show you. So replace both.
--
-- Delete these two unbind/bind pairs if you would rather keep Omarchy's
-- scratchpad on Super+S; the numbered bindings below work either way.
hl.unbind("SUPER + S")
o.bind("SUPER + S", "Open scratchpad deck", deck .. " toggle")

hl.unbind("SUPER + ALT + S")
o.bind("SUPER + ALT + S", "Send window to scratchpad 1", deck .. " send 1")

-- Jump straight to one scratchpad; the same key again hides it.
--
-- code:10..18 are the number keys 1..9, matched by position rather than by
-- keysym so these still land on the top-row numbers under a non-US layout.
-- Super+Ctrl+<number> is unclaimed in a stock Omarchy install: Super+<number>
-- switches workspaces and Super+Alt+<number> selects windows within a group.
for index = 1, 9 do
  o.bind(
    "SUPER + CTRL + code:" .. tostring(index + 9),
    "Show scratchpad " .. index,
    deck .. " slot " .. index
  )
end

-- Stash the focused window into a specific scratchpad, without following it.
for index = 1, 9 do
  o.bind(
    "SUPER + CTRL + ALT + code:" .. tostring(index + 9),
    "Send window to scratchpad " .. index,
    deck .. " send " .. index
  )
end

-- Flip through the scratchpads that actually have something in them.
o.bind("SUPER + CTRL + SLASH", "Next scratchpad", deck .. " next")
-- END tiertek.scratchpad-deck
