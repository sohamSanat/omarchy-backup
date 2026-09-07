#!/bin/bash
# Hook triggered on Omarchy theme-set to sync terminal theme mode and environment across all sessions
THEME_NAME="$1"

if [[ -x "$HOME/.local/bin/omarchy-theme-env" ]]; then
  "$HOME/.local/bin/omarchy-theme-env" --sync >/dev/null 2>&1 || true
fi

# If tmux is active, propagate COLORFGBG and OMARCHY_THEME_MODE into tmux environment
if command -v tmux &>/dev/null; then
  if tmux list-sessions &>/dev/null; then
    source "$HOME/.local/state/omarchy/theme-mode.env" 2>/dev/null || true
    tmux set-environment -g OMARCHY_THEME_MODE "$OMARCHY_THEME_MODE" 2>/dev/null || true
    tmux set-environment -g OMARCHY_THEME_NAME "$OMARCHY_THEME_NAME" 2>/dev/null || true
    tmux set-environment -g COLORFGBG "$COLORFGBG" 2>/dev/null || true
  fi
fi
