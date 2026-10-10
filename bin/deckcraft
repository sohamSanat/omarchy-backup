#!/usr/bin/env bash
# ==============================================================================
# DeckCraft launcher wrapper for Omarchy Linux
# ------------------------------------------------------------------------------
# 1. Enables loopback control server on port 48295 so Omarchy theme changes update live
# 2. Exposes DECKCRAFT_THEME_FILE for live dynamic per-theme color customization
# 3. Unsets WAYLAND_DISPLAY by default so XWayland enables file drag & drop.
#    Set DECKCRAFT_FORCE_WAYLAND=1 to force native Wayland.
# ==============================================================================

export DECKCRAFT_CONTROL_PORT="${DECKCRAFT_CONTROL_PORT:-48295}"
export DECKCRAFT_THEME_FILE="${DECKCRAFT_THEME_FILE:-$HOME/.config/deckcraft/theme.json}"

# Ensure initial theme.json is populated from current Omarchy theme
if [[ ! -f "$DECKCRAFT_THEME_FILE" ]]; then
  "$HOME/.local/bin/omarchy-sync-deckcraft" 2>/dev/null || true
fi

if [[ -n "${DECKCRAFT_FORCE_WAYLAND:-}" ]]; then
  export DECKCRAFT_WAYLAND=1
else
  unset WAYLAND_DISPLAY
fi

exec "$HOME/.local/bin/deckcraft.real" "$@"
