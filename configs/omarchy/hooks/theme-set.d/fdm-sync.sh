#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for Free Download Manager (FDM)
# ------------------------------------------------------------------------------
# Generates fdm-theme.json with full Omarchy palette tokens (accent, background,
# selection, borders, highlights) and signals FDM's live QML engine.
# ==============================================================================

CURRENT_THEME_DIR="$HOME/.local/state/omarchy/current/theme"
FDM_TPL="$HOME/.config/omarchy/themed/fdm-theme.json.tpl"
FDM_DEST="$CURRENT_THEME_DIR/fdm-theme.json"
FDM_SETTINGS="$HOME/.local/share/Softdeluxe/Free Download Manager/settings.ini"

[[ -f "$CURRENT_THEME_DIR/colors.toml" ]] || exit 0

# 1. Compile fdm-theme.json using Python for robust token fallback & JSON validity
python3 - << 'PYEOF'
import os, json, re

theme_dir = os.path.expanduser("~/.local/state/omarchy/current/theme")
colors_toml = os.path.join(theme_dir, "colors.toml")
dest_json = os.path.join(theme_dir, "fdm-theme.json")

colors = {}
if os.path.exists(colors_toml):
    with open(colors_toml, "r") as f:
        for line in f:
            m = re.match(r'^([a-zA-Z0-9_]+)\s*=\s*"?([^"\r\n]+)"?', line.strip())
            if m:
                colors[m.group(1)] = m.group(2)

mode = colors.get("mode", "dark")
if not mode or mode not in ("light", "dark"):
    mode_file = os.path.join(theme_dir, "mode")
    if os.path.exists(mode_file):
        with open(mode_file) as f:
            mode = f.read().strip()
    else:
        mode = "dark"

bg = colors.get("background") or colors.get("bg", "#0b0d11")
dark_bg = colors.get("dark_background") or colors.get("dark_bg", bg)
darker_bg = colors.get("darker_background") or colors.get("darker_bg", dark_bg)
lighter_bg = colors.get("lighter_background") or colors.get("lighter_bg", "#19171c")
fg = colors.get("foreground") or colors.get("fg", "#f0b7ca")
bright_fg = colors.get("bright_foreground") or colors.get("bright_fg", fg)
dark_fg = colors.get("dark_foreground") or colors.get("dark_fg", "#4a5d46")
soft_fg = colors.get("soft_fg", fg)
accent = colors.get("accent", "#f23888")
selection = colors.get("selection", accent)
muted = colors.get("muted", "#678270")
green = colors.get("green", colors.get("color2", "#5aa15d"))
red = colors.get("red", colors.get("color1", "#f23888"))
yellow = colors.get("yellow", colors.get("color3", "#d7be96"))

theme_data = {
    "mode": mode,
    # Dark Mode Palette
    "dark100": bg,
    "dark200": dark_bg,
    "dark300": darker_bg,
    "dark400": selection,
    "dark500": muted,
    "dark600": dark_fg,
    "dark700": soft_fg,
    "dark800": fg,
    "dark900": bright_fg,
    "dark1000": bright_fg,
    "darkPrimary": accent,
    "darkSecondary": green,
    "darkAmber": yellow,
    "darkDanger": red,

    # Light Mode Palette (Guaranteed high-contrast dark text on light surfaces)
    "light100": fg if mode == "light" else "#171A1F",
    "light200": fg if mode == "light" else "#1F2329",
    "light300": dark_fg if mode == "light" else "#272C33",
    "light400": muted if mode == "light" else "#424B57",
    "light500": muted if mode == "light" else "#5A6677",
    "light600": selection if mode == "light" else "#929DAD",
    "light700": lighter_bg if mode == "light" else "#CED6E0",
    "light800": bg if mode == "light" else "#E6EAEF",
    "light900": bg if mode == "light" else "#ECEFF3",
    "light1000": bg if mode == "light" else "#FDFDFD",
    "lightPrimary": accent,
    "lightSecondary": green,
    "lightAmber": yellow,
    "lightDanger": red,
}

with open(dest_json + ".tmp", "w") as f:
    json.dump(theme_data, f, indent=2)
os.replace(dest_json + ".tmp", dest_json)
PYEOF

# 2. Ensure FDM settings are configured to follow system theme
if [[ -f "$FDM_SETTINGS" ]]; then
  if grep -q '^theme=' "$FDM_SETTINGS"; then
    sed -i 's/^theme=.*/theme=system/' "$FDM_SETTINGS"
  fi
fi

# 3. Emit color-scheme signal for GTK/portal
is_light=false
if [[ -f "$CURRENT_THEME_DIR/mode" && "$(cat "$CURRENT_THEME_DIR/mode" 2>/dev/null)" == "light" ]]; then
  is_light=true
elif grep -q '^mode\s*=\s*"light"' "$CURRENT_THEME_DIR/colors.toml" 2>/dev/null; then
  is_light=true
fi

if command -v gsettings >/dev/null 2>&1 && [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  if [[ "$is_light" == "true" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme "prefer-light" 2>/dev/null || true
  else
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
  fi
fi
