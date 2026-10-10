#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for EffectCraft
# ------------------------------------------------------------------------------
# Invoked automatically by Omarchy on every theme change (omarchy theme set <name>).
# Delegates synchronization to ~/.local/bin/omarchy-sync-effectcraft.
# ==============================================================================

if [[ -x "$HOME/.local/bin/omarchy-sync-effectcraft" ]]; then
  "$HOME/.local/bin/omarchy-sync-effectcraft" 2>/dev/null || true
fi
