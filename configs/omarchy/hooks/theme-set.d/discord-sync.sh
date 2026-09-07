#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for Discord
# ------------------------------------------------------------------------------
# Generates discord-theme.css with full Omarchy palette tokens (accent, background,
# surfaces, typography, borders, highlights) and signals Discord's live injector.
# ==============================================================================

CURRENT_THEME_DIR="$HOME/.local/state/omarchy/current/theme"
DEST_CSS="$CURRENT_THEME_DIR/discord-theme.css"

[[ -f "$CURRENT_THEME_DIR/colors.toml" ]] || exit 0

python3 - << 'PYEOF'
import os, sys, re

theme_dir = os.path.expanduser("~/.local/state/omarchy/current/theme")
colors_toml = os.path.join(theme_dir, "colors.toml")
dest_css = os.path.join(theme_dir, "discord-theme.css")

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

def hex_to_rgb(h):
    h = h.lstrip('#')
    if len(h) == 3:
        h = ''.join(c*2 for c in h)
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hex(rgb):
    return '#{:02x}{:02x}{:02x}'.format(
        max(0, min(255, int(round(rgb[0])))),
        max(0, min(255, int(round(rgb[1])))),
        max(0, min(255, int(round(rgb[2]))))
    )

def blend(c1, c2, factor):
    r1, g1, b1 = hex_to_rgb(c1)
    r2, g2, b2 = hex_to_rgb(c2)
    return rgb_to_hex((
        r1 * (1 - factor) + r2 * factor,
        g1 * (1 - factor) + r2 * factor,
        b1 * (1 - factor) + r2 * factor
    ))

bg = colors.get("background") or colors.get("bg", "#111c18")
fg = colors.get("foreground") or colors.get("fg", "#C1C497")
accent = colors.get("accent", "#509475")
muted = colors.get("muted", "#53685B")
bright_fg = colors.get("bright_foreground", fg)
dark_fg = colors.get("dark_foreground", muted)
dark_bg = colors.get("dark_background", blend(bg, "#000000", 0.2))
darker_bg = colors.get("darker_background", blend(bg, "#000000", 0.4))
lighter_bg = colors.get("lighter_background", blend(bg, "#ffffff", 0.1))

is_light = (mode == "light")

if is_light:
    bg_lowest = "#ffffff"
    bg_lower = blend(bg, "#ffffff", 0.45)
    bg_base = bg
    bg_surface = blend(bg, "#000000", 0.06)
    bg_surface_high = blend(bg, "#000000", 0.12)
    bg_surface_highest = blend(bg, "#000000", 0.18)

    text_normal = "#1c1c1c"
    text_bright = "#0a0a0a"
    text_muted = "#4a4a4a"
    text_link = accent

    border_subtle = blend(bg, "#000000", 0.08)
    border_normal = blend(bg, "#000000", 0.15)
    border_strong = blend(bg, "#000000", 0.25)

    accent_hover = blend(accent, "#000000", 0.12)
    accent_active = blend(accent, "#000000", 0.22)
    accent_fg = "#ffffff"
else:
    bg_lowest = darker_bg
    bg_lower = dark_bg
    bg_base = bg
    bg_surface = lighter_bg
    bg_surface_high = blend(bg_surface, "#ffffff", 0.08)
    bg_surface_highest = blend(bg_surface, "#ffffff", 0.15)

    text_normal = fg
    text_bright = bright_fg
    text_muted = dark_fg
    text_link = accent

    border_subtle = blend(bg_base, "#ffffff", 0.06)
    border_normal = blend(bg_base, "#ffffff", 0.12)
    border_strong = blend(bg_base, "#ffffff", 0.20)

    accent_hover = blend(accent, "#ffffff", 0.12)
    accent_active = blend(accent, "#000000", 0.15)
    accent_fg = bg_lowest

neutrals = []
for i in range(1, 101):
    f = (i - 1) / 99.0
    if is_light:
        if f < 0.3:
            c = blend(bg_lowest, bg_base, f / 0.3)
        elif f < 0.6:
            c = blend(bg_base, border_strong, (f - 0.3) / 0.3)
        else:
            c = blend(text_muted, text_bright, (f - 0.6) / 0.4)
    else:
        if f < 0.3:
            c = blend(text_bright, text_normal, f / 0.3)
        elif f < 0.6:
            c = blend(text_normal, border_subtle, (f - 0.3) / 0.3)
        else:
            c = blend(bg_surface, bg_lowest, (f - 0.6) / 0.4)
    neutrals.append(f"  --neutral-{i}: {c} !important;")

