#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for FilmCraft
# ------------------------------------------------------------------------------
# Invoked automatically by Omarchy on every theme change (omarchy theme set <name>).
# Delegates synchronization to ~/.local/bin/omarchy-sync-filmcraft.
# ==============================================================================

if [[ -x "$HOME/.local/bin/omarchy-sync-filmcraft" ]]; then
  "$HOME/.local/bin/omarchy-sync-filmcraft" 2>/dev/null || true
fi
