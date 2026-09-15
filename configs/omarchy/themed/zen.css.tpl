/* ==============================================================================
 * Omarchy Dynamic Theme for Zen Browser
 * ------------------------------------------------------------------------------
 * This stylesheet is compiled dynamically by Omarchy whenever the system theme
 * changes (via ~/.local/bin/omarchy-sync-zen / omarchy theme set).
 *
 * NOTE FOR AI AGENTS & DEVELOPERS:
 * - This file ONLY styles Zen Browser's Chrome (UI, tabs, sidebars, toolbars, URL bar).
 * - Webpage contents are strictly untouched.
 * - Variables are populated dynamically from the active Omarchy theme's colors.toml.
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

  /* --- Zen Browser Native Variables --- */
  --zen-primary-color: {{ accent }} !important;
  --zen-branding-bg: {{ background }} !important;
  --zen-branding-bg-reverse: {{ foreground }} !important;
  --zen-branding-dark: {{ background }} !important;
  --zen-branding-paper: {{ background }} !important;

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
  --zen-urlbar-background-base: {{ background }} !important;
  --zen-urlbar-background-transparent: color-mix(in srgb, {{ background }} 85%, transparent) !important;
  --zen-toolbar-element-bg: var(--omarchy-surface) !important;
  --zen-toolbar-element-bg-hover: var(--omarchy-surface-hover) !important;
  --zen-selected-bg: var(--omarchy-surface-active) !important;
  --zen-selected-color: {{ foreground }} !important;

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
  --toolbar-field-focus-background-color: var(--omarchy-surface-hover) !important;
  --toolbarbutton-icon-fill: {{ foreground }} !important;
  --toolbarbutton-hover-background: var(--omarchy-surface-hover) !important;
  --toolbarbutton-active-background: var(--omarchy-surface-active) !important;
  --lwt-text-color: {{ foreground }} !important;
  --toolbox-textcolor: {{ foreground }} !important;
  --toolbox-textcolor-inactive: var(--omarchy-muted) !important;
  --color-accent-primary: {{ accent }} !important;
  --button-background-color-primary: {{ accent }} !important;
  --button-primary-hover-bgcolor: color-mix(in srgb, {{ accent }} 85%, white 15%) !important;
  --button-primary-active-bgcolor: color-mix(in srgb, {{ accent }} 80%, black 20%) !important;
  --button-primary-color: {{ selection_foreground }} !important;

  /* Tab Selection & Badges */
  --tab-selected-textcolor: {{ foreground }} !important;
  --tab-selected-bgcolor: var(--omarchy-surface-active) !important;
  --tab-background-color-hover: var(--omarchy-surface-hover) !important;

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

/* Compact Mode Toolbar Background */
.zen-toolbar-background {
  background-color: {{ background }} !important;
  border: 1px solid var(--omarchy-border) !important;
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

/* ==============================================================================
   Search Section / Omnibox / Breakout URL Bar (Ctrl + T & Ctrl + L)
   ============================================================================== */

/* Normal / Inline URL Bar state */
#urlbar-container {
  color: {{ foreground }} !important;
}

#urlbar:not([breakout-extend]) .urlbar-background {
  background-color: var(--omarchy-surface) !important;
  border: 1px solid var(--omarchy-border) !important;
  box-shadow: none !important;
}

#urlbar:not([breakout-extend]):hover .urlbar-background {
  background-color: var(--omarchy-surface-hover) !important;
  border-color: color-mix(in srgb, {{ accent }} 40%, var(--omarchy-border)) !important;
}

#urlbar:not([breakout-extend])[focused="true"] .urlbar-background {
  background-color: var(--omarchy-surface) !important;
  border-color: {{ accent }} !important;
}

/* Extended / Opened Search Modal (triggered by Ctrl+T, Ctrl+L, or click) */
#urlbar[breakout-extend],
#urlbar[breakout],
#urlbar[open],
#urlbar[zen-floating-urlbar="true"] {
  color: {{ foreground }} !important;
}

/* Modal Card Background Canvas */
#urlbar[breakout-extend] .urlbar-background,
#urlbar[open] .urlbar-background,
#urlbar[zen-floating-urlbar="true"] .urlbar-background {
  background: color-mix(in srgb, {{ background }} 94%, {{ foreground }} 6%) !important;
  background-color: color-mix(in srgb, {{ background }} 94%, {{ foreground }} 6%) !important;
  border: 1px solid var(--omarchy-border) !important;
  border-radius: 14px !important;
  box-shadow: 0 16px 48px rgba(0, 0, 0, 0.45), 0 0 0 1px var(--omarchy-border) !important;
  outline: none !important;
}

