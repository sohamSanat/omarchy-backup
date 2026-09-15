/* ==============================================================================
 * Omarchy Dynamic Theme for Brave-Origin New Tab Page
 * ------------------------------------------------------------------------------
 * Template: ~/.config/omarchy/themed/brave-ntp.css.tpl
 * Compiled to: ~/.local/state/omarchy/current/theme/brave-ntp.css
 * Consumed by: ~/.config/omarchy/brave-polish/ntp.html
 *
 * Provides a floating, frosted search & quick access card on New Tab (Ctrl + T),
 * matching the exact aesthetic, typography, and keyboard responsiveness of Zen.
 * ============================================================================== */

:root {
  /* --- Omarchy System Theme Tokens --- */
  --omarchy-bg: {{ background }};
  --omarchy-fg: {{ foreground }};
  --omarchy-accent: {{ accent }};
  --omarchy-muted: {{ muted }};
  --omarchy-selection-bg: {{ selection_background }};
  --omarchy-selection-fg: {{ selection_foreground }};

  /* Surfaces & Interactivity (blended for perfect contrast in both light and dark modes) */
  --omarchy-surface: color-mix(in srgb, {{ foreground }} 7%, {{ background }});
  --omarchy-surface-hover: color-mix(in srgb, {{ foreground }} 13%, {{ background }});
  --omarchy-surface-active: color-mix(in srgb, {{ foreground }} 20%, {{ background }});
  --omarchy-border: color-mix(in srgb, {{ foreground }} 16%, transparent);
  --omarchy-border-subtle: color-mix(in srgb, {{ foreground }} 10%, transparent);
  --omarchy-card-bg: color-mix(in srgb, {{ background }} 94%, {{ foreground }} 6%);
}

* {
  box-sizing: border-box;
}

/* Guard: sweep any unexpected injected browser elements outside the root container */
body > :not(script):not(style):not(link):not(#omarchy-ntp-root) {
  display: none !important;
  visibility: hidden !important;
  height: 0 !important;
  min-height: 0 !important;
  margin: 0 !important;
  padding: 0 !important;
  border: none !important;
}

html, body {
  margin: 0;
  padding: 0;
  min-height: 100vh;
  width: 100vw;
  background: var(--omarchy-bg) !important;
  background-color: var(--omarchy-bg) !important;
  color: var(--omarchy-fg) !important;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Inter", Helvetica, Arial, sans-serif;
  overflow-x: hidden;
  user-select: none;
}

body {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
  padding-top: clamp(80px, 16vh, 160px);
  /* Dynamic ambient glow matching active theme accent */
  background-image:
    radial-gradient(60% 50% at 50% 0%, color-mix(in srgb, {{ accent }} 20%, transparent), transparent 70%),
    radial-gradient(40% 35% at 85% 90%, color-mix(in srgb, {{ accent }} 10%, transparent), transparent 70%);
  background-attachment: fixed;
}

::selection {
  background: var(--omarchy-selection-bg) !important;
  color: var(--omarchy-selection-fg) !important;
}

/* ==============================================================================
   NTP Root & Search Card (Zen-Grade Floating Card)
   ============================================================================== */

#omarchy-ntp-root {
  width: 100%;
  max-width: 680px;
  padding: 0 16px;
  display: flex;
  flex-direction: column;
  align-items: center;
  animation: omarchy-card-appear 0.22s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes omarchy-card-appear {
  from {
    opacity: 0;
    transform: translateY(-8px) scale(0.99);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

#omarchy-search-card {
  width: 100%;
  background: var(--omarchy-card-bg);
  backdrop-filter: blur(28px) saturate(190%);
  -webkit-backdrop-filter: blur(28px) saturate(190%);
  border: 1px solid var(--omarchy-border);
  border-radius: 16px;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.42), 0 0 0 1px var(--omarchy-border);
  overflow: hidden;
  transition: border-color 0.18s ease, box-shadow 0.18s ease;
}

