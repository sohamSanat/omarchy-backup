#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for Foliate (EPUB / PDF Reader & Library)
# ------------------------------------------------------------------------------
# Generates omarchy.json theme, user-stylesheet.css, foliate.css, and GTK4 CSS
# with full palette tokens (accent, background, reader view, sidebar, headerbar).
# ==============================================================================

CURRENT_THEME_DIR="$HOME/.local/state/omarchy/current/theme"
FOLIATE_CONFIG_DIR="$HOME/.config/com.github.johnfactotum.Foliate"
FOLIATE_THEMES_DIR="$FOLIATE_CONFIG_DIR/themes"
GTK4_CONFIG_DIR="$HOME/.config/gtk-4.0"

mkdir -p "$FOLIATE_THEMES_DIR" "$GTK4_CONFIG_DIR"

[[ -f "$CURRENT_THEME_DIR/colors.toml" ]] || exit 0

python3 - << 'PYEOF'
import os, json
try:
    import tomllib
except ImportError:
    import tomli as tomllib

theme_dir = os.path.expanduser("~/.local/state/omarchy/current/theme")
colors_toml = os.path.join(theme_dir, "colors.toml")
foliate_themes_dir = os.path.expanduser("~/.config/com.github.johnfactotum.Foliate/themes")
foliate_user_css = os.path.expanduser("~/.config/com.github.johnfactotum.Foliate/user-stylesheet.css")
foliate_css = os.path.expanduser("~/.config/com.github.johnfactotum.Foliate/foliate.css")
gtk4_css = os.path.expanduser("~/.config/gtk-4.0/gtk.css")

colors = {}
if os.path.exists(colors_toml):
    with open(colors_toml, "rb") as f:
        colors = tomllib.load(f)

mode = colors.get("mode", "dark")
if not mode or mode not in ("light", "dark"):
    mode_file = os.path.join(theme_dir, "mode")
    if os.path.exists(mode_file):
        with open(mode_file) as f:
            mode = f.read().strip()
    else:
        mode = "dark"

bg = colors.get("background") or colors.get("bg", "#111c18")
fg = colors.get("foreground") or colors.get("fg", "#C1C497")
accent = colors.get("accent", "#509475")
selection = colors.get("selection", "#32473B")
muted = colors.get("muted", "#53685B")
dark_bg = colors.get("dark_background") or colors.get("dark_bg", bg)
darker_bg = colors.get("darker_background") or colors.get("darker_bg", dark_bg)
lighter_bg = colors.get("lighter_background") or colors.get("lighter_bg", bg)
bright_fg = colors.get("bright_foreground") or colors.get("bright_fg", fg)
dark_fg = colors.get("dark_foreground") or colors.get("dark_fg", fg)

def wcag_lum(h):
    if not isinstance(h, str): return 0.5
    h = h.lstrip('#')
    if len(h) != 6: return 0.5
    try:
        rgb = [int(h[i:i+2], 16)/255.0 for i in (0, 2, 4)]
        rgb = [c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4 for c in rgb]
        return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]
    except Exception:
        return 0.5

def wcag_contrast(c1, c2):
    l1, l2 = wcag_lum(c1), wcag_lum(c2)
    return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)

accent_fg = "#ffffff" if wcag_contrast(accent, "#ffffff") >= wcag_contrast(accent, "#000000") else "#000000"
selection_fg = "#ffffff" if wcag_contrast(selection, "#ffffff") >= wcag_contrast(selection, "#000000") else "#000000"

if mode == "light":
    sidebar_bg = darker_bg if darker_bg != bg else "#e4d8c0"
    sidebar_fg = dark_fg if dark_fg else fg
    sidebar_border = f"color-mix(in srgb, {muted} 30%, transparent)"
    card_bg = lighter_bg if lighter_bg != bg else "#ffffff"
    muted_header = dark_fg if wcag_contrast(dark_fg, sidebar_bg) >= 3.8 else (fg if wcag_contrast(fg, sidebar_bg) >= 3.8 else "#33291b")
    sidebar_shade = "rgba(0, 0, 0, 0.07)"
else:
    sidebar_bg = darker_bg if darker_bg != bg else dark_bg
    sidebar_fg = fg
    sidebar_border = f"color-mix(in srgb, {muted} 40%, transparent)"
    card_bg = lighter_bg if lighter_bg != bg else "rgba(255, 255, 255, 0.08)"
    muted_header = bright_fg if bright_fg else fg
    sidebar_shade = "rgba(0, 0, 0, 0.25)"

