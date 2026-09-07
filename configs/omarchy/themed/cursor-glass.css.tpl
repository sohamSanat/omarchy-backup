/* Omarchy Dynamic Theme for Cursor Glass (Base Cursor Agent App) */

:root,
body,
body[data-cursor-glass-mode="true"],
[data-component="root"],
.monaco-workbench,
.monaco-workbench.vs-dark,
.monaco-workbench.vs,
.monaco-workbench.hc-black,
.monaco-workbench.hc-light,
.ui-1lzgia1 {
  /* Surface & Container Colors */
  --glass-surface-background: {{ background }} !important;
  --glass-sidebar-surface-background: {{ dark_background }} !important;
  --glass-chat-surface-background: {{ background }} !important;
  --glass-editor-surface-background: {{ background }} !important;
  --glass-chat-bubble-background: {{ lighter_background }} !important;
  --glass-onboard-surface-background: {{ background }} !important;
  --glass-window-border-color: {{ selection }} !important;
  --welcome-splash-early-bg: {{ background }} !important;

  --cursor-bg-chrome: {{ background }} !important;
  --cursor-bg-editor: {{ background }} !important;
  --cursor-bg-sidebar: {{ dark_background }} !important;
  --cursor-bg-elevated: {{ dark_background }} !important;
  --cursor-bg-input: {{ darker_background }} !important;
  --cursor-bg-input-field: {{ darker_background }} !important;
  --cursor-bg-card: {{ dark_background }} !important;
  --cursor-bg-primary: {{ background }} !important;
  --cursor-bg-secondary: {{ lighter_background }} !important;
  --cursor-bg-tertiary: {{ selection }} !important;
  --cursor-bg-quaternary: {{ darker_background }} !important;
  --cursor-bg-quinary: {{ dark_background }} !important;

  /* Accent & Action Colors */
  --cursor-accent: {{ accent }} !important;
  --cursor-bg-accent: {{ accent }} !important;
  --cursor-bg-accent-secondary: {{ lighter_background }} !important;
  --cursor-bg-accent-tertiary: {{ selection }} !important;
  --cursor-bg-accent-hover: color-mix(in srgb, {{ bright_foreground }} 15%, {{ accent }}) !important;
  --cursor-bg-active: {{ selection }} !important;
  --cursor-brand: {{ accent }} !important;
  --cursor-focus: {{ accent }} !important;

  /* Base & Foreground Text Colors */
  --cursor-base: {{ foreground }} !important;
  --cursor-text-primary: {{ foreground }} !important;
  --cursor-text-secondary: {{ dark_foreground }} !important;
  --cursor-text-tertiary: {{ muted }} !important;
  --cursor-text-quaternary: {{ muted }} !important;
  --cursor-text-invert: {{ background }} !important;
  --cursor-text-accent: {{ accent }} !important;
  --cursor-text-active: {{ bright_foreground }} !important;
  --cursor-text-focused: {{ foreground }} !important;
  --cursor-text-link: {{ bright_cyan }} !important;
  --cursor-text-link-active: {{ bright_foreground }} !important;
  --cursor-text-code-block-background: {{ dark_background }} !important;

  /* Border & Stroke Colors */
  --cursor-stroke-primary: {{ selection }} !important;
  --cursor-stroke-secondary: {{ lighter_background }} !important;
  --cursor-stroke-tertiary: {{ darker_background }} !important;
  --cursor-stroke-tertiary-opaque: {{ lighter_background }} !important;
  --cursor-stroke-quaternary: {{ darker_background }} !important;
  --cursor-stroke-focused: {{ accent }} !important;
  --cursor-input-border: {{ lighter_background }} !important;
  --cursor-input-placeholder-foreground: {{ muted }} !important;

  /* Icon Colors */
  --cursor-icon-primary: {{ foreground }} !important;
  --cursor-icon-secondary: {{ dark_foreground }} !important;
  --cursor-icon-tertiary: {{ muted }} !important;
  --cursor-icon-quaternary: {{ muted }} !important;
  --cursor-icon-accent-primary: {{ accent }} !important;
  --cursor-icon-blue-primary: {{ blue }} !important;
  --cursor-icon-green-primary: {{ green }} !important;
  --cursor-icon-red-primary: {{ red }} !important;
  --cursor-icon-yellow-primary: {{ yellow }} !important;
  --cursor-icon-magenta-primary: {{ magenta }} !important;
  --cursor-icon-cyan-primary: {{ cyan }} !important;
  --cursor-icon-purple-primary: {{ purple }} !important;

  /* Git & Status Colors */
  --cursor-added: {{ green }} !important;
  --cursor-modified: {{ yellow }} !important;
  --cursor-removed: {{ red }} !important;
  --cursor-untracked: {{ cyan }} !important;
  --cursor-success: {{ green }} !important;
  --cursor-warn: {{ yellow }} !important;
  --cursor-danger: {{ red }} !important;
  --cursor-blue: {{ blue }} !important;
  --cursor-green: {{ green }} !important;
  --cursor-red: {{ red }} !important;
  --cursor-yellow: {{ yellow }} !important;
  --cursor-magenta: {{ magenta }} !important;
  --cursor-cyan: {{ cyan }} !important;
  --cursor-purple: {{ purple }} !important;
  --cursor-orange: {{ orange }} !important;

  /* Syntax Highlighting Tokens */
  --cursor-syntax-background: {{ dark_background }} !important;
  --cursor-syntax-foreground: {{ foreground }} !important;
  --cursor-syntax-keyword: {{ magenta }} !important;
  --cursor-syntax-function: {{ blue }} !important;
  --cursor-syntax-string: {{ green }} !important;
  --cursor-syntax-comment: {{ muted }} !important;
  --cursor-syntax-constant: {{ red }} !important;
  --cursor-syntax-number: {{ orange }} !important;
  --cursor-syntax-parameter: {{ light_foreground }} !important;
  --cursor-syntax-punctuation: {{ dark_foreground }} !important;
  --cursor-syntax-property: {{ bright_cyan }} !important;
  --cursor-syntax-type: {{ bright_yellow }} !important;
  --cursor-syntax-variable: {{ foreground }} !important;
  --cursor-syntax-tag: {{ red }} !important;
  --cursor-syntax-link: {{ cyan }} !important;
  --cursor-syntax-string-expression: {{ green }} !important;
  --cursor-syntax-attribute: {{ blue }} !important;
  --cursor-syntax-class: {{ bright_yellow }} !important;

  /* Shiki Syntax Token Mappings */
  --shiki-foreground: {{ foreground }} !important;
  --shiki-token-constant: {{ red }} !important;
  --shiki-token-string: {{ green }} !important;
  --shiki-token-comment: {{ muted }} !important;
  --shiki-token-keyword: {{ magenta }} !important;
  --shiki-token-parameter: {{ light_foreground }} !important;
  --shiki-token-function: {{ blue }} !important;
  --shiki-token-string-expression: {{ green }} !important;
  --shiki-token-punctuation: {{ dark_foreground }} !important;
  --shiki-token-link: {{ cyan }} !important;
  --shiki-token-type: {{ bright_yellow }} !important;
  --shiki-token-property: {{ bright_cyan }} !important;
  --shiki-token-variable: {{ foreground }} !important;
  --shiki-token-tag: {{ red }} !important;

  /* Diffs */
  --cursor-bg-diff-inserted: color-mix(in srgb, {{ green }} 20%, transparent) !important;
  --cursor-bg-diff-removed: color-mix(in srgb, {{ red }} 20%, transparent) !important;

  /* VS Code Fallback Tokens */
  --vscode-sideBar-background: {{ dark_background }} !important;
  --vscode-sideBar-foreground: {{ foreground }} !important;
  --vscode-editor-background: {{ background }} !important;
  --vscode-editor-foreground: {{ foreground }} !important;
  --vscode-foreground: {{ foreground }} !important;
  --vscode-descriptionForeground: {{ dark_foreground }} !important;
  --vscode-button-background: {{ accent }} !important;
  --vscode-button-foreground: {{ bright_foreground }} !important;
  --vscode-button-hoverBackground: color-mix(in srgb, {{ bright_foreground }} 15%, {{ accent }}) !important;
  --vscode-button-secondaryBackground: {{ lighter_background }} !important;
  --vscode-button-secondaryForeground: {{ foreground }} !important;
  --vscode-focusBorder: {{ accent }} !important;
  --vscode-input-background: {{ darker_background }} !important;
  --vscode-input-foreground: {{ foreground }} !important;
  --vscode-input-border: {{ lighter_background }} !important;
  --vscode-input-placeholderForeground: {{ muted }} !important;
  --vscode-list-hoverBackground: {{ lighter_background }} !important;
  --vscode-list-activeSelectionBackground: {{ selection }} !important;
  --vscode-list-activeSelectionForeground: {{ bright_foreground }} !important;
  --vscode-menu-background: {{ dark_background }} !important;
  --vscode-menu-foreground: {{ foreground }} !important;
  --vscode-titleBar-activeBackground: {{ dark_background }} !important;
  --vscode-titleBar-activeForeground: {{ foreground }} !important;
}

