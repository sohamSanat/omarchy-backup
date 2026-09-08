"""
omarchy_theme: Universal Python library for Omarchy theme detection and adaptive styling.
Provides instant theme mode detection (light vs dark), access to active theme colors,
and pre-configured high-contrast palettes guaranteed to remain legible on transparent
terminals and light/dark wallpapers alike.

Usage:
    import omarchy_theme

    if omarchy_theme.is_light():
        ...

    p = omarchy_theme.get_palette()
    print(f"{p['title']}Header{omarchy_theme.RESET}")
    print(f"{p['text']}High contrast body text{omarchy_theme.RESET}")
    print(f"{p['muted']}Readable secondary text (never dim){omarchy_theme.RESET}")
"""

import os
from typing import Dict, Any

RESET = "\033[0m"
BOLD = "\033[1m"
ITALIC = "\033[3m"
DIM = "\033[2m"


def is_light() -> bool:
    """Check if the active Omarchy theme or terminal environment is in light mode."""
    # 1. Environment variable (fastest, set by shell integration)
    env_mode = os.environ.get("OMARCHY_THEME_MODE", "").lower()
    if env_mode == "light":
        return True
    elif env_mode == "dark":
        return False

    # 2. COLORFGBG environment check (e.g. "0;15" = black on white)
    colorfgbg = os.environ.get("COLORFGBG", "")
    if colorfgbg:
        parts = colorfgbg.split(";")
        if len(parts) >= 2:
            try:
                bg = int(parts[-1])
                if bg in (7, 15):
                    return True
                elif bg in (0, 8):
                    return False
            except ValueError:
                pass

    # 3. Omarchy state files
    theme_state_dir = os.path.expanduser("~/.local/state/omarchy/current/theme")
    if os.path.exists(os.path.join(theme_state_dir, "light.mode")):
        return True

    # 4. Check mode file or colors.toml
    mode_file = os.path.join(theme_state_dir, "mode")
    if os.path.exists(mode_file):
        try:
            with open(mode_file, "r") as f:
                if "light" in f.read().lower():
                    return True
        except Exception:
            pass

    colors_file = os.path.join(theme_state_dir, "colors.toml")
    if os.path.exists(colors_file):
        try:
            with open(colors_file, "r") as f:
                content = f.read()
            if 'mode = "light"' in content or "mode = 'light'" in content:
                return True
            for line in content.splitlines():
                line = line.strip()
                if line.startswith("background") and "=" in line:
                    val = line.split("=", 1)[1].strip().strip("\"'")
                    if val.startswith("#") and len(val) >= 7:
                        r = int(val[1:3], 16)
                        g = int(val[3:5], 16)
                        b = int(val[5:7], 16)
                        if (r + g + b) > 382:
                            return True
        except Exception:
            pass

    return False


def is_dark() -> bool:
    """Check if the active Omarchy theme is in dark mode."""
    return not is_light()


def get_mode() -> str:
    """Return 'light' or 'dark' for the active theme."""
    return "light" if is_light() else "dark"


def get_theme_name() -> str:
    """Return the name of the active Omarchy theme."""
    name = os.environ.get("OMARCHY_THEME_NAME", "")
    if name:
        return name
    name_file = os.path.expanduser("~/.local/state/omarchy/current/theme.name")
    if os.path.exists(name_file):
        try:
            with open(name_file, "r") as f:
                return f.read().strip()
        except Exception:
            pass
    return "unknown"


def get_palette() -> Dict[str, str]:
    """
    Return a high-contrast ANSI 256 color palette matched to the active theme mode.
    Guarantees that on light themes, text and secondary elements NEVER use light/white
    colors or washed-out DIM codes.
    """
    if is_light():
        return {
            "title": "\033[38;5;130m",     # Deep amber/bronze
            "divider": "\033[38;5;54m",   # Deep royal plum
            "thin_div": "\033[38;5;240m", # Readable slate divider
            "head": "\033[38;5;234m",     # Deep charcoal/black for headers
            "text": "\033[38;5;235m",     # Crisp dark charcoal body text (never white/light gray)
            "muted": "\033[38;5;240m",    # Readable slate (never washed-out DIM)
            "bullet": "\033[38;5;240m",   # Visible separator bullet
            "blue": "\033[38;5;25m",      # Deep cobalt blue
            "magenta": "\033[38;5;127m",  # Deep raspberry/magenta
            "green": "\033[38;5;28m",     # Deep forest green
            "orange": "\033[38;5;166m",   # Deep burnt orange
            "purple": "\033[38;5;91m",    # Deep royal purple
            "cyan": "\033[38;5;30m",      # Deep peacock teal
            "yellow": "\033[38;5;130m",   # Rich golden amber
            "red": "\033[38;5;160m",      # Crimson red
        }
    else:
        return {
            "title": "\033[38;5;220m",    # Bright gold
            "divider": "\033[38;5;141m",  # Lavender purple
            "thin_div": "\033[38;5;244m", # Soft gray
            "head": "\033[38;5;255m",     # Bright white header
            "text": "\033[38;5;253m",     # Light foreground body text
            "muted": "\033[38;5;245m",    # Muted gray
            "bullet": "\033[38;5;245m",   # Bullet dot
            "blue": "\033[38;5;75m",      # Sky blue
            "magenta": "\033[38;5;207m",  # Bright magenta
            "green": "\033[38;5;84m",     # Mint green
            "orange": "\033[38;5;208m",   # Bright orange
            "purple": "\033[38;5;141m",   # Lavender purple
            "cyan": "\033[38;5;51m",      # Electric cyan
            "yellow": "\033[38;5;220m",   # Bright yellow
            "red": "\033[38;5;196m",      # Bright red
        }


def style(text: str, color_key: str = "text") -> str:
    """Wrap text in the active palette color followed by RESET."""
    palette = get_palette()
    code = palette.get(color_key, palette["text"])
    return f"{code}{text}{RESET}"
