# Omarchy Dark Reader Mod for Zen Browser

This directory contains the mod source and build integration connecting the **Dark Reader** browser extension to **Omarchy Linux**'s dynamic system theming architecture.

## Overview
 
- **Source Code**: [`src/`](file:///home/soham/.config/zen/mods/darkreader/src/)
  - `background/index.js`:
    - Manages `OmarchyManager`, which asynchronously loads `../config/omarchy-theme.json`.
    - Implements perceptual luminance checking (`OmarchyManager.isColorLight`) using ITU-R BT.601 formula to guarantee dark backgrounds are never misclassified as light mode even if theme packages have inaccurate mode flags.
    - Computes theme poles (`darkSchemeBackgroundColor`, `lightSchemeBackgroundColor`, `darkSchemeTextColor`, `lightSchemeTextColor`, `selectionColor`, `scrollbarColor`, `accentColor`, `omarchyTokens`) matched to active system mode (`mode: "light"` or `"dark"`).
    - Incorporates dual-mode color modifiers (`modifyOmarchyDarkSchemeColor`, `modifyOmarchyLightBgColor`, `modifyOmarchyLightFgColor`) into background style generation.
    - Handles `TOGGLE_OMARCHY_THEME` message from UI: backs up existing theme settings to `savedNormalTheme` and `savedNormalDetectDarkTheme`, applies Omarchy theme poles, and notifies all open tabs. Toggling OFF restores the saved normal configuration.
    - Bypasses `detectDarkTheme` and dark lists when `omarchyThemeActive` is enabled so that native dark-mode web apps (e.g. YouTube, GitHub) do not disable Dark Reader or revert to generic un-themed colors.
  - `inject/index.js`:
    - **Color Math Engine**:
      - `modifyOmarchyDarkSchemeColor` and `modifyOmarchyDarkModeHSL` accurately map canvas luminance to theme backgrounds, elevate surface luminance for cards and chips, and preserve saturated buttons.
      - `modifyOmarchyLightBgColor` and `modifyOmarchyLightFgColor` handle light-mode themes (e.g. Akaito parchment), explicitly inverting light foreground text to deep contrast dark tones (`#4d2e1a`) to satisfy Omarchy high-contrast requirements.
    - **Dynamic Stylesheet Injection (`darkreader--omarchy-theme`)**: Injects CSS variables and component styling for web applications:
      - **YouTube**:
        - Scoped selectors: `html, html:not(.style-scope), :root, [dark], html[dark], [data-color-mode], [data-theme], ytd-app, ytd-app[dark], ytd-masthead, ytd-browse, ytd-watch-flexy`.
        - System variables: full coverage of `--yt-spec-*`, `--yt-primary-*`, `--yt-secondary-*`, `--yt-app-background`, `--ytd-searchbox-*`, and `--yt-spec-badge-chip-*`.
        - Component styling: `#page-manager`, `ytd-masthead`, `ytd-mini-guide-renderer`, `#container.ytd-searchbox`, `#video-title`, `#metadata-line`, navigation icons, and `.ytp-play-progress`.
      - **GitHub**: `--bgColor-default`, `--bgColor-muted`, `--bgColor-inset`, `--fgColor-accent`, and borders.
      - **Reddit (Shreddit)**: `--shreddit-content-background`, `--color-neutral-background*`, `--darkreader-bg--*`, targeting `shreddit-app`, `#main-content`, `.subgrid-container`, and comments.
      - **Universal**: custom scrollbars, selection colors (`::selection`), form controls, and `:focus-visible` rings.
    - **Theme Detector Guard**: Protects the dynamic theme from premature cleanup on dark web apps.
  - `ui/popup/index.js`:
    - Renders the interactive `OmarchyToggle` component (`omarchy` button).
    - Reactively binds button indicator and text state to `data.settings.omarchyThemeActive`.
    - Displays `"Omarchy System Theme Active"` in status section when enabled.
    - Dispatches `actions.toggleOmarchyTheme(!isActive)` through the background connector.
  - `ui/popup/index.html`:
    - Injects `omarchy-theme.css`.
  - `ui/popup/omarchy-theme.css`:
    - Populated from the compiled Omarchy system theme template.
- **Dynamic Templates**:
  - [`~/.config/omarchy/themed/zen-darkreader.css.tpl`](file:///home/soham/.config/omarchy/themed/zen-darkreader.css.tpl):
    - Populates popup button colors using Omarchy theme tokens (`{{ accent }}`, `{{ background }}`, `{{ foreground }}`).
    - Compiles to `~/.local/state/omarchy/current/theme/zen-darkreader.css`.
  - [`~/.config/omarchy/themed/zen-darkreader-theme.json.tpl`](file:///home/soham/.config/omarchy/themed/zen-darkreader-theme.json.tpl):
    - Generates clean JSON capturing `mode`, `background`, `foreground`, `accent`, `selectionBackground`, `selectionForeground`, `darkBackground`, `darkerBackground`, etc.
    - Compiles to `~/.local/state/omarchy/current/theme/zen-darkreader-theme.json`.
- **Packaging & Deployment**:
  - Managed by [`omarchy-sync-zen`](file:///home/soham/.local/bin/omarchy-sync-zen).
  - Automatically copies `zen-darkreader.css` to `ui/popup/omarchy-theme.css` and `zen-darkreader-theme.json` to `config/omarchy-theme.json`.
  - Repacks and signs/installs `<profile>/extensions/addon@darkreader.org.xpi` across active Zen profiles.
  - Automatically regenerates tokens on `omarchy theme set <theme>`.

## Verification & Usage

```bash
# Check status of theme and Dark Reader mod
omarchy-sync-zen --status

# Re-compile and sync Dark Reader across profiles
omarchy-sync-zen --sync

# Restart Zen browser gracefully
omarchy-sync-zen --restart
```
