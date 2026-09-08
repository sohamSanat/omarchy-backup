/* ==============================================================================
 * Omarchy Universal Base for Brave-Origin (ALL websites)
 * ------------------------------------------------------------------------------
 * Template: ~/.config/omarchy/themed/brave-global.css.tpl
 * Compiled to: ~/.local/state/omarchy/current/theme/brave-global.css
 * Consumed by: ~/.config/omarchy/brave-polish/global.js (runs on <all_urls>)
 *
 * Deliberately conservative: only generic tokens no site can conflict with.
 * Pages that paint their own backgrounds keep them; transparent pages sit on
 * the Omarchy background. Native widgets follow the theme mode.
 * ============================================================================== */

:root {
  color-scheme: {{ mode }} !important;
  --omarchy-bg: {{ background }} !important;
  --omarchy-fg: {{ foreground }} !important;
  --omarchy-accent: {{ accent }} !important;
  --omarchy-muted: {{ muted }} !important;
}

html {
  background-color: {{ background }} !important;
}

::selection {
  background: {{ selection_background }} !important;
  color: {{ selection_foreground }} !important;
}

:focus-visible {
  outline: 2px solid {{ accent }} !important;
  outline-offset: 2px;
}

::-webkit-scrollbar { width: 10px !important; height: 10px !important; }
::-webkit-scrollbar-track { background: transparent !important; }
::-webkit-scrollbar-thumb {
  background: color-mix(in srgb, {{ muted }} 55%, transparent) !important;
  border-radius: 6px !important;
  border: 2px solid transparent !important;
  background-clip: content-box !important;
}
::-webkit-scrollbar-thumb:hover {
  background: color-mix(in srgb, {{ muted }} 85%, transparent) !important;
  background-clip: content-box !important;
}
