#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for LightCraft
# ------------------------------------------------------------------------------
# Invoked automatically by Omarchy on every theme change (omarchy theme set <name>).
# Delegates synchronization to ~/.local/bin/omarchy-sync-lightcraft.
# ==============================================================================

if [[ -x "$HOME/.local/bin/omarchy-sync-lightcraft" ]]; then
  "$HOME/.local/bin/omarchy-sync-lightcraft" 2>/dev/null || true
fi