#urlbar[breakout-extend]:hover .urlbar-background,
#urlbar[open]:hover .urlbar-background,
#urlbar[zen-floating-urlbar="true"]:hover .urlbar-background {
  border-color: color-mix(in srgb, {{ accent }} 40%, var(--omarchy-border)) !important;
}

#urlbar[breakout-extend][focused="true"] .urlbar-background,
#urlbar[open][focused="true"] .urlbar-background {
  border-color: {{ accent }} !important;
  box-shadow: 0 0 0 2px color-mix(in srgb, {{ accent }} 40%, transparent), 0 16px 48px rgba(0, 0, 0, 0.5) !important;
}

/* Search input container */
#urlbar[breakout-extend] #urlbar-input-container,
#urlbar[open] #urlbar-input-container {
  padding: 6px 12px !important;
  border-bottom: 1px solid var(--omarchy-border) !important;
}

/* Input element & placeholder */
#urlbar-input,
.urlbar-input {
  color: {{ foreground }} !important;
  font-size: 15px !important;
}

#urlbar-input::placeholder,
.urlbar-input::placeholder {
  color: var(--omarchy-muted) !important;
  opacity: 0.8 !important;
}

/* Search icons in input box */
#identity-box,
#identity-icon-box {
  color: {{ foreground }} !important;
  fill: {{ foreground }} !important;
}

#identity-icon-box:hover {
  background-color: var(--omarchy-surface-hover) !important;
}

/* Search mode indicator badge (e.g. Google, Tab search) */
#urlbar-search-mode-indicator,
#urlbar-label-box {
  background-color: {{ accent }} !important;
  color: {{ selection_foreground }} !important;
  border-radius: 6px !important;
  padding: 2px 8px !important;
}

#urlbar-search-mode-indicator-title {
  color: {{ selection_foreground }} !important;
  font-weight: 600 !important;
}

/* Results Dropdown View */
.urlbarView {
  background: transparent !important;
  background-color: transparent !important;
  color: {{ foreground }} !important;
  border: none !important;
  box-shadow: none !important;
  padding: 4px 6px !important;
}

.urlbarView-body-outer,
.urlbarView-body-inner {
  background: transparent !important;
}

#urlbar-results {
  padding: 4px 0 !important;
}

/* Search Result Rows */
.urlbarView-row {
  color: {{ foreground }} !important;
  border-radius: 8px !important;
  margin: 2px 0 !important;
  padding: 6px 10px !important;
  transition: background-color 0.12s ease !important;
  background-color: transparent !important;
}

.urlbarView-row:hover {
  background-color: var(--omarchy-surface-hover) !important;
  color: {{ foreground }} !important;
}

.urlbarView-row[selected] {
  background-color: var(--omarchy-surface-active) !important;
  border-left: 3px solid {{ accent }} !important;
  color: {{ foreground }} !important;
}

/* Row Content Typography & Icons */
.urlbarView-row[selected] .urlbarView-title,
.urlbarView-row[selected] .urlbarView-title-separator::before {
  color: {{ foreground }} !important;
}

.urlbarView-title {
  color: {{ foreground }} !important;
  font-size: 14px !important;
  font-weight: 500 !important;
}

.urlbarView-title-separator::before {
  color: var(--omarchy-muted) !important;
  opacity: 0.6 !important;
}

.urlbarView-url {
  color: {{ accent }} !important;
  font-size: 13px !important;
  opacity: 0.9 !important;
}

.urlbarView-action {
  color: var(--omarchy-muted) !important;
  font-size: 13px !important;
}

.urlbarView-favicon {
  border-radius: 4px !important;
  fill: {{ foreground }} !important;
}

.urlbarView-shortcutContent {
  background-color: var(--omarchy-surface) !important;
  color: {{ foreground }} !important;
  border: 1px solid var(--omarchy-border) !important;
  border-radius: 4px !important;
}

/* Bottom search engine buttons */
.search-panel-one-offs-container {
  border-top: 1px solid var(--omarchy-border) !important;
  background: transparent !important;
  padding-block: 4px !important;
}

.searchbar-engine-one-off-item {
  color: {{ foreground }} !important;
  fill: {{ foreground }} !important;
  border-radius: 6px !important;
}

.searchbar-engine-one-off-item:hover {
  background-color: var(--omarchy-surface-hover) !important;
}

/* ==============================================================================
   Tabs & Navigation
   ============================================================================== */

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

/* ==============================================================================
   Sidebar & Workspaces
   ============================================================================== */

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

/* ==============================================================================
   Findbar, Toasts & Dialogs
   ============================================================================== */

findbar {
  background-color: {{ background }} !important;
  color: {{ foreground }} !important;
  border-top: 1px solid var(--omarchy-border) !important;
}

#zen-toast-container {
  background-color: var(--omarchy-surface) !important;
  color: {{ foreground }} !important;
  border: 1px solid var(--omarchy-border) !important;
}