# 1. Build Foliate omarchy.json
if mode == "light":
    theme_data = {
        "label": "Omarchy",
        "light": {
            "fg": fg,
            "bg": bg,
            "link": accent
        },
        "dark": {
            "fg": "#C1C497",
            "bg": "#111c18",
            "link": accent
        }
    }
else:
    theme_data = {
        "label": "Omarchy",
        "light": {
            "fg": "#33291b",
            "bg": "#f0e6d3",
            "link": accent
        },
        "dark": {
            "fg": fg,
            "bg": bg,
            "link": accent
        }
    }

dest_json = os.path.join(foliate_themes_dir, "omarchy.json")
with open(dest_json + ".tmp", "w") as f:
    json.dump(theme_data, f, indent=2)
os.replace(dest_json + ".tmp", dest_json)

# 2. Build Foliate user-stylesheet.css
user_css_content = f"""/* ==============================================================================
 * Omarchy Foliate Reader User Stylesheet
 * Generated automatically from active Omarchy theme
 * ============================================================================== */

::selection {{
    background-color: {selection} !important;
    color: {selection_fg} !important;
}}

/* Clean Custom Scrollbars */
::-webkit-scrollbar {{
    width: 6px;
    height: 6px;
}}
::-webkit-scrollbar-track {{
    background: transparent;
}}
::-webkit-scrollbar-thumb {{
    background: {muted}55;
    border-radius: 3px;
}}
::-webkit-scrollbar-thumb:hover {{
    background: {accent};
}}

/* Typography Accents */
h1, h2, h3, h4, h5, h6 {{
    color: {bright_fg if mode == 'dark' else dark_fg};
}}

a, a:any-link {{
    color: {accent} !important;
    text-underline-offset: 0.15em;
}}

code, pre {{
    background-color: {darker_bg if mode == 'dark' else lighter_bg} !important;
    color: {bright_fg if mode == 'dark' else fg} !important;
    border-radius: 4px;
}}
pre {{
    border-left: 3px solid {accent} !important;
    padding: 10px 14px !important;
}}

blockquote {{
    border-left: 3px solid {accent} !important;
    padding-left: 14px !important;
    margin-left: 0 !important;
    margin-right: 0 !important;
    color: {muted} !important;
}}
"""

with open(foliate_user_css + ".tmp", "w") as f:
    f.write(user_css_content)
os.replace(foliate_user_css + ".tmp", foliate_user_css)

