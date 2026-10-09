#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for VectorCraft
# ------------------------------------------------------------------------------
# Invoked automatically by Omarchy on every theme change (omarchy theme set <name>).
# Delegates synchronization to ~/.local/bin/omarchy-sync-vectorcraft.
# ==============================================================================

if [[ -x "$HOME/.local/bin/omarchy-sync-vectorcraft" ]]; then
  "$HOME/.local/bin/omarchy-sync-vectorcraft" "$@" 2>/dev/null || true
fi

