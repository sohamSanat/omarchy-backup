#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for Zen Browser
# ------------------------------------------------------------------------------
# Invoked automatically by Omarchy on every theme change (omarchy theme set <name>).
# Delegates synchronization to ~/.local/bin/omarchy-sync-zen.
# ==============================================================================

if [[ -x "$HOME/.local/bin/omarchy-sync-zen" ]]; then
  "$HOME/.local/bin/omarchy-sync-zen" --sync 2>/dev/null || true
fi
