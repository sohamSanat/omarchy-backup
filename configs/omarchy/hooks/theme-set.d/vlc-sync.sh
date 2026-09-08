#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for VLC Media Player
# ------------------------------------------------------------------------------
# Invoked automatically by Omarchy on every theme change
# (omarchy theme set <name>). Delegates synchronization to
# ~/.local/bin/omarchy-sync-vlc, which derives VLC's slider colors and
# dark mode from the active theme's colors.toml.
# ==============================================================================

if [[ -x "$HOME/.local/bin/omarchy-sync-vlc" ]]; then
  "$HOME/.local/bin/omarchy-sync-vlc" --sync 2>/dev/null || true
fi
