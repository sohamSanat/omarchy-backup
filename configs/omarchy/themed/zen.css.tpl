/* Omarchy Dynamic Theme for Zen Browser */
/* Auto-generated from active Omarchy system theme */

:root,
#main-window,
body {
  /* Core Palette */
  --zen-omarchy-bg: {{ background }};
  --zen-omarchy-bg-dark: {{ dark_background }};
  --zen-omarchy-bg-darker: {{ darker_background }};
  --zen-omarchy-bg-lighter: {{ lighter_background }};
  --zen-omarchy-fg: {{ foreground }};
  --zen-omarchy-fg-bright: {{ bright_foreground }};
  --zen-omarchy-fg-dark: {{ dark_foreground }};
  --zen-omarchy-fg-light: {{ light_foreground }};
  --zen-omarchy-accent: {{ accent }};
  --zen-omarchy-selection-bg: {{ selection_background }};
  --zen-omarchy-selection-fg: {{ selection_foreground }};
  --zen-omarchy-muted: {{ muted }};
  --zen-omarchy-red: {{ red }};
  --zen-omarchy-green: {{ green }};
  --zen-omarchy-yellow: {{ yellow }};
  --zen-omarchy-blue: {{ blue }};
  --zen-omarchy-magenta: {{ magenta }};
  --zen-omarchy-cyan: {{ cyan }};

  /* Zen Browser Custom Properties */
  --zen-primary-color: {{ accent }} !important;
  --zen-branding-dark: {{ dark_background }} !important;
  --zen-branding-paper: {{ light_foreground }} !important;
  --zen-branding-bg: {{ background }} !important;
  --zen-branding-bg-reverse: {{ bright_foreground }} !important;

  --zen-colors-primary: {{ accent }} !important;
  --zen-colors-secondary: {{ lighter_background }} !important;
  --zen-colors-tertiary: {{ dark_background }} !important;
  --zen-colors-hover-bg: {{ selection_background }} !important;
  --zen-colors-primary-foreground: {{ selection_foreground }} !important;
  --zen-colors-border: {{ muted }} !important;
  --zen-colors-border-contrast: color-mix(in srgb, {{ muted }} 80%, transparent) !important;
  --zen-colors-input-bg: {{ lighter_background }} !important;

  --zen-main-browser-background: transparent !important;
  --zen-main-browser-background-toolbar: {{ background }} !important;
  --zen-themed-toolbar-bg-transparent: transparent !important;
  --zen-dialog-background: {{ dark_background }} !important;
  --zen-in-content-dialog-background: {{ background }} !important;
  --zen-urlbar-background: {{ lighter_background }} !important;

  --zen-sidebar-notification-bg: {{ accent }} !important;
  --zen-sidebar-notification-shadow: 0 0 8px color-mix(in srgb, {{ accent }} 40%, transparent) !important;
  --zen-sidebar-themed-icon-fill: {{ accent }} !important;
  --zen-split-view-active-tab-bg: {{ lighter_background }} !important;
  --zen-theme-picker-dot-color: {{ accent }} !important;
  --zen-loading-progress-bar-color: {{ accent }} !important;

  /* Standard Firefox Chrome Theme Variables */
  --toolbar-bgcolor: {{ background }} !important;
  --toolbar-color: {{ foreground }} !important;
  --toolbarbutton-hover-background: {{ selection_background }} !important;
  --toolbarbutton-active-background: color-mix(in srgb, {{ accent }} 30%, transparent) !important;
  --toolbarbutton-border-radius: 6px !important;

  --tab-selected-bgcolor: {{ lighter_background }} !important;
  --tab-selected-textcolor: {{ bright_foreground }} !important;
  --tab-background-color-hover: {{ selection_background }} !important;

  --toolbar-field-background-color: {{ lighter_background }} !important;
  --toolbar-field-color: {{ foreground }} !important;
  --toolbar-field-focus-background-color: {{ lighter_background }} !important;
  --toolbar-field-focus-color: {{ bright_foreground }} !important;
  --toolbar-field-border-color: {{ muted }} !important;

  --arrowpanel-background: {{ dark_background }} !important;
  --arrowpanel-color: {{ foreground }} !important;
  --arrowpanel-border-color: {{ muted }} !important;
  --panel-separator-color: {{ muted }} !important;

  --autocomplete-popup-background: {{ dark_background }} !important;
  --autocomplete-popup-color: {{ foreground }} !important;
  --autocomplete-popup-hover-background: {{ selection_background }} !important;

  --sidebar-background-color: {{ dark_background }} !important;
  --sidebar-text-color: {{ foreground }} !important;
  --sidebar-border-color: {{ muted }} !important;

  --lwt-sidebar-background-color: {{ dark_background }} !important;
  --lwt-sidebar-text-color: {{ foreground }} !important;

  /* In-Content UI / Settings */
  --in-content-page-background: {{ background }} !important;
  --in-content-page-color: {{ foreground }} !important;
  --in-content-box-background: {{ dark_background }} !important;
  --in-content-box-border-color: {{ muted }} !important;
  --in-content-button-background: {{ lighter_background }} !important;
  --in-content-button-background-hover: {{ selection_background }} !important;
  --in-content-button-background-active: {{ accent }} !important;
  --in-content-primary-button-background: {{ accent }} !important;
  --in-content-primary-button-text-color: {{ selection_foreground }} !important;
  --in-content-primary-button-background-hover: color-mix(in srgb, {{ accent }} 85%, white 15%) !important;

  /* New Tab Page */
  --newtab-background-color: transparent !important;
  --newtab-text-primary-color: {{ foreground }} !important;
  --newtab-text-secondary-color: {{ dark_foreground }} !important;
  --newtab-primary-action-background: {{ accent }} !important;
  --newtab-element-hover-color: {{ selection_background }} !important;
  --newtab-card-background-color: color-mix(in srgb, {{ dark_background }} 60%, transparent) !important;
}

