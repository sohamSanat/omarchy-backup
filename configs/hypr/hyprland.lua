-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- BEGIN OMARCHY SENSEI (managed by omarchy-sensei setup)
require("default.hypr.helpers")
require("hypr.sensei")
-- END OMARCHY SENSEI

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Personal Hyprland window rules & configuration
-- Increase transparency for Obsidian so the wallpaper bleeds through with glass blur
o.window("(obsidian|md\\.obsidian\\.Obsidian)", {
  tag = "-default-opacity",
  opacity = "0.85 0.78",
})

-- Increase transparency for file managers (Strata & Nautilus) for a glass-like blur effect
o.window("(io\\.github\\.lgse\\.Strata|strata|org\\.gnome\\.Nautilus|nautilus)", {
  tag = "-default-opacity",
  opacity = "0.82 0.75",
})

-- wmfeht.border-fx (Omarchy plugin control plane; pcall if the file is missing)
pcall(require, "hypr.border-fx")