# 3. Build Full Libadwaita & Foliate CSS definitions (Strict GTK CSS syntax)
css_bundle = f"""/* Omarchy GTK 4 / Libadwaita System & Foliate Styling */
@define-color accent_color {accent};
@define-color accent_bg_color {accent};
@define-color accent_fg_color {accent_fg};
@define-color window_bg_color {bg};
@define-color window_fg_color {fg};
@define-color view_bg_color {bg};
@define-color view_fg_color {fg};
@define-color headerbar_bg_color {dark_bg};
@define-color headerbar_fg_color {fg};
@define-color headerbar_border_color {sidebar_border};
@define-color headerbar_backdrop_color {dark_bg};
@define-color sidebar_bg_color {sidebar_bg};
@define-color sidebar_fg_color {sidebar_fg};
@define-color sidebar_backdrop_color {sidebar_bg};
@define-color sidebar_shade_color {sidebar_shade};
@define-color sidebar_border_color {sidebar_border};
@define-color secondary_sidebar_bg_color {sidebar_bg};
@define-color secondary_sidebar_fg_color {sidebar_fg};
@define-color secondary_sidebar_backdrop_color {sidebar_bg};
@define-color secondary_sidebar_border_color {sidebar_border};
@define-color secondary_sidebar_shade_color {sidebar_shade};
@define-color card_bg_color {card_bg};
@define-color card_fg_color {fg};
@define-color popover_bg_color {dark_bg};
@define-color popover_fg_color {fg};
@define-color dialog_bg_color {dark_bg};
@define-color dialog_fg_color {fg};

/* --- Foliate Library View & Navigation Sidebar --- */

/* Split view sidebar pane container */
.sidebar-pane,
overlay-split-view > .sidebar-pane,
splitview > sidebar,
navigation-split-view > .sidebar-pane {{
    background-color: @sidebar_bg_color;
    color: @sidebar_fg_color;
}}

.sidebar-pane toolbarview,
.sidebar-pane scrolledwindow {{
    background-color: transparent;
    color: @sidebar_fg_color;
}}

/* Sidebar Top HeaderBar (housing hamburger Main Menu button) */
.sidebar-pane headerbar,
.sidebar-pane toolbarview > .top-bar headerbar,
.sidebar-pane .top-bar.raised {{
    background-color: @sidebar_bg_color;
    color: @sidebar_fg_color;
    box-shadow: none;
    border-bottom: 1px solid @sidebar_border_color;
}}

.sidebar-pane headerbar button,
.sidebar-pane headerbar menubutton > button {{
    color: @sidebar_fg_color;
    border-radius: 6px;
}}

.sidebar-pane headerbar button:hover,
.sidebar-pane headerbar menubutton > button:hover {{
    background-color: alpha(@sidebar_fg_color, 0.12);
    color: @sidebar_fg_color;
}}

/* Split view divider line */
overlay-split-view > border {{
    background-color: @sidebar_border_color;
    min-width: 1px;
}}

/* Navigation Sidebar ListBox */
.navigation-sidebar {{
    background-color: transparent;
    padding: 8px 6px;
}}

/* Section Headings: LIBRARY, CATALOGS */
.navigation-sidebar .caption-heading,
.navigation-sidebar .dim-label,
.navigation-sidebar header label,
.navigation-sidebar > .header > .heading {{
    color: {muted_header};
    font-weight: 700;
    font-size: 0.72rem;
    letter-spacing: 0.08em;
    opacity: 1;
    margin-left: 12px;
    margin-top: 14px;
    margin-bottom: 4px;
}}

/* Sidebar Navigation Items */
.navigation-sidebar row {{
    border-radius: 8px;
    margin: 2px 4px;
    padding: 6px 10px;
    color: @sidebar_fg_color;
    transition: background-color 150ms ease, color 150ms ease;
    font-size: 0.95rem;
}}

.navigation-sidebar row:not(:selected):hover {{
    background-color: alpha(@accent_bg_color, 0.16);
    color: @sidebar_fg_color;
}}

.navigation-sidebar row:not(:selected):active {{
    background-color: alpha(@accent_bg_color, 0.26);
}}

/* Active Selected Row (Theme accent pill) */
.navigation-sidebar row:selected,
.navigation-sidebar row:selected:hover,
.navigation-sidebar row:selected:focus,
.navigation-sidebar row.activatable:selected,
.navigation-sidebar child:selected,
.navigation-sidebar flowboxchild:selected {{
    background-color: @accent_bg_color;
    color: @accent_fg_color;
    font-weight: 600;
}}

/* Text and Icons inside Selected Row */
.navigation-sidebar row:selected label,
.navigation-sidebar row:selected image,
.navigation-sidebar row:selected .icon {{
    color: @accent_fg_color;
}}

/* Main Content Area in Library */
#library-toolbar-view,
#catalog-toolbar-view,
overlay-split-view > .content-pane {{
    background-color: @window_bg_color;
    color: @window_fg_color;
}}

#library-toolbar-view headerbar,
#catalog-toolbar-view headerbar {{
    background-color: @headerbar_bg_color;
    color: @headerbar_fg_color;
    border-bottom: 1px solid @sidebar_border_color;
}}

#search-bar {{
    background-color: @headerbar_bg_color;
    border-bottom: 1px solid @sidebar_border_color;
}}

#search-bar entry {{
    background-color: @view_bg_color;
    color: @view_fg_color;
}}
"""

# Write to foliate.css
with open(foliate_css + ".tmp", "w") as f:
    f.write(css_bundle)
os.replace(foliate_css + ".tmp", foliate_css)

# Write to gtk.css for global GTK 4 Libadwaita apps
with open(gtk4_css + ".tmp", "w") as f:
    f.write(css_bundle)
os.replace(gtk4_css + ".tmp", gtk4_css)

PYEOF

# 4. Configure GSettings for Foliate
if command -v gsettings >/dev/null 2>&1 && [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  gsettings set com.github.johnfactotum.Foliate.viewer.view theme 'omarchy.json' 2>/dev/null || true

  IS_LIGHT=false
  if [[ -f "$CURRENT_THEME_DIR/mode" && "$(cat "$CURRENT_THEME_DIR/mode" 2>/dev/null)" == "light" ]]; then
    IS_LIGHT=true
  elif grep -q '^mode\s*=\s*"light"' "$CURRENT_THEME_DIR/colors.toml" 2>/dev/null; then
    IS_LIGHT=true
  fi

  if [[ "$IS_LIGHT" == "true" ]]; then
    gsettings set com.github.johnfactotum.Foliate color-scheme 1 2>/dev/null || true
  else
    gsettings set com.github.johnfactotum.Foliate color-scheme 2 2>/dev/null || true
  fi
fi
