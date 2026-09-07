# Zen Browser Mods on Omarchy Linux

This directory hosts the configurations and mods connecting **Zen Browser** to **Omarchy Linux**.

## Active Mods

### 1. Omarchy Dynamic System Theme (`omarchy-theme`)
- **Purpose**: Automatically synchronizes Zen Browser's chrome UI colors (sidebar, tab strip, toolbars, dialogs) with the active Omarchy system theme.
- **Source Template**: [`~/.config/omarchy/themed/zen.css.tpl`](file:///home/soham/.config/omarchy/themed/zen.css.tpl)
- **Compiled Target**: [`~/.local/state/omarchy/current/theme/zen.css`](file:///home/soham/.local/state/omarchy/current/theme/zen.css)
- **Profile Link**: `<profile>/chrome/zen-omarchy-theme.css` -> imported by `<profile>/chrome/userChrome.css`.
- **Sync CLI**: [`~/.local/bin/omarchy-sync-zen`](file:///home/soham/.local/bin/omarchy-sync-zen)

### 2. Frosted Glass Default Tab (`omarchy-zen-glass`)
- **Purpose**: Transforms the default empty/new tab area into a frosted glass pane matching the system terminal (Ghostty), with the desktop wallpaper and Hyprland blur bleeding through.
- **Crucial Invariant**: Only empty/new tabs (`about:blank`, `about:newtab`, `about:home`) are transparent. Loaded web pages (GitHub, YouTube, Google, etc.) specify their own opaque backgrounds and remain 100% solid, crisp, and readable.
- **Source Template**: [`~/.config/omarchy/themed/zen-content.css.tpl`](file:///home/soham/.config/omarchy/themed/zen-content.css.tpl)
- **Compiled Target**: [`~/.local/state/omarchy/current/theme/zen-content.css`](file:///home/soham/.local/state/omarchy/current/theme/zen-content.css)
- **Profile Link**: `<profile>/chrome/zen-omarchy-content.css` -> imported by `<profile>/chrome/userContent.css`.
- **Mod Manager CLI**: [`~/.local/bin/omarchy-zen-glass`](file:///home/soham/.local/bin/omarchy-zen-glass)

### 3. Omarchy Dark Reader Integration (`omarchy-darkreader`)
- **Purpose**: Fully connects the Dark Reader browser extension to Omarchy Linux's dynamic system theming architecture. When toggled on via the dedicated `omarchy` button in the Dark Reader popup, it overrides Dark Reader's default generic `#181a1b` dark palette with the exact active Omarchy system theme (supporting both dark and light modes, e.g. Akaito parchment `#f3e4cb` or Tokyo Night `#1a1b26`), including theme poles, accents, link colors, and text selection. Toggling off seamlessly restores normal user settings.
- **Source Mod**: [`~/.config/zen/mods/darkreader/src/`](file:///home/soham/.config/zen/mods/darkreader/src/)
  - `background/index.js`:
    - `OmarchyManager` loads tokens from `config/omarchy-theme.json` and computes scheme poles (`darkSchemeBackgroundColor`, `lightSchemeBackgroundColor`, `darkSchemeTextColor`, `lightSchemeTextColor`, `selectionColor`, `accentColor`, `omarchyTokens`).
    - Implements perceptual luminance checking (`OmarchyManager.isColorLight`) using ITU-R BT.601 formula to guarantee dark backgrounds are never misclassified as light mode even if theme packages have inaccurate mode flags.
    - Mirrors dual-mode light/dark color modification algorithms (`modifyOmarchyDarkSchemeColor`, `modifyOmarchyLightBgColor`, `modifyOmarchyLightFgColor`) for background style generation.
    - Handles `TOGGLE_OMARCHY_THEME` with non-destructive state restoration (`savedNormalTheme`, `savedNormalDetectDarkTheme`).
    - Bypasses native dark theme detection and dark lists while `omarchyThemeActive` is true so that web applications with native dark themes (YouTube, GitHub, Reddit) are properly themed to Omarchy colors without Dark Reader turning itself off.
  - `inject/index.js`:
    - **Color Math Engine**:
      - `modifyOmarchyDarkSchemeColor` and `modifyOmarchyDarkModeHSL` map canvas backgrounds directly to the Omarchy background (`#1a1b26` in Tokyo Night, `#1E3061` in Nous), map elevated cards and chips to elevated surfaces, and preserve saturated brand badges. Includes low-luminance tinted background normalization (`l <= 0.25 && s < 0.40`) to prevent subreddit custom themes from tinting post containers.
      - `modifyOmarchyLightBgColor` and `modifyOmarchyLightFgColor` ensure that light themes (e.g. Akaito `#f3e4cb`) map canvas backgrounds cleanly to cream parchment while converting white/light text to high-contrast dark charcoal/brown (`#4d2e1a`) per Omarchy text contrast rules.
    - **Dynamic Variable Injection (`darkreader--omarchy-theme`)**: Injects CSS variables and component rules for major web applications:
      - **YouTube**:
        - Scoped selectors: `html, html:not(.style-scope), :root, [dark], html[dark], [data-color-mode], [data-theme], ytd-app, ytd-app[dark], ytd-masthead, ytd-browse, ytd-watch-flexy` preventing `<ytd-app>` variable overriding.
        - Surface & layout rules: `#page-manager`, `ytd-masthead`, `ytd-mini-guide-renderer`, `#container.ytd-searchbox`, `#video-title`, `#metadata-line`, navigation icons, chip clouds, and player progress bars.
      - **GitHub**: `--bgColor-*`, `--fgColor-accent`, universal selection, scrollbars, focus rings.
      - **Reddit (Shreddit)**: `--shreddit-content-background`, `--color-neutral-background*`, `--darkreader-bg--shreddit-content-background`, `--newCommunityTheme-*`, targeting `shreddit-app`, `#main-content`, `.subgrid-container`, `aside`, `nav`, `.bg-neutral-background`, `#comment-tree`.
    - **Theme Detector Guard**: Prevents `detectDarkTheme` from disabling dynamic style injection when `omarchyThemeActive` is true.
  - `ui/popup/index.js`: Interactive `OmarchyToggle` button bound to reactive extension settings with active theme status indication.
- **Dynamic Templates**:
  - [`~/.config/omarchy/themed/zen-darkreader.css.tpl`](file:///home/soham/.config/omarchy/themed/zen-darkreader.css.tpl) -> compiles to `~/.local/state/omarchy/current/theme/zen-darkreader.css` (popup UI styling).
  - [`~/.config/omarchy/themed/zen-darkreader-theme.json.tpl`](file:///home/soham/.config/omarchy/themed/zen-darkreader-theme.json.tpl) -> compiles to `~/.local/state/omarchy/current/theme/zen-darkreader-theme.json` (system token palette).
- **Extension Target**: `<profile>/extensions/addon@darkreader.org.xpi`
- **Sync CLI**: [`~/.local/bin/omarchy-sync-zen`](file:///home/soham/.local/bin/omarchy-sync-zen)

---

## 4-Layer Glass Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Hyprland Compositor (~/.config/hypr/hyprland.lua)        │
│    - Window rule: opacity = 0.85 0.78                       │
│    - Dual-pass blur over active desktop wallpaper           │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ 2. Gecko / Wayland Engine (<profile>/user.js)                │
│    - zen.widget.linux.transparency = true                   │
│    - browser.tabs.allow_transparent_browser = true          │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ 3. Chrome Window Canvas (zen.css / userChrome.css)          │
│    - #main-window, #browser, .browserContainer transparent  │
│    - Frosted glass floating URL bar on empty tabs           │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ 4. Tab Content (zen-content.css / userContent.css)          │
│    - about:blank, about:newtab, about:home transparent      │
│    - External websites (https://...) remain 100% solid      │
└─────────────────────────────────────────────────────────────┘
```

---

## Management Commands

```bash
# Check status of the glass mod across all 4 layers
omarchy-zen-glass --status

# Enable or re-enable the glass mod
omarchy-zen-glass --enable

# Disable the glass mod (restores solid window background)
omarchy-zen-glass --disable

# Gracefully restart Zen Browser to apply stylesheet updates (restores session)
omarchy-zen-glass --restart

# Re-sync theme after manual template edits
omarchy-sync-zen --sync
```