css = f"""/* mode: {mode} */
/* Omarchy Dynamic Discord Theme */
*,
*::before,
*::after,
:root,
html,
body,
.theme-dark,
.theme-darker,
.theme-light,
.theme-midnight,
.visual-refresh,
[class*="theme-"] {{
  --background-base-lowest: {bg_lowest} !important;
  --background-base-lower: {bg_lower} !important;
  --background-base-low: {bg_base} !important;
  --background-surface-high: {bg_surface} !important;
  --background-surface-higher: {bg_surface_high} !important;
  --background-surface-highest: {bg_surface_highest} !important;
  --bg-surface-raised: {bg_surface} !important;

  --chat-background: {bg_base} !important;
  --chat-background-default: {bg_base} !important;
  --panel-bg: {bg_lowest} !important;
  --card-primary-bg: {bg_surface} !important;
  --card-secondary-bg: {bg_lower} !important;
  --modal-background: {bg_base} !important;
  --modal-footer-background: {bg_lowest} !important;
  --channeltextarea-background: {bg_lower} !important;

  --background-gradient-highest: {bg_surface} !important;
  --background-gradient-high: {bg_lower} !important;
  --background-gradient-low: {bg_base} !important;
  --background-gradient-lowest: {bg_lowest} !important;

  --control-primary-background-default: {accent} !important;
  --control-primary-background-hover: {accent_hover} !important;
  --control-primary-background-active: {accent_active} !important;
  --control-brand-foreground: {accent_fg} !important;

  --brand-500: {accent} !important;
  --brand-560: {accent_hover} !important;
  --brand-600: {accent_active} !important;
  --brand-experiment: {accent} !important;
  --brand-experiment-500: {accent} !important;

  --blurple-50: {accent} !important;
  --blurple-55: {accent_hover} !important;
  --blurple-60: {accent_active} !important;

  --text-normal: {text_normal} !important;
  --text-muted: {text_muted} !important;
  --text-link: {text_link} !important;
  --text-primary: {text_bright} !important;
  --text-secondary: {text_normal} !important;

  --header-primary: {text_bright} !important;
  --header-secondary: {text_normal} !important;
  --interactive-normal: {text_normal} !important;
  --interactive-hover: {text_bright} !important;
  --interactive-active: {accent} !important;
  --interactive-muted: {text_muted} !important;

  --border-subtle: {border_subtle} !important;
  --border-normal: {border_normal} !important;
  --border-strong: {border_strong} !important;

  --scrollbar-auto-thumb: {border_normal} !important;
  --scrollbar-auto-track: transparent !important;
  --scrollbar-thin-thumb: {border_subtle} !important;

{chr(10).join(neutrals)}
}}

/* Structural Layout Overrides */
nav[class*="guilds_"],
[class*="guilds_"],
ul[class*="tree_"],
[class*="folder_"],
[class*="scroller_"][class*="guilds_"] {{
  background-color: {bg_lowest} !important;
}}

[class*="childWrapper_"] {{
  background-color: {accent} !important;
  color: {accent_fg} !important;
}}
[class*="childWrapper_"] svg {{
  color: {accent_fg} !important;
}}

[class*="sidebar_"],
[class*="container_"]:has(> [class*="sidebar_"]) {{
  background-color: {bg_lower} !important;
}}

[class*="panels_"],
[class*="container_"][class*="panels_"] {{
  background-color: {bg_lowest} !important;
  border-top: 1px solid {border_subtle} !important;
}}

[class*="title_"],
[class*="subtitleContainer_"],
[class*="header_"][class*="container_"] {{
  background-color: {bg_base} !important;
  border-bottom: 1px solid {border_subtle} !important;
}}

[class*="searchBar_"] {{
  background-color: {bg_lowest} !important;
}}
[class*="searchBar_"] [class*="searchBarComponent_"] {{
  background-color: {bg_lowest} !important;
  color: {text_muted} !important;
}}

[class*="chat_"],
[class*="chatContent_"],
[class*="content_"]:has(> [class*="chatContent_"]),
[class*="messagesWrapper_"] {{
  background-color: {bg_base} !important;
}}

[class*="membersWrap_"],
[class*="members_"],
[class*="nowPlayingColumn_"] {{
  background-color: {bg_lower} !important;
}}

[class*="channelTextArea_"],
[class*="channelTextArea_"] [class*="scrollableContainer_"] {{
  background-color: {bg_lowest} !important;
  border: 1px solid {border_subtle} !important;
}}

[class*="channel_"][class*="selected_"] [class*="link_"],
[class*="interactive_"]:hover,
[class*="interactiveSelected_"] {{
  background-color: {bg_surface} !important;
}}

[class*="unread_"],
[class*="badge_"],
[class*="numberBadge_"] {{
  background-color: {accent} !important;
  color: {accent_fg} !important;
}}

code, pre, [class*="codeBlockText_"] {{
  background-color: {bg_lowest} !important;
  border: 1px solid {border_subtle} !important;
  color: {text_normal} !important;
}}
[class*="embedFull_"] {{
  background-color: {bg_lower} !important;
  border-left-color: {accent} !important;
}}

[class*="menu_"],
[class*="contextMenu_"],
[class*="popout_"],
[class*="root_"][class*="modal_"],
[class*="focusLock_"] [class*="root_"] {{
  background-color: {bg_lower} !important;
  border: 1px solid {border_normal} !important;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4) !important;
}}

::selection {{
  background-color: {accent} !important;
  color: {accent_fg} !important;
}}
"""

with open(dest_css, "w") as f:
    f.write(css)

print(f"[discord-sync] Generated {dest_css} for mode: {mode}")
PYEOF
