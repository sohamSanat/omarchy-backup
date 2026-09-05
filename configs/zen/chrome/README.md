# Zen Browser Omarchy Theming & Glass Mod Integration

This directory contains the modular styling system connecting **Zen Browser** to **Omarchy Linux**'s dynamic system theme and frosted glass tab effects.

## Architecture

1. **Source Templates**:
   - `~/.config/omarchy/themed/zen.css.tpl`: Defines chrome UI theme (tabs, toolbars, sidebar, dialogs, floating search bar).
   - `~/.config/omarchy/themed/zen-content.css.tpl`: Defines default/new tab content styling (`about:blank`, `about:newtab`, `about:home`).
2. **Current Theme Cache**:
   - `~/.local/state/omarchy/current/theme/zen.css`
   - `~/.local/state/omarchy/current/theme/zen-content.css`
   Compiled automatically whenever the Omarchy theme changes via `omarchy theme set <name>`.
3. **Symlink Targets**:
   - `zen-omarchy-theme.css` -> `~/.local/state/omarchy/current/theme/zen.css`
   - `zen-omarchy-content.css` -> `~/.local/state/omarchy/current/theme/zen-content.css`
4. **Root Entrypoints**:
   - `userChrome.css`: Imports `zen-omarchy-theme.css`. Only styles the browser chrome.
   - `userContent.css`: Imports `zen-omarchy-content.css`. Targets only internal blank/new tabs.
   - **Crucial Rule**: Normal web pages (Google, GitHub, etc.) are strictly untouched and remain 100% solid.
5. **Hyprland Glass Blur**:
   - Configured in `~/.config/hypr/hyprland.lua`:
     ```lua
     o.window("(zen|zen-bin|zen-alpha)", {
       tag = "-default-opacity",
       opacity = "0.85 0.78",
     })
     ```
6. **Automation Hooks**:
   - `~/.config/omarchy/hooks/theme-set.d/zen-sync.sh`: Runs on every theme change.

## CLI Tools

- Re-sync theme: `omarchy-sync-zen`
- Check theme status: `omarchy-sync-zen --status`
- Manage glass tab mod: `omarchy-zen-glass` (`--status`, `--enable`, `--disable`, `--restart`)
- Gracefully restart Zen: `omarchy-sync-zen --restart`
