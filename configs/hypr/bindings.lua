-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
o.bind("SUPER + H", "Toggle dictation", "omarchy-shell io.github.ef-code.omarchy-flow.service toggle")
o.bind("CTRL + H", "Toggle dictation", "omarchy-shell io.github.ef-code.omarchy-flow.service toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Use Strata instead of Nautilus for Omarchy's file-manager shortcuts.
hl.unbind("SUPER + SHIFT + F")
hl.unbind("SUPER + ALT + SHIFT + F")
o.bind("SUPER + SHIFT + F", "File manager", { launch = "strata" })
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", "uwsm-app -- strata \"$(omarchy-cmd-terminal-cwd)\"")
o.bind("SUPER + E", "File manager", { launch = "strata" })

-- HomeLab Launcher
o.bind("SUPER + Y", "HomeLab launcher", "omarchy-shell shell toggle io.github.elvis-christian.homelab-launcher")

-- YouTube Music (ytkew)
o.bind("SUPER + M", "YouTube Music", { tui = "ytkew", focus = true })

-- Dictionary
o.bind("SUPER + D", "Look up selection in dictionary", "omarchy-dictionary-lookup")


-- Workspace Switcher: begin
do
  local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
  local path = config_home .. "/omarchy/plugins/reomarchy.workspace-switcher/bindings.lua"
  local file = io.open(path, "r")
  if file then
    file:close()
    dofile(path)
  end
end
-- Workspace Switcher: end

-- ricardosuman.pretty-screenshot (begin)
hl.unbind("PRINT")
o.bind("PRINT", "Screenshot", "omarchy-pretty-screenshot")
-- ricardosuman.pretty-screenshot (end)

-- io.github.ellion369.omagent: begin
o.bind("ALT + SPACE", "Omagent overlay", "omarchy-shell shell toggle io.github.ellion369.omagent")
o.bind("SUPER + A", "Omagent overlay", "omarchy-shell shell toggle io.github.ellion369.omagent")
hl.layer_rule({ match = { namespace = "omarchy-omagent" }, blur = true, ignore_alpha = 0.6 })
-- io.github.ellion369.omagent: end

-- nguyenn.clipboard: begin (overrides built-in omarchy.clipboard)
hl.unbind("SUPER + CTRL + V")
o.bind("SUPER + CTRL + V", "Clipboard manager", "omarchy-shell shell toggle nguyenn.clipboard")
o.bind("SUPER + SHIFT + V", "Clipboard manager", "omarchy-shell shell toggle nguyenn.clipboard")
-- nguyenn.clipboard: end

-- reidenxerx.tile-blueprints: begin
o.bind("SUPER + ALT + L", "Tile blueprints", "omarchy-shell shell toggle reidenxerx.tile-blueprints '{}'")
-- reidenxerx.tile-blueprints: end

-- Laptop Lid Switch: clean suspend on close, reliable wake on open
hl.unbind("switch:on:Lid Switch")
o.bind("switch:on:Lid Switch", nil, "omarchy-system-lid-close", { locked = true })

hl.unbind("switch:off:Lid Switch")
o.bind("switch:off:Lid Switch", nil, "omarchy-system-lid-open", { locked = true })

-- tiertek.scratchpad-deck: begin
local deck = os.getenv("HOME") .. "/.config/omarchy/plugins/tiertek.scratchpad-deck/bin/scratchpad-deck"

-- Kept Omarchy's default scratchpad for SUPER + S (toggle) and SUPER + ALT + S (send window)

for index = 1, 9 do
  o.bind(
    "SUPER + CTRL + code:" .. tostring(index + 9),
    "Show scratchpad " .. index,
    deck .. " slot " .. index
  )
end

for index = 1, 9 do
  o.bind(
    "SUPER + CTRL + ALT + code:" .. tostring(index + 9),
    "Send window to scratchpad " .. index,
    deck .. " send " .. index
  )
end

o.bind("SUPER + CTRL + SLASH", "Next scratchpad", deck .. " next")
-- tiertek.scratchpad-deck: end

-- >>> omarchy-flow managed hotkeys >>>
-- Managed by Omarchy Flow. Configure these in the Flow settings menu.
hl.unbind("SUPER + ALT + V")
o.bind("SUPER + ALT + V", "Flow: Toggle dictation", "omarchy-shell io.github.ef-code.omarchy-flow.service toggle")
hl.unbind("SUPER + ALT + SHIFT + V")
o.bind("SUPER + ALT + SHIFT + V", "Flow: Dictate & submit", "omarchy-shell io.github.ef-code.omarchy-flow.service toggleSubmit")
hl.unbind("F6")
o.bind("F6", "Flow: Push to talk", "omarchy-shell io.github.ef-code.omarchy-flow.service start")
o.bind("F6", "Flow: Push to talk (release)", "omarchy-shell io.github.ef-code.omarchy-flow.service stop", { release = true })
hl.unbind("SUPER + ALT + P")
o.bind("SUPER + ALT + P", "Flow: Pause / resume", "omarchy-shell io.github.ef-code.omarchy-flow.service pause")
hl.unbind("SUPER + ALT + C")
o.bind("SUPER + ALT + C", "Flow: Cancel recording", "omarchy-shell io.github.ef-code.omarchy-flow.service cancel")
-- <<< omarchy-flow managed hotkeys <<<

-- [nav-guide-keybind]
-- Enhanced Super+K window for Omarchy
hl.unbind("SUPER + K")
o.bind("SUPER + K", "Super+K Alternative", "omarchy-shell nav-guide toggle")
-- Preserve the classic keybindings menu on a dedicated fallback shortcut
o.bind("SUPER + SHIFT + K", "Classic Keybindings Menu", "omarchy-menu-keybindings")
-- [/nav-guide-keybind]
