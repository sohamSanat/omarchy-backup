#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for WordCraft
# ------------------------------------------------------------------------------
# Invoked automatically by Omarchy on every theme change (omarchy theme set <name>).
# Delegates synchronization to ~/.local/bin/omarchy-sync-wordcraft.
# ==============================================================================

if [[ -x "$HOME/.local/bin/omarchy-sync-wordcraft" ]]; then
  "$HOME/.local/bin/omarchy-sync-wordcraft" "$@" 2>/dev/null || true
fi
