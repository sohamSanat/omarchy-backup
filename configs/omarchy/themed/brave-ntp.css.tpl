/* ==============================================================================
 * Omarchy Dynamic Theme for Brave-Origin New Tab Page
 * ------------------------------------------------------------------------------
 * Template: ~/.config/omarchy/themed/brave-ntp.css.tpl
 * Compiled to: ~/.local/state/omarchy/current/theme/brave-ntp.css
 * Consumed by: ~/.config/omarchy/brave-polish/ntp.html (companion MV3 ext)
 *
 * NOTE: Brave window stays fully opaque (no compositor transparency).
 * Glass effect here is pure CSS backdrop-filter over the theme background,
 * so loaded websites are never affected.
 * ============================================================================== */

:root {
  --omarchy-bg: {{ background }};
  --omarchy-fg: {{ foreground }};
  --omarchy-accent: {{ accent }};
  --omarchy-muted: {{ muted }};
  --omarchy-surface: color-mix(in srgb, {{ foreground }} 8%, {{ background }});
  --omarchy-surface-hover: color-mix(in srgb, {{ foreground }} 15%, {{ background }});
  --omarchy-border: color-mix(in srgb, {{ foreground }} 18%, transparent);
}

* { box-sizing: border-box; }

/* Footer guard: Brave-Origin injects an attribution footer
 * ("extension name" + Customize button) into extension NTPs.
 * Only Omarchy's own elements may render. */
body > :not(.omarchy-clock):not(.omarchy-date):not(.omarchy-search):not(.omarchy-topsites):not(script):not(style):not(link) {
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
  /* Solid theme canvas: the window is fully opaque (website readability
   * first). Cards keep their frosted-glass styling on top of it. */
  background: {{ background }} !important;
  background-color: {{ background }} !important;
  color: {{ foreground }} !important;
  font-family: "Inter", "Segoe UI", system-ui, -apple-system, sans-serif;
}

body {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 28px;
  overflow-x: hidden;
  /* Subtle accent glows over the solid theme background. */
  background-image:
    radial-gradient(60% 50% at 50% 0%, color-mix(in srgb, {{ accent }} 20%, transparent), transparent 70%),
    radial-gradient(40% 35% at 85% 90%, color-mix(in srgb, {{ accent }} 10%, transparent), transparent 70%);
}

.omarchy-clock {
  font-size: 64px;
  font-weight: 200;
  letter-spacing: 0.04em;
  color: {{ foreground }};
  text-shadow: 0 2px 18px rgba(0, 0, 0, 0.35);
}

.omarchy-date {
  margin-top: -20px;
  font-size: 15px;
  color: color-mix(in srgb, {{ foreground }} 70%, transparent);
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.omarchy-search {
  width: min(560px, 86vw);
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 13px 18px;
  border-radius: 14px;
  background: color-mix(in srgb, {{ background }} 62%, transparent);
  border: 1px solid var(--omarchy-border);
  backdrop-filter: blur(20px) saturate(140%);
  -webkit-backdrop-filter: blur(20px) saturate(140%);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.35), inset 0 1px 0 rgba(255, 255, 255, 0.1);
}

.omarchy-search:focus-within {
  border-color: {{ accent }};
  box-shadow: 0 0 0 2px color-mix(in srgb, {{ accent }} 40%, transparent), 0 12px 36px rgba(0, 0, 0, 0.45);
}

.omarchy-search input {
  flex: 1;
  background: transparent;
  border: none;
  outline: none;
  font-size: 16px;
  color: {{ foreground }};
}

.omarchy-search input::placeholder {
  color: color-mix(in srgb, {{ foreground }} 55%, transparent);
}

.omarchy-search .search-icon {
  color: {{ accent }};
  font-size: 17px;
}

.omarchy-topsites {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 14px;
  width: min(560px, 86vw);
}

.omarchy-top {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  min-width: 0;
  padding: 16px 8px 12px;
  border-radius: 12px;
  text-decoration: none;
  background: color-mix(in srgb, {{ background }} 60%, transparent);
  border: 1px solid color-mix(in srgb, {{ foreground }} 14%, transparent);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.25);
  transition: transform 0.15s ease, border-color 0.15s ease;
}

.omarchy-top:hover {
  border-color: {{ accent }};
  transform: translateY(-2px);
}

.omarchy-top img {
  width: 28px;
  height: 28px;
  border-radius: 6px;
}

.omarchy-top .tile-letter {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 15px;
  background: color-mix(in srgb, {{ accent }} 25%, {{ background }});
  color: {{ foreground }};
}

.omarchy-top span {
  font-size: 12px;
  color: {{ foreground }};
  max-width: 100%;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
