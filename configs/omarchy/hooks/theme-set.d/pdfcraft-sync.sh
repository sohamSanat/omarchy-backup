#!/bin/bash
# ==============================================================================
# Omarchy Theme-Set Hook for PdfCraft
# ------------------------------------------------------------------------------
# Invoked automatically by Omarchy on every theme change (omarchy theme set <name>).
# Delegates synchronization to ~/.local/bin/omarchy-sync-pdfcraft.
# ==============================================================================

if [[ -x "$HOME/.local/bin/omarchy-sync-pdfcraft" ]]; then
  "$HOME/.local/bin/omarchy-sync-pdfcraft" 2>/dev/null || true
fi