/* Base Surfaces & Structural Overrides */
html,
body,
body[data-cursor-glass-mode="true"],
#workbench\.main\.container,
[data-component="root"] {
  background: {{ background }} !important;
  background-color: {{ background }} !important;
  color: {{ foreground }} !important;
}

/* In-App Menubar & Titlebar */
[data-component="glass-in-app-menubar"],
[data-component="glass-titlebar"],
.glass-titlebar {
  background: {{ dark_background }} !important;
  background-color: {{ dark_background }} !important;
  border-bottom: 1px solid {{ selection }} !important;
  color: {{ foreground }} !important;
}

/* Top Menubar Buttons & Window Controls */
[data-component="glass-in-app-menubar"] button,
[data-component="glass-window-controls"] button {
  color: {{ dark_foreground }} !important;
}

[data-component="glass-in-app-menubar"] button:hover,
[data-component="glass-window-controls"] button:hover {
  color: {{ foreground }} !important;
  background-color: {{ lighter_background }} !important;
}

[data-component="glass-window-controls"] button[data-kind="close"]:hover {
  background-color: {{ red }} !important;
  color: #ffffff !important;
}

/* Workspace Sidebar */
[data-component="workspace-sidebar"],
.glass-sidebar {
  background: {{ dark_background }} !important;
  background-color: {{ dark_background }} !important;
  border-right: 1px solid {{ selection }} !important;
  color: {{ foreground }} !important;
}

