---
description: Ensure high text contrast and legibility across light and dark Omarchy themes
trigger: always_on
---

# Omarchy Theming & Text Contrast Guidelines

When creating, editing, or customizing CLI tools, terminal banners, TUIs, shell prompts, or Omarchy configurations:

- **Universal Environment Variables Available in All Terminal Sessions**:
  - `OMARCHY_THEME_MODE`: Set to `"light"` or `"dark"`.
  - `COLORFGBG`: Set to `"0;15"` (light background) or `"15;0"` (dark background). Standard tools (vim, nvim, bat, fzf, Python rich) check this automatically.
  - `OMARCHY_THEME_NAME`: Active theme slug (e.g. `"akaito"`, `"tokyo-night"`).
  - `OMARCHY_THEME_FG`, `OMARCHY_THEME_BG`, `OMARCHY_THEME_ACCENT`: Hex color codes.

- **Available Detection Tooling & Libraries**:
  - **Python**: Use `import omarchy_theme` (available in user site-packages):
    ```python
    import omarchy_theme
    p = omarchy_theme.get_palette() # Pre-configured high-contrast palette for active mode
    if omarchy_theme.is_light():
        ...
    ```
  - **Bash**: Use `source /home/soham/.local/lib/omarchy-theme.sh`:
    Provides `$COLOR_TEXT`, `$COLOR_MUTED`, `$COLOR_BLUE`, `$THEME_MODE`, `is_light_theme`.
  - **CLI**: Use `omarchy-theme-env` (`--json`, `--mode`, `is-light`, `is-dark`).

- **Strict Rule for Light Themes**:
  - In terminals with transparency (e.g. Ghostty with `background-opacity` over light wallpapers), background areas can be white or off-white.
  - **NEVER** use white (`\033[38;5;255m`), light gray (`\033[38;5;244m`), or washed-out `DIM` (`\033[2m`) for text, descriptions, subtitles, borders, or headers.
  - **NEVER** use bright/pale neon colors (such as electric cyan `#00ffff`, pale yellow `#ffd700`, or pastel green) on light backgrounds.
  - **Primary Body & Descriptions**: Always use high-contrast dark text (e.g. terminal default foreground `\033[39m` or deep charcoal `\033[38;5;235m`).
  - **Subtitles & Muted Metadata**: Use readable dark slate/charcoal (e.g. `\033[38;5;240m` / `#585858`), NOT `DIM`.
  - **Accents & Highlights**: Use deep, rich, saturated tones:
    - Blue: Deep cobalt (`\033[38;5;25m`)
    - Green: Forest green (`\033[38;5;28m`)
    - Red / Magenta: Crimson / raspberry (`\033[38;5;160m` / `\033[38;5;127m`)
    - Orange / Amber: Deep rust / antique bronze (`\033[38;5;166m` / `\033[38;5;130m`)
    - Purple: Royal plum (`\033[38;5;91m` / `\033[38;5;54m`)
    - Cyan: Deep teal (`\033[38;5;30m`)

- **Dual-Mode Adaptation**:
  Always ensure any script, banner, or CLI dynamically adapts to both dark and light modes so readability is preserved whenever the user switches Omarchy themes.
