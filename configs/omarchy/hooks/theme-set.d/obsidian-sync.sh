#!/bin/bash
# Hook triggered on Omarchy theme-set
if [[ -x "$HOME/.local/bin/omarchy-sync-obsidian" ]]; then
  "$HOME/.local/bin/omarchy-sync-obsidian" 2>/dev/null || true
fi
