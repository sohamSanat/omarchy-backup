/* ==============================================================================
 * Omarchy Dynamic Theme for Zen Browser
 * ------------------------------------------------------------------------------
 * This stylesheet is compiled dynamically by Omarchy whenever the system theme
 * changes (via ~/.local/bin/omarchy-sync-zen / omarchy theme set).
 *
 * NOTE FOR AI AGENTS & DEVELOPERS:
 * - This file ONLY styles Zen Browser's Chrome (UI, tabs, sidebars, toolbars, URL bar).
 * - Webpage contents are strictly untouched.
 * - Variables are populated from the active Omarchy theme's colors.toml.
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
  --omarchy-surface: color-mix(in srgb, {{ foreground }} 6%, {{ background }});
  --omarchy-surface-hover: color-mix(in srgb, {{ foreground }} 12%, {{ background }});
  --omarchy-surface-active: color-mix(in srgb, {{ foreground }} 18%, {{ background }});
  --omarchy-border: color-mix(in srgb, {{ foreground }} 15%, transparent);

  /* --- Zen Browser Native Variables --- */
  --zen-primary-color: {{ accent }} !important;
  --zen-branding-bg: {{ background }} !important;
  --zen-branding-bg-reverse: {{ foreground }} !important;

  --zen-colors-primary: var(--omarchy-surface) !important;
  --zen-colors-secondary: var(--omarchy-surface-hover) !important;
  --zen-colors-tertiary: {{ background }} !important;
  --zen-colors-hover-bg: var(--omarchy-surface-hover) !important;
  --zen-colors-primary-foreground: {{ foreground }} !important;
  --zen-colors-border: var(--omarchy-border) !important;
  --zen-colors-border-contrast: {{ accent }} !important;
  --zen-colors-input-bg: var(--omarchy-surface) !important;

  --zen-dialog-background: {{ background }} !important;
  --zen-urlbar-background: var(--omarchy-surface) !important;
  --zen-toolbar-element-bg: var(--omarchy-surface) !important;
  --zen-toolbar-element-bg-hover: var(--omarchy-surface-hover) !important;

  /* Main Browser & Toolbar Canvas */
  --zen-main-browser-background: transparent !important;
  --zen-background-opacity: 0 !important;
  --zen-main-browser-background-toolbar: {{ background }} !important;
  --zen-themed-toolbar-bg: {{ background }} !important;
  --zen-themed-toolbar-bg-transparent: transparent !important;
  --zen-navigator-toolbox-background: {{ background }} !important;
  --toolbox-bgcolor-inactive: {{ background }} !important;

  /* Firefox / Gecko Chrome Tokens */
  --toolbar-bgcolor: {{ background }} !important;
  --toolbar-color: {{ foreground }} !important;
  --toolbar-field-color: {{ foreground }} !important;
  --toolbar-field-focus-color: {{ foreground }} !important;
  --toolbar-field-background-color: var(--omarchy-surface) !important;
  --toolbarbutton-icon-fill: {{ foreground }} !important;
  --toolbarbutton-hover-background: var(--omarchy-surface-hover) !important;
  --toolbarbutton-active-background: var(--omarchy-surface-active) !important;
  --lwt-text-color: {{ foreground }} !important;
  --toolbox-textcolor: {{ foreground }} !important;

  /* Tab Selection & Badges */
  --tab-selected-textcolor: {{ foreground }} !important;
  --tab-selected-bgcolor: var(--omarchy-surface-active) !important;
  --tab-background-color-hover: var(--omarchy-surface-hover) !important;
  --zen-selected-bg: var(--omarchy-surface-active) !important;
  --zen-selected-color: {{ foreground }} !important;

  /* Sidebar Tokens */
  --sidebar-background-color: {{ background }} !important;
  --sidebar-text-color: {{ foreground }} !important;
  --lwt-sidebar-background-color: {{ background }} !important;
  --lwt-sidebar-text-color: {{ foreground }} !important;

  /* Popups, Panels, Dialogs */
  --arrowpanel-background: {{ background }} !important;
  --arrowpanel-color: {{ foreground }} !important;
  --arrowpanel-border-color: var(--omarchy-border) !important;
  --panel-separator-color: var(--omarchy-border) !important;

  /* Split views & focus outlines */
  --zen-active-split-outline-color: {{ accent }} !important;
}

/* ==============================================================================
   UI Element Overrides (Browser Chrome Only)
   ============================================================================== */

/* Window Canvas & Default Tab Glass Transparency:
 * The window and tab container are transparent so the desktop wallpaper with
 * Hyprland's dual-pass blur bleeds through when no website is open (default tab).
 * When any website is loaded, web content remains 100% solid, crisp, and readable. */
#main-window,
#zen-main-app-wrapper,
#browser,
#tabbrowser-tabbox,
#tabbrowser-tabpanels,
.browserSidebarContainer,
.browserContainer,
browser[type="content"][transparent="true"] {
  background: transparent !important;
  background-color: transparent !important;
}

/* Neutralize Zen's built-in background gradient overlay to reveal blur */
.zen-browser-generic-background {
  background: transparent !important;
}

.zen-browser-generic-background::after {
  background: transparent !important;
  opacity: 0 !important;
}

.zen-browser-generic-background::before {
  display: none !important;
}

/* Toolbars, Tab Strip & Header */
#navigator-toolbox,
#TabsToolbar,
#nav-bar,
#zen-appcontent-navbar-container,
#PersonalToolbar,
hbox#titlebar {
  background-color: {{ background }} !important;
  color: {{ foreground }} !important;
  border-color: var(--omarchy-border) !important;
}

/* Toolbar Buttons & Icons */
toolbarbutton {
  color: {{ foreground }} !important;
}

.toolbarbutton-1:hover {
  background-color: var(--omarchy-surface-hover) !important;
}

