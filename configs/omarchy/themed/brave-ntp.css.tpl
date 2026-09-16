/* ==============================================================================
 * Omarchy Dynamic Theme for Brave-Origin New Tab Page
 * ------------------------------------------------------------------------------
 * Template: ~/.config/omarchy/themed/brave-ntp.css.tpl
 * Compiled to: ~/.local/state/omarchy/current/theme/brave-ntp.css
 * Consumed by: ~/.config/omarchy/brave-polish/ntp.html
 * ============================================================================== */

:root {
  --omarchy-bg: {{ background }};
  --omarchy-fg: {{ foreground }};
  --omarchy-accent: {{ accent }};
  --omarchy-muted: {{ muted }};
  
  --omarchy-surface: color-mix(in srgb, {{ foreground }} 7%, {{ background }});
  --omarchy-surface-hover: color-mix(in srgb, {{ foreground }} 14%, {{ background }});
  --omarchy-surface-active: color-mix(in srgb, {{ foreground }} 22%, {{ background }});
  --omarchy-border: color-mix(in srgb, {{ foreground }} 16%, transparent);
  --omarchy-border-hover: color-mix(in srgb, {{ accent }} 45%, var(--omarchy-border));
  --omarchy-accent-subtle: color-mix(in srgb, {{ accent }} 22%, transparent);
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  -webkit-font-smoothing: antialiased;
}

html, body {
  width: 100%;
  height: 100vh;
  overflow: hidden;
  background-color: var(--omarchy-bg) !important;
  color: var(--omarchy-fg);
  font-family: "Inter", "Segoe UI", system-ui, -apple-system, sans-serif;
  user-select: none;
}

body {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: center;
  padding: 24px 32px;
  background-image:
    radial-gradient(ellipse 75% 65% at 50% 15%, color-mix(in srgb, var(--omarchy-accent) 18%, transparent), transparent 75%),
    radial-gradient(ellipse 60% 50% at 85% 85%, color-mix(in srgb, var(--omarchy-fg) 12%, transparent), transparent 70%);
  background-attachment: fixed;
}

/* --- Top Header Navigation Bar --- */
.ntp-header {
  width: 100%;
  max-width: 1200px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  animation: fadeIn 0.4s ease-out;
}

.ntp-badge-space {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  border-radius: 8px;
  background: var(--omarchy-accent-subtle);
  border: 1px solid color-mix(in srgb, var(--omarchy-accent) 40%, transparent);
  color: var(--omarchy-accent);
  font-weight: 700;
  font-size: 15px;
  letter-spacing: 0.5px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.25);
  transition: transform 0.15s ease, background 0.15s ease;
}

.ntp-badge-space:hover {
  transform: scale(1.05);
  background: color-mix(in srgb, var(--omarchy-accent) 35%, transparent);
}

.ntp-header-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.ntp-pill-theme {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 14px;
  border-radius: 20px;
  background: var(--omarchy-surface);
  border: 1px solid var(--omarchy-border);
  font-size: 12px;
  font-weight: 500;
  color: var(--omarchy-fg);
  letter-spacing: 0.3px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

.ntp-pill-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--omarchy-accent);
  box-shadow: 0 0 8px var(--omarchy-accent);
  animation: pulseDot 2.5s infinite ease-in-out;
}

.ntp-pill-clock {
  padding: 6px 12px;
  border-radius: 20px;
  background: var(--omarchy-surface);
  border: 1px solid var(--omarchy-border);
  font-size: 12px;
  font-weight: 600;
  color: var(--omarchy-fg);
  font-variant-numeric: tabular-nums;
}

/* --- Center Search & Launchpad --- */
.ntp-center {
  width: 100%;
  max-width: 680px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 36px;
  margin-top: -40px;
  animation: slideUp 0.45s cubic-bezier(0.16, 1, 0.3, 1);
}

/* Zen-Style Search Pill */
.search-container {
  width: 100%;
  position: relative;
}

.search-bar {
  width: 100%;
  height: 54px;
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 0 20px;
  background: var(--omarchy-surface);
  border: 1px solid var(--omarchy-border);
  border-radius: 27px;
  box-shadow: 0 12px 36px rgba(0, 0, 0, 0.45), 0 0 0 1px var(--omarchy-border);
  transition: all 0.22s cubic-bezier(0.16, 1, 0.3, 1);
}

.search-bar:hover {
  background: var(--omarchy-surface-hover);
  border-color: var(--omarchy-border-hover);
  box-shadow: 0 16px 44px rgba(0, 0, 0, 0.55), 0 0 0 1px var(--omarchy-border-hover);
}

.search-bar:focus-within {
  background: color-mix(in srgb, var(--omarchy-bg) 92%, var(--omarchy-fg) 8%);
  border-color: var(--omarchy-accent);
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--omarchy-accent) 35%, transparent), 0 20px 52px rgba(0, 0, 0, 0.65);
  transform: translateY(-1px);
}

.search-icon {
  width: 20px;
  height: 20px;
  fill: var(--omarchy-fg);
  opacity: 0.85;
  flex-shrink: 0;
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.search-bar:focus-within .search-icon {
  opacity: 1;
  fill: var(--omarchy-accent);
  transform: scale(1.05);
}

.search-input {
  width: 100%;
  height: 100%;
  background: transparent;
  border: none;
  outline: none;
  font-size: 16px;
  color: var(--omarchy-fg);
  font-family: inherit;
  font-weight: 500;
}

.search-input::placeholder {
  color: var(--omarchy-accent);
  opacity: 0.9;
  font-weight: 400;
  transition: opacity 0.2s ease;
}

.search-input:focus::placeholder {
  opacity: 0.45;
}

/* --- Quick Launch Shortcuts --- */
.shortcuts-grid {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  flex-wrap: wrap;
}

.shortcut-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  padding: 14px 18px;
  min-width: 90px;
  background: var(--omarchy-surface);
  border: 1px solid var(--omarchy-border);
  border-radius: 16px;
  text-decoration: none;
  color: var(--omarchy-fg);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.25);
  transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
  cursor: pointer;
}

.shortcut-card:hover {
  transform: translateY(-3px);
  background: var(--omarchy-surface-hover);
  border-color: var(--omarchy-border-hover);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.4), 0 0 0 1px var(--omarchy-border-hover);
}

.shortcut-card:active {
  transform: translateY(-1px);
  background: var(--omarchy-surface-active);
}

.shortcut-icon-wrapper {
  width: 42px;
  height: 42px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: color-mix(in srgb, var(--omarchy-bg) 70%, transparent);
  border: 1px solid var(--omarchy-border);
  transition: transform 0.2s ease;
}

.shortcut-card:hover .shortcut-icon-wrapper {
  transform: scale(1.08);
}

.shortcut-icon-wrapper svg {
  width: 22px;
  height: 22px;
}

.shortcut-label {
  font-size: 13px;
  font-weight: 500;
  letter-spacing: 0.2px;
  opacity: 0.9;
  transition: opacity 0.2s ease, color 0.2s ease;
}

.shortcut-card:hover .shortcut-label {
  opacity: 1;
  color: var(--omarchy-accent);
}

/* Footer info */
.ntp-footer {
  font-size: 11px;
  color: var(--omarchy-muted);
  opacity: 0.6;
  letter-spacing: 0.5px;
  text-align: center;
}

/* Animations */
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideUp {
  from { opacity: 0; transform: translateY(16px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes pulseDot {
  0%, 100% { opacity: 0.8; transform: scale(1); }
  50% { opacity: 1; transform: scale(1.3); }
}
