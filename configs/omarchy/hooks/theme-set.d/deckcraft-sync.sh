#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for DeckCraft
# ------------------------------------------------------------------------------
# Invoked automatically by Omarchy on every theme change (omarchy theme set <name>).
# Delegates synchronization to ~/.local/bin/omarchy-sync-deckcraft.
# ==============================================================================

if [[ -x "$HOME/.local/bin/omarchy-sync-deckcraft" ]]; then
  "$HOME/.local/bin/omarchy-sync-deckcraft" "$@" 2>/dev/null || true
fi
