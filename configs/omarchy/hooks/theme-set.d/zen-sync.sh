#!/bin/bash
# Hook triggered on Omarchy theme-set to sync Zen Browser
if [[ -x "$HOME/.local/bin/omarchy-sync-zen" ]]; then
  "$HOME/.local/bin/omarchy-sync-zen" 2>/dev/null || true
fi
