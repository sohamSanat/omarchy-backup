/* ==============================================================================
 * Omarchy Dynamic Theme for Dark Reader Extension
 * ------------------------------------------------------------------------------
 * Managed dynamically by Omarchy Linux & ~/.local/bin/omarchy-sync-zen.
 * Template: ~/.config/omarchy/themed/zen-darkreader.css.tpl
 * Target:   ~/.local/state/omarchy/current/theme/zen-darkreader.css
 * ============================================================================== */

:root {
  /* Omarchy System Theme Tokens */
  --omarchy-bg: {{ background }};
  --omarchy-fg: {{ foreground }};
  --omarchy-accent: {{ accent }};
  --omarchy-muted: {{ muted }};
  --omarchy-selection-bg: {{ selection_background }};
  --omarchy-selection-fg: {{ selection_foreground }};

  /* Surfaces & Interactivity */
  --omarchy-surface: color-mix(in srgb, {{ foreground }} 8%, {{ background }});
  --omarchy-surface-hover: color-mix(in srgb, {{ foreground }} 15%, {{ background }});
  --omarchy-surface-active: color-mix(in srgb, {{ foreground }} 22%, {{ background }});
  --omarchy-border: color-mix(in srgb, {{ foreground }} 20%, transparent);
}

/* Omarchy Toggle Button in Dark Reader Popup */
.omarchy-toggle-btn {
  align-items: center;
  background-color: color-mix(in srgb, {{ accent }} 12%, #141e24);
  border: 0.125rem solid var(--omarchy-accent, {{ accent }});
  border-radius: 0.25rem;
  box-sizing: border-box;
  color: #ffffff;
  cursor: pointer;
  display: block;
  height: 1.75rem;
  min-height: 1.75rem;
  outline: none;
  overflow: hidden;
  padding: 0;
  position: relative;
  text-align: center;
  transition: background-color 150ms ease, border-color 150ms ease, box-shadow 150ms ease, color 150ms ease;
  user-select: none;
  -moz-user-select: none;
  width: 100%;
}

.omarchy-toggle-btn:hover {
  background-color: color-mix(in srgb, var(--omarchy-accent, {{ accent }}) 25%, #141e24);
  border-color: var(--omarchy-accent, {{ accent }});
  box-shadow: 0 0 8px color-mix(in srgb, var(--omarchy-accent, {{ accent }}) 35%, transparent);
}

.omarchy-toggle-btn .button__wrapper {
  align-items: center;
  display: flex !important;
  flex-direction: row;
  gap: 0.5rem;
  height: 100%;
  justify-content: center;
  line-height: 1;
  width: 100%;
}

.omarchy-toggle-btn__text {
  color: #ffffff;
  font-family: inherit;
  font-size: 0.75rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  line-height: 1;
  text-transform: lowercase;
}

.omarchy-toggle-btn__indicator {
  background-color: color-mix(in srgb, #ffffff 40%, transparent);
  border: 1px solid color-mix(in srgb, var(--omarchy-accent, {{ accent }}) 60%, transparent);
  border-radius: 50%;
  display: inline-block;
  flex-shrink: 0;
  height: 0.5rem;
  width: 0.5rem;
  transition: background-color 150ms ease, box-shadow 150ms ease, transform 150ms ease;
}

/* Active / Toggled State */
.omarchy-toggle-btn:active,
.omarchy-toggle-btn.omarchy-toggle-btn--active {
  background-color: var(--omarchy-accent, {{ accent }}) !important;
  border-color: var(--omarchy-accent, {{ accent }}) !important;
  box-shadow: 0 0 12px color-mix(in srgb, var(--omarchy-accent, {{ accent }}) 50%, transparent);
  color: #ffffff !important;
}

.omarchy-toggle-btn.omarchy-toggle-btn--active .omarchy-toggle-btn__text {
  color: #ffffff !important;
}

.omarchy-toggle-btn.omarchy-toggle-btn--active .omarchy-toggle-btn__indicator {
  background-color: #ffffff !important;
  border-color: #ffffff !important;
  box-shadow: 0 0 6px #ffffff;
  transform: scale(1.15);
}