#omarchy-search-card:focus-within {
  border-color: var(--omarchy-accent);
  box-shadow:
    0 0 0 2px color-mix(in srgb, var(--omarchy-accent) 40%, transparent),
    0 24px 60px rgba(0, 0, 0, 0.52);
}

/* --- Search Input Row --- */

#omarchy-search-bar {
  display: flex;
  align-items: center;
  padding: 14px 18px;
  border-bottom: 1px solid var(--omarchy-border);
  gap: 12px;
}

.search-icon-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--omarchy-fg);
  opacity: 0.75;
  flex-shrink: 0;
}

#omarchy-search-input {
  flex: 1;
  background: transparent;
  border: none;
  outline: none;
  font-size: 15.5px;
  font-weight: 500;
  color: var(--omarchy-fg);
  caret-color: var(--omarchy-accent);
  padding: 0;
  margin: 0;
  user-select: text;
}

#omarchy-search-input::placeholder {
  color: var(--omarchy-muted);
  opacity: 0.85;
}

.search-clear-btn {
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 4px;
  border-radius: 6px;
  color: var(--omarchy-muted);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.12s ease, color 0.12s ease;
  flex-shrink: 0;
}

.search-clear-btn:hover {
  background-color: var(--omarchy-surface-hover);
  color: var(--omarchy-fg);
}

/* --- Results / Quick Access Container --- */

#omarchy-results-container {
  padding: 6px 8px 8px 8px;
  max-height: 420px;
  overflow-y: auto;
}

#omarchy-results-container::-webkit-scrollbar {
  width: 6px;
}

#omarchy-results-container::-webkit-scrollbar-thumb {
  background: var(--omarchy-border);
  border-radius: 4px;
}

#omarchy-results-list {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

/* --- Row Styling (matches Zen's urlbarView-row) --- */

.omarchy-result-row {
  display: flex;
  align-items: center;
  padding: 8px 12px;
  border-radius: 8px;
  text-decoration: none;
  cursor: pointer;
  background: transparent;
  border-left: 3px solid transparent;
  transition: background-color 0.1s ease, border-left-color 0.1s ease;
  user-select: none;
  gap: 12px;
}

.omarchy-result-row:hover {
  background-color: var(--omarchy-surface-hover);
}

.omarchy-result-row.selected {
  background-color: var(--omarchy-surface-active);
  border-left-color: var(--omarchy-accent);
}

.omarchy-result-icon {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  background-color: var(--omarchy-surface);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: var(--omarchy-fg);
  overflow: hidden;
}

.omarchy-result-icon svg {
  width: 16px;
  height: 16px;
}

.omarchy-result-icon img {
  width: 16px;
  height: 16px;
  object-fit: contain;
}

.omarchy-result-content {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.omarchy-result-title {
  font-size: 14px;
  font-weight: 500;
  color: var(--omarchy-fg);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.omarchy-result-url {
  font-size: 12px;
  color: var(--omarchy-accent);
  opacity: 0.9;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.omarchy-result-tag {
  font-size: 11px;
  font-weight: 500;
  padding: 2px 8px;
  border-radius: 6px;
  background: var(--omarchy-surface);
  color: var(--omarchy-muted);
  border: 1px solid var(--omarchy-border);
  flex-shrink: 0;
}

.omarchy-result-row.selected .omarchy-result-tag {
  color: var(--omarchy-fg);
  border-color: color-mix(in srgb, var(--omarchy-accent) 40%, var(--omarchy-border));
}

/* --- Keyboard Hints Footer --- */

#omarchy-search-hints {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 16px 10px 16px;
  border-top: 1px solid var(--omarchy-border-subtle);
  font-size: 11px;
  color: var(--omarchy-muted);
  opacity: 0.8;
}

.hint-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.hint-item {
  display: flex;
  align-items: center;
  gap: 4px;
}

kbd {
  font-family: inherit;
  font-size: 10px;
  padding: 1px 5px;
  border-radius: 4px;
  background: var(--omarchy-surface);
  border: 1px solid var(--omarchy-border);
  color: var(--omarchy-fg);
}
