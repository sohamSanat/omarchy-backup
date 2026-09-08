#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for Brave-Origin
# ------------------------------------------------------------------------------
# Invoked automatically by Omarchy on every theme change (omarchy theme set <name>).
# Delegates synchronization to ~/.local/bin/omarchy-sync-brave.
# Toolbar color itself is handled by stock omarchy-theme-set-browser policy.
# ==============================================================================

if [[ -x "$HOME/.local/bin/omarchy-sync-brave" ]]; then
  "$HOME/.local/bin/omarchy-sync-brave" --sync 2>/dev/null || true
fi
