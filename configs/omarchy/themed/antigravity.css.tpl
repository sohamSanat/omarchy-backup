/* Omarchy Dynamic Theme for Antigravity Base App */
:root, .dark, .theme-dark, .theme-light, body {
  /* UI Surface Colors */
  --background: {{ background }} !important;
  --color-background: {{ background }} !important;
  --foreground: {{ foreground }} !important;
  --color-foreground: {{ foreground }} !important;

  --sidebar: {{ dark_background }} !important;
  --color-sidebar: {{ dark_background }} !important;
  --sidebar-secondary: {{ lighter_background }} !important;
  --color-sidebar-secondary: {{ lighter_background }} !important;
  --sidebar-muted: {{ darker_background }} !important;
  --color-sidebar-muted: {{ darker_background }} !important;

  --card: {{ dark_background }} !important;
  --color-card: {{ dark_background }} !important;
  --card-border: {{ selection }} !important;
  --color-card-border: {{ selection }} !important;

  --border: {{ lighter_background }} !important;
  --color-border: {{ lighter_background }} !important;

  --primary: {{ accent }} !important;
  --color-primary: {{ accent }} !important;
  --primary-foreground: {{ bright_foreground }} !important;
  --color-primary-foreground: {{ bright_foreground }} !important;

  --secondary: {{ lighter_background }} !important;
  --color-secondary: {{ lighter_background }} !important;
  --secondary-foreground: {{ foreground }} !important;
  --color-secondary-foreground: {{ foreground }} !important;

  --muted: {{ darker_background }} !important;
  --color-muted: {{ darker_background }} !important;
  --muted-foreground: {{ dark_foreground }} !important;
  --color-muted-foreground: {{ dark_foreground }} !important;

  --color-selection-background: {{ selection }} !important;
  --editor-selection-background: {{ selection }} !important;
  --color-placeholder: {{ muted }} !important;
  --color-link: {{ cyan }} !important;
  --color-warning: {{ yellow }} !important;
  --color-error: {{ red }} !important;

  /* Syntax Highlighting Tokens */
  --syntax-default-fg: {{ foreground }} !important;
  --syntax-comment: {{ muted }} !important;
  --syntax-punctuation: {{ dark_foreground }} !important;
  --syntax-property: {{ bright_cyan }} !important;
  --syntax-tag: {{ red }} !important;
  --syntax-constant: {{ red }} !important;
  --syntax-number: {{ orange }} !important;
  --syntax-string: {{ green }} !important;
  --syntax-attr-name: {{ blue }} !important;
  --syntax-builtin: {{ green }} !important;
  --syntax-operator: {{ cyan }} !important;
  --syntax-variable: {{ foreground }} !important;
  --syntax-attr-value: {{ green }} !important;
  --syntax-keyword: {{ magenta }} !important;
  --syntax-function: {{ blue }} !important;
  --syntax-class-name: {{ bright_yellow }} !important;
  --syntax-regex: {{ orange }} !important;

  --code-foreground: {{ foreground }} !important;
  --color-code: {{ foreground }} !important;
  --editor-code-block-background: {{ dark_background }} !important;
  --editor-line-number-foreground: {{ muted }} !important;

  /* Diffs */
  --editor-diff-inserted-line-background: {{ green }}22 !important;
  --editor-diff-inserted-text-background: {{ green }}44 !important;
  --editor-diff-removed-line-background: {{ red }}22 !important;
  --editor-diff-removed-text-background: {{ red }}44 !important;
  --color-diffEditor-insertedLineBackground: {{ green }}22 !important;
  --color-diffEditor-insertedTextBackground: {{ green }}44 !important;
  --color-diffEditor-removedLineBackground: {{ red }}22 !important;
  --color-diffEditor-removedTextBackground: {{ red }}44 !important;
}

/* Explicit Prism / Markdown Token Rules */
.token.comment, .token.prolog, .token.doctype, .token.cdata {
  color: {{ muted }} !important;
  font-style: italic !important;
}
.token.punctuation {
  color: {{ dark_foreground }} !important;
}
.token.property, .token.symbol, .token.deleted {
  color: {{ bright_cyan }} !important;
}
.token.tag {
  color: {{ red }} !important;
}
.token.constant {
  color: {{ red }} !important;
}
.token.boolean, .token.number {
  color: {{ orange }} !important;
}
.token.selector, .token.string, .token.char, .token.inserted {
  color: {{ green }} !important;
}
.token.attr-name {
  color: {{ blue }} !important;
}
.token.builtin {
  color: {{ green }} !important;
}
.token.operator, .token.entity, .token.url {
  color: {{ cyan }} !important;
}
.token.atrule, .token.attr-value {
  color: {{ green }} !important;
}
.token.keyword {
  color: {{ magenta }} !important;
  font-weight: 500 !important;
}
.token.function {
  color: {{ blue }} !important;
}
.token.class-name {
  color: {{ bright_yellow }} !important;
}
.token.regex, .token.important {
  color: {{ orange }} !important;
}
.token.variable {
  color: {{ foreground }} !important;
}
.token.reference {
  color: {{ magenta }} !important;
}
.token.type, .token.definition {
  color: {{ bright_yellow }} !important;
}
.token.macro {
  color: {{ orange }} !important;
}

/* Code Blocks & Pre Elements */
pre[class*="language-"],
code[class*="language-"],
.code-block,
div[class*="code-block"] {
  background-color: {{ dark_background }} !important;
  color: {{ foreground }} !important;
  border-color: {{ lighter_background }} !important;
}

:not(pre) > code {
  background-color: {{ darker_background }} !important;
  color: {{ bright_foreground }} !important;
  padding: 0.15em 0.35em !important;
  border-radius: 4px !important;
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

/* Inputs, Textareas and Dropdowns */
textarea, input {
  color: {{ foreground }} !important;
}

/* Header & Title bar integration */
header, [data-tauri-drag-region], [style*="webkit-app-region: drag"] {
  background-color: {{ background }} !important;
}