/* Sidebar "New Chat" & Primary Actions */
[data-component="workspace-sidebar"] button:first-child,
.ui-button-primary {
  background-color: {{ lighter_background }} !important;
  border: 1px solid {{ selection }} !important;
  color: {{ bright_foreground }} !important;
}

[data-component="workspace-sidebar"] button:first-child:hover {
  background-color: {{ selection }} !important;
}

/* Sidebar Navigation Items & Repo Tree */
[data-component="workspace-sidebar"] .ui-tree-item,
[data-component="workspace-sidebar"] [role="treeitem"],
[data-component="workspace-sidebar"] button {
  color: {{ foreground }} !important;
}

[data-component="workspace-sidebar"] .ui-tree-item:hover,
[data-component="workspace-sidebar"] [role="treeitem"]:hover {
  background-color: {{ lighter_background }} !important;
}

[data-component="workspace-sidebar"] [aria-selected="true"],
[data-component="workspace-sidebar"] [data-selected="true"] {
  background-color: {{ selection }} !important;
  color: {{ bright_foreground }} !important;
}

/* Sidebar Footer & User Profile */
[data-component="glass-sidebar-footer"] {
  background-color: {{ dark_background }} !important;
  border-top: 1px solid {{ selection }} !important;
}

/* Agent Center Panel / Canvas */
[data-component="agent-panel"],
.agent-panel {
  background: {{ background }} !important;
  background-color: {{ background }} !important;
  color: {{ foreground }} !important;
}

/* Top Content Pane Bar (Chat Tab / Breadcrumbs) */
[data-component="content-pane-top-bar"] {
  background-color: {{ dark_background }} !important;
  border-bottom: 1px solid {{ selection }} !important;
  color: {{ foreground }} !important;
}

/* Chat Prompt Input Container */
[data-component="agent-conversation-composer"],
.ui-prompt-input,
[data-component="agent-panel-empty-state"] > div {
  background-color: {{ dark_background }} !important;
  border: 1px solid {{ lighter_background }} !important;
  border-radius: 8px !important;
}

[data-component="agent-conversation-composer"] textarea,
.ui-prompt-input textarea,
input[type="text"] {
  background-color: transparent !important;
  color: {{ foreground }} !important;
}

[data-component="agent-conversation-composer"] textarea::placeholder,
.ui-prompt-input textarea::placeholder,
input::placeholder {
  color: {{ muted }} !important;
}

/* Action Buttons & Pills (Plan New Idea, Multitask, etc.) */
button[class*="ui-button"],
[role="button"] {
  color: {{ foreground }} !important;
}

/* User Message Bubble */
[data-component="user-message-bubble"],
.user-message-bubble,
[data-component="agent-panel"] > div > div:has(> .user-message) {
  background-color: {{ lighter_background }} !important;
  color: {{ bright_foreground }} !important;
  border-radius: 8px !important;
}

/* Code Blocks & Preformatted Code */
pre,
code,
.ProseMirror pre:where(:not([data-rte-prose-boundary] *)) {
  background-color: {{ dark_background }} !important;
  color: {{ foreground }} !important;
  border: 1px solid {{ lighter_background }} !important;
  border-radius: 6px !important;
}

:not(pre) > code {
  background-color: {{ darker_background }} !important;
  color: {{ bright_foreground }} !important;
  padding: 0.15em 0.35em !important;
  border-radius: 4px !important;
}

/* Markdown Links & Headings */
a,
.ui-link,
[data-component="link"] {
  color: {{ bright_cyan }} !important;
  text-decoration-color: {{ bright_cyan }}66 !important;
}

a:hover,
.ui-link:hover {
  color: {{ cyan }} !important;
  text-decoration: underline !important;
}

h1, h2, h3, h4, h5, h6 {
  color: {{ bright_foreground }} !important;
}

/* Custom Scrollbars */
::-webkit-scrollbar {
  width: 8px !important;
  height: 8px !important;
}

::-webkit-scrollbar-track {
  background: transparent !important;
}

::-webkit-scrollbar-thumb {
  background: {{ muted }}55 !important;
  border-radius: 4px !important;
}

::-webkit-scrollbar-thumb:hover {
  background: {{ muted }}99 !important;
}

/* Selection Highlight */
::selection {
  background-color: {{ selection }} !important;
  color: {{ bright_foreground }} !important;
}
