#!/bin/bash
# Hook triggered on Omarchy theme-set to synchronize colors to Herdr
# Adheres strictly to Omarchy theming and high-contrast dual-mode rules.

set -euo pipefail

THEME_NAME="${1:-}"
CONFIG_FILE="$HOME/.config/herdr/config.toml"

if [[ ! -f "$CONFIG_FILE" ]]; then
  exit 0
fi

# Query theme parameters via omarchy-theme-env if available
if command -v omarchy-theme-env &>/dev/null; then
  THEME_JSON=$(omarchy-theme-env --json 2>/dev/null || echo "{}")
  MODE=$(echo "$THEME_JSON" | jq -r '.mode // "dark"')
  FG=$(echo "$THEME_JSON" | jq -r '.foreground // "#14B9B5"')
  BG=$(echo "$THEME_JSON" | jq -r '.background // "#0e091d"')
  ACCENT=$(echo "$THEME_JSON" | jq -r '.accent // "#BE3F50"')
else
  MODE="${OMARCHY_THEME_MODE:-dark}"
  FG="${OMARCHY_THEME_FG:-#14B9B5}"
  BG="${OMARCHY_THEME_BG:-#0e091d}"
  ACCENT="${OMARCHY_THEME_ACCENT:-#BE3F50}"
fi

# Run python helper to calculate colors and update config.toml
python3 - <<PY
import re, sys

config_path = "$CONFIG_FILE"
mode = "$MODE"
bg = "$BG"
fg = "$FG"
accent = "$ACCENT"

def parse_hex(h):
    h = h.lstrip('#')
    if len(h) == 3:
        h = ''.join(c*2 for c in h)
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def to_hex(rgb):
    return '#{:02x}{:02x}{:02x}'.format(*(max(0, min(255, int(v))) for v in rgb))

def blend(c1, c2, factor):
    # factor = 1.0 means c1, factor = 0.0 means c2
    return tuple(c1[i]*factor + c2[i]*(1-factor) for i in range(3))

try:
    bg_rgb = parse_hex(bg)
    accent_rgb = parse_hex(accent)
    fg_rgb = parse_hex(fg)

    if mode == "light":
        # Light mode:
        panel_bg = "reset"
        sidebar_bg = to_hex(blend(bg_rgb, (0, 0, 0), 0.94))
        active_row_bg = to_hex(blend(bg_rgb, accent_rgb, 0.85))
        selection_bg = to_hex(blend(bg_rgb, accent_rgb, 0.75))
        red = "#c82828"
        green = "#288c3a"
    else:
        # Dark mode:
        panel_bg = "reset"
        sidebar_bg = to_hex(blend(bg_rgb, (0, 0, 0), 0.75))
        active_row_bg = to_hex(blend(bg_rgb, accent_rgb, 0.78))
        selection_bg = to_hex(blend(bg_rgb, fg_rgb, 0.82))
        red = accent
        green = "#7cd699"

    with open(config_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Update [ui] accent
    content = re.sub(r'(?m)^(\s*accent\s*=\s*)"[^"]*"', r'\1"' + accent + '"', content)

    # Update [theme.custom] block
    custom_block = f"""[theme.custom]
sidebar_bg = "{sidebar_bg}"
active_row_bg = "{active_row_bg}"
selection_bg = "{selection_bg}"
panel_bg = "{panel_bg}"
accent = "{accent}"
red = "{red}"
green = "{green}" """

    if "[theme.custom]" in content:
        content = re.sub(r"(?s)\[theme\.custom\].*?(?=\n\[|\Z)", custom_block + "\n", content)
    else:
        content = re.sub(r"(\[theme\][^\n]*\n)", r"\1\n" + custom_block + "\n\n", content)

    with open(config_path, "w", encoding="utf-8") as f:
        f.write(content)

except Exception as e:
    print(f"Error updating config: {e}", file=sys.stderr)
    sys.exit(1)
PY

# If Herdr server is active, reload config live
if command -v herdr &>/dev/null; then
  herdr server reload-config >/dev/null 2>&1 || true
fi
