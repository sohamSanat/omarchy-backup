#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for GridCraft
# ------------------------------------------------------------------------------
# Invoked automatically by Omarchy on every theme change (omarchy theme set <name>).
# Delegates synchronization to ~/.local/bin/omarchy-sync-gridcraft.
# ==============================================================================

if [[ -x "$HOME/.local/bin/omarchy-sync-gridcraft" ]]; then
  "$HOME/.local/bin/omarchy-sync-gridcraft" "$@" 2>/dev/null || true
fi
