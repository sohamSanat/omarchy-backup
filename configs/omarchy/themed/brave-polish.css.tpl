/* ==============================================================================
 * Omarchy Dynamic Site Polish for Brave-Origin
 * ------------------------------------------------------------------------------
 * Template: ~/.config/omarchy/themed/brave-polish.css.tpl
 * Compiled to: ~/.local/state/omarchy/current/theme/brave-polish.css
 * Consumed by: ~/.config/omarchy/brave-polish/loader.js (companion MV3 ext)
 *   fetched at document_start on every navigation -> hot-applies, no restart.
 *
 * Scoped per-site so unrelated websites are untouched.
 * ============================================================================== */

/* ---- Universal Omarchy tokens + selection + scrollbars + focus ---- */
:root {
  --omarchy-bg: {{ background }} !important;
  --omarchy-fg: {{ foreground }} !important;
  --omarchy-accent: {{ accent }} !important;
  --omarchy-muted: {{ muted }} !important;
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

/* ================= YouTube ================= */
html[youtube-omarchy] {
  --yt-spec-base-background: {{ background }} !important;
  --yt-spec-raised-background: {{ dark_background }} !important;
  --yt-spec-menu-background: {{ dark_background }} !important;
  --yt-spec-text-primary: {{ foreground }} !important;
  --yt-spec-text-secondary: {{ muted }} !important;
  --yt-spec-icon-inactive: {{ muted }} !important;
  --yt-spec-brand-icon-active: {{ foreground }} !important;
  --yt-spec-call-to-action: {{ accent }} !important;
  --yt-spec-suggested-action: color-mix(in srgb, {{ accent }} 15%, {{ background }}) !important;
  --yt-spec-button-chip-background-hover: color-mix(in srgb, {{ foreground }} 12%, {{ background }}) !important;
  --yt-spec-10-percent-layer: color-mix(in srgb, {{ foreground }} 10%, transparent) !important;
  --yt-spec-outline: color-mix(in srgb, {{ foreground }} 20%, transparent) !important;
  --yt-app-background: {{ background }} !important;
  --yt-primary-color: {{ foreground }} !important;
  --yt-secondary-color: {{ muted }} !important;
}

html[youtube-omarchy] #page-manager,
html[youtube-omarchy] ytd-app,
html[youtube-omarchy] ytd-browse,
html[youtube-omarchy] ytd-watch-flexy {
  background: {{ background }} !important;
}

html[youtube-omarchy] ytd-masthead,
html[youtube-omarchy] #masthead-container {
  background: {{ dark_background }} !important;
}

html[youtube-omarchy] #container.ytd-searchbox {
  background: {{ darker_background }} !important;
  border-color: color-mix(in srgb, {{ foreground }} 20%, transparent) !important;
}

html[youtube-omarchy] #video-title,
html[youtube-omarchy] .yt-core-attributed-string {
  color: {{ foreground }} !important;
}

html[youtube-omarchy] #metadata-line,
html[youtube-omarchy] ytd-video-meta-block {
  color: {{ muted }} !important;
}

html[youtube-omarchy] .ytp-play-progress {
  background: {{ accent }} !important;
}

/* ================= GitHub ================= */
html[github-omarchy] {
  --bgColor-default: {{ background }} !important;
  --bgColor-muted: {{ dark_background }} !important;
  --bgColor-inset: {{ darker_background }} !important;
  --bgColor-accent-muted: color-mix(in srgb, {{ accent }} 15%, {{ background }}) !important;
  --fgColor-default: {{ foreground }} !important;
  --fgColor-muted: {{ muted }} !important;
  --fgColor-accent: {{ accent }} !important;
  --borderColor-default: color-mix(in srgb, {{ foreground }} 18%, transparent) !important;
  --borderColor-muted: color-mix(in srgb, {{ foreground }} 12%, transparent) !important;
}

html[github-omarchy] body,
html[github-omarchy] .AppHeader,
html[github-omarchy] .Header {
  background-color: {{ background }} !important;
  color: {{ foreground }} !important;
}

/* ================= Reddit (Shreddit) ================= */
html[reddit-omarchy] {
  --shreddit-content-background: {{ background }} !important;
  --color-neutral-background: {{ background }} !important;
  --color-neutral-background-weak: {{ dark_background }} !important;
  --color-neutral-background-medium: {{ darker_background }} !important;
}

html[reddit-omarchy] shreddit-app,
html[reddit-omarchy] #main-content,
html[reddit-omarchy] .subgrid-container {
  background: {{ background }} !important;
  color: {{ foreground }} !important;
}

html[reddit-omarchy] a { color: {{ accent }} !important; }
