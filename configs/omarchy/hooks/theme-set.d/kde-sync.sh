#!/bin/bash
# Hook triggered on Omarchy theme-set to sync KDE/Qt applications (like KDE Connect)
if [[ -x "$HOME/.local/bin/omarchy-sync-kde" ]]; then
  "$HOME/.local/bin/omarchy-sync-kde" 2>/dev/null || true
fi
