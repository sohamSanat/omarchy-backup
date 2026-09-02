/* Omarchy Theme for Obsidian */

.theme-dark, .theme-light {
  /* Mode-adaptive / Core base colors */
  --color-base-00: {{ background }};
  --color-base-05: {{ darker_background }};
  --color-base-10: {{ dark_background }};
  --color-base-20: {{ darker_background }};
  --color-base-25: {{ lighter_background }};
  --color-base-30: {{ lighter_background }};
  --color-base-35: {{ muted }};
  --color-base-40: {{ muted }};
  --color-base-50: {{ dark_foreground }};
  --color-base-60: {{ foreground }};
  --color-base-70: {{ light_foreground }};
  --color-base-100: {{ bright_foreground }};

  /* Core background & text colors */
  --background-primary: {{ background }};
  --background-primary-alt: {{ darker_background }};
  --background-secondary: {{ dark_background }};
  --background-secondary-alt: {{ darker_background }};
  --text-normal: {{ foreground }};
  --text-bold: {{ bright_foreground }};
  --text-muted: {{ dark_foreground }};
  --text-faint: color-mix(in srgb, {{ dark_foreground }} 70%, transparent);

  /* Title bar & Sidebars */
  --titlebar-background: {{ dark_background }};
  --titlebar-background-focused: {{ darker_background }};
  --titlebar-text-color-focused: {{ foreground }};
  --tab-background-active: {{ background }};
  --tab-text-color-focused-active: {{ bright_foreground }};
  --ribbon-background: {{ dark_background }};

  /* Selection colors */
  --text-selection: {{ selection }};

  /* Borders & Dividers */
  --background-modifier-border: {{ muted }};
  --divider-color: {{ muted }};
  --background-modifier-border-focus: {{ accent }};
  --background-modifier-border-hover: {{ light_foreground }};

  /* UI Form & Hover states */
  --background-modifier-form-field: {{ darker_background }};
  --background-modifier-hover: color-mix(in srgb, {{ foreground }} 8%, transparent);
  --background-modifier-active-hover: color-mix(in srgb, {{ foreground }} 15%, transparent);

  /* Semantic accent & rainbow palette */
  --color-accent: {{ accent }};
  --color-accent-1: {{ bright_blue }};
  --color-accent-2: {{ cyan }};
  --text-accent: {{ accent }};
  --text-accent-hover: {{ bright_blue }};
  --interactive-accent: {{ accent }};
  --interactive-accent-hover: {{ bright_blue }};
  --interactive-hover: color-mix(in srgb, {{ accent }} 15%, transparent);

  --color-red: {{ red }};
  --color-orange: {{ orange }};
  --color-yellow: {{ yellow }};
  --color-green: {{ green }};
  --color-cyan: {{ cyan }};
  --color-blue: {{ blue }};
  --color-purple: {{ purple }};
  --color-pink: {{ magenta }};

  /* Headings */
  --text-title-h1: {{ red }};
  --text-title-h2: {{ green }};
  --text-title-h3: {{ yellow }};
  --text-title-h4: {{ blue }};
  --text-title-h5: {{ magenta }};
  --text-title-h6: {{ cyan }};
  --heading-spacing: calc(var(--p-spacing) * 1.5);

  /* Links */
  --text-link: {{ blue }};
  --link-color: {{ blue }};
  --link-color-hover: {{ bright_blue }};
  --link-external-color: {{ cyan }};
  --link-external-color-hover: {{ bright_cyan }};

  /* Code & Syntax */
  --code-normal: {{ cyan }};
  --code-background: {{ darker_background }};

  /* Callouts & Quotes */
  --blockquote-border-color: {{ accent }};

  /* Tags & Checkboxes */
  --tag-color: {{ cyan }};
  --tag-background: color-mix(in srgb, {{ cyan }} 15%, transparent);
  --tag-background-hover: color-mix(in srgb, {{ cyan }} 25%, transparent);
  --checkbox-color: {{ accent }};
  --checkbox-color-hover: {{ bright_blue }};

  /* Errors and success */
  --text-error: {{ red }};
  --text-error-hover: {{ bright_red }};
  --text-success: {{ green }};

  /* Graph */
  --graph-line: {{ muted }};
  --graph-node: {{ accent }};
  --graph-node-focused: {{ bright_blue }};
  --graph-node-tag: {{ cyan }};
  --graph-node-attachment: {{ green }};
}

/* Headers */
.cm-header-1, .markdown-rendered h1 { color: var(--text-title-h1); }
.cm-header-2, .markdown-rendered h2 { color: var(--text-title-h2); }
.cm-header-3, .markdown-rendered h3 { color: var(--text-title-h3); }
.cm-header-4, .markdown-rendered h4 { color: var(--text-title-h4); }
.cm-header-5, .markdown-rendered h5 { color: var(--text-title-h5); }
.cm-header-6, .markdown-rendered h6 { color: var(--text-title-h6); }

/* Code blocks */
.markdown-rendered code {
  color: {{ cyan }};
}

/* Syntax highlighting */
.cm-s-obsidian span.cm-keyword { color: {{ red }}; }
.cm-s-obsidian span.cm-string { color: {{ green }}; }
.cm-s-obsidian span.cm-number { color: {{ yellow }}; }
.cm-s-obsidian span.cm-comment { color: {{ muted }}; }
.cm-s-obsidian span.cm-operator { color: {{ blue }}; }
.cm-s-obsidian span.cm-def { color: {{ blue }}; }
.cm-s-obsidian span.cm-variable { color: {{ foreground }}; }
.cm-s-obsidian span.cm-property { color: {{ cyan }}; }

/* Active navigation items & headers */
.workspace-leaf.mod-active .workspace-leaf-header-title {
  color: var(--interactive-accent);
}

.nav-file-title.is-active {
  color: var(--interactive-accent);
}

/* Search results */
.search-result-file-title {
  color: var(--interactive-accent);
}
