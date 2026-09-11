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
o.bind("SUPER + H", "Toggle dictation", "voxtype-dictate-toggle")
o.bind("CTRL + H", "Toggle dictation", "voxtype-dictate-toggle")
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
