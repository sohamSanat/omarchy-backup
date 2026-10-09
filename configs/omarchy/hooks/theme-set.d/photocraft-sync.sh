#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for PhotoCraft
# ------------------------------------------------------------------------------
# Invoked automatically by Omarchy on every theme change (omarchy theme set <name>).
# Delegates synchronization to ~/.local/bin/omarchy-sync-photocraft.
# ==============================================================================

if [[ -x "$HOME/.local/bin/omarchy-sync-photocraft" ]]; then
  "$HOME/.local/bin/omarchy-sync-photocraft" "$@" 2>/dev/null || true
fi