/* Browser Window & Main Containers */
#browser,
#zen-tabbox-wrapper,
#tabbrowser-tabbox,
#tabbrowser-tabpanels,
.browserSidebarContainer,
browser[type="content"],
.browserStack,
.browserStack > browser {
  background-color: transparent !important;
  background: transparent !important;
}

#navigator-toolbox,
#zen-sidebar-top-buttons,
#zen-appcontent-navbar-wrapper {
  background-color: {{ background }} !important;
}

/* Sidebar & Workspace UI */
#sidebar-box,
#sidebar-main,
#zen-sidebar-box {
  background-color: {{ dark_background }} !important;
}

.zen-workspace-button[active="true"],
.zen-workspace-button:hover {
  background-color: {{ lighter_background }} !important;
  color: {{ accent }} !important;
}

.zen-workspace-indicator {
  fill: {{ accent }} !important;
}

/* Tab Styling */
.tabbrowser-tab[selected] .tab-background,
.tabbrowser-tab[multiselected] .tab-background {
  background-color: {{ lighter_background }} !important;
  border-left: 2px solid {{ accent }} !important;
}

.tabbrowser-tab[selected] .tab-label {
  color: {{ bright_foreground }} !important;
  font-weight: 600 !important;
}

.tabbrowser-tab:hover:not([selected]) .tab-background {
  background-color: {{ selection_background }} !important;
}

/* URL Bar & Autocomplete Popup */
#urlbar-background {
  background-color: {{ lighter_background }} !important;
  border: 1px solid {{ muted }} !important;
}

#urlbar[focused="true"] #urlbar-background {
  border-color: {{ accent }} !important;
  box-shadow: 0 0 0 1px {{ accent }} !important;
}

#urlbar-input {
  color: {{ foreground }} !important;
}

.urlbarView {
  background-color: {{ dark_background }} !important;
}

.urlbarView-row[selected],
.urlbarView-row:hover {
  background-color: {{ selection_background }} !important;
  color: {{ bright_foreground }} !important;
}

/* Scrollbars */
* {
  scrollbar-color: {{ muted }} {{ background }} !important;
}