.toolbarbutton-icon {
  fill: {{ foreground }} !important;
}

/* URL Bar / Omnibox Styling */
#urlbar-container {
  color: {{ foreground }} !important;
}

.urlbar-background {
  background-color: var(--omarchy-surface) !important;
  border: 1px solid var(--omarchy-border) !important;
  box-shadow: none !important;
}

#urlbar:not([breakout-extend]):hover .urlbar-background {
  background-color: var(--omarchy-surface-hover) !important;
  border-color: color-mix(in srgb, {{ accent }} 40%, var(--omarchy-border)) !important;
}

#urlbar[focused="true"] .urlbar-background {
  background-color: var(--omarchy-surface) !important;
  border-color: {{ accent }} !important;
}

/* Centered / Floating Search Bar on Empty & New Tabs (Frosted Glass Card) */
#urlbar[zen-floating-urlbar="true"] .urlbar-background,
#urlbar[breakout-extend][zen-floating-urlbar="true"] .urlbar-background {
  background: color-mix(in srgb, {{ background }} 75%, transparent) !important;
  backdrop-filter: blur(24px) saturate(140%) !important;
  -webkit-backdrop-filter: blur(24px) saturate(140%) !important;
  border: 1px solid color-mix(in srgb, {{ foreground }} 18%, transparent) !important;
  box-shadow: 0 12px 36px 0 rgba(0, 0, 0, 0.4), inset 0 1px 0 0 rgba(255, 255, 255, 0.12) !important;
  border-radius: 14px !important;
}

#urlbar[zen-floating-urlbar="true"]:hover .urlbar-background {
  background: color-mix(in srgb, {{ background }} 65%, transparent) !important;
  border-color: color-mix(in srgb, {{ foreground }} 28%, transparent) !important;
}

#urlbar[zen-floating-urlbar="true"][focused="true"] .urlbar-background {
  background: color-mix(in srgb, {{ background }} 80%, transparent) !important;
  border-color: {{ accent }} !important;
  box-shadow: 0 0 0 2px color-mix(in srgb, {{ accent }} 40%, transparent), 0 16px 40px 0 rgba(0, 0, 0, 0.5) !important;
}

.urlbar-input {
  color: {{ foreground }} !important;
}

.urlbar-input::placeholder {
  color: color-mix(in srgb, {{ foreground }} 60%, transparent) !important;
  opacity: 1 !important;
}

.urlbarView {
  background-color: {{ background }} !important;
  color: {{ foreground }} !important;
  border-color: var(--omarchy-border) !important;
}

.urlbarView-url {
  color: {{ accent }} !important;
}

/* Tab Bar items */
.tabbrowser-tab {
  color: {{ foreground }} !important;
}

.tabbrowser-tab:hover:not([selected]) .tab-background {
  background-color: var(--omarchy-surface-hover) !important;
}

.tabbrowser-tab[selected] .tab-background,
.tabbrowser-tab[visuallyselected] .tab-background,
.tabbrowser-tab[multiselected] .tab-background {
  background-color: var(--omarchy-surface-active) !important;
  border-left: 3px solid {{ accent }} !important;
  box-shadow: none !important;
}

.tabbrowser-tab[selected] .tab-label {
  color: {{ foreground }} !important;
  font-weight: 600 !important;
}

/* New Tab Button */
#tabs-newtab-button,
#vertical-tabs-newtab-button,
#new-tab-button {
  background-color: var(--omarchy-surface) !important;
  color: {{ foreground }} !important;
  fill: {{ foreground }} !important;
  box-shadow: none !important;
}

#tabs-newtab-button:hover,
#vertical-tabs-newtab-button:hover,
#new-tab-button:hover {
  background-color: var(--omarchy-surface-hover) !important;
  color: {{ accent }} !important;
  fill: {{ accent }} !important;
}

/* Close Tab Button */
.tab-close-button {
  color: {{ foreground }} !important;
  fill: {{ foreground }} !important;
}

.tab-close-button:hover {
  background-color: color-mix(in srgb, {{ red }} 25%, transparent) !important;
  color: {{ red }} !important;
  fill: {{ red }} !important;
}

/* Sidebar & Tabs Area */
#sidebar-box,
#sidebar-header,
.sidebar-placesTree,
#zen-tabs-wrapper,
#zen-tabbox-wrapper,
#zen-sidebar-top-buttons,
#zen-sidebar-foot-buttons {
  background-color: {{ background }} !important;
  color: {{ foreground }} !important;
}

#zen-sidebar-top-buttons toolbarbutton,
#zen-sidebar-foot-buttons toolbarbutton {
  color: {{ foreground }} !important;
  fill: {{ foreground }} !important;
}

#zen-sidebar-top-buttons toolbarbutton:hover,
#zen-sidebar-foot-buttons toolbarbutton:hover {
  background-color: var(--omarchy-surface-hover) !important;
  color: {{ accent }} !important;
  fill: {{ accent }} !important;
}

/* Workspace switcher */
#zen-workspaces-button {
  background-color: var(--omarchy-surface) !important;
  color: {{ foreground }} !important;
  border: 1px solid var(--omarchy-border) !important;
}

#zen-workspaces-button:hover {
  background-color: var(--omarchy-surface-hover) !important;
  border-color: {{ accent }} !important;
}

.zen-current-workspace-indicator {
  background-color: {{ accent }} !important;
}

/* Findbar */
findbar {
  background-color: {{ background }} !important;
  color: {{ foreground }} !important;
  border-top: 1px solid var(--omarchy-border) !important;
}

/* Toast Notifications */
#zen-toast-container {
  background-color: var(--omarchy-surface) !important;
  color: {{ foreground }} !important;
  border: 1px solid var(--omarchy-border) !important;
}
