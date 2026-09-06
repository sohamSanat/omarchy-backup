#!/bin/bash
# omarchy-theme.sh: Universal theme detection and high-contrast color palette for Bash scripts.
# Sourcing this file automatically configures high-contrast terminal styling for the active Omarchy theme.
#
# Usage in any script:
#   source /home/soham/.local/lib/omarchy-theme.sh
#   echo -e "${COLOR_BLUE}${COLOR_BOLD}Header${COLOR_RESET}"
#   echo -e "  ${COLOR_TEXT}High-contrast body text${COLOR_RESET}"
#   echo -e "  ${COLOR_MUTED}Readable secondary text (never dim)${COLOR_RESET}"

# Ensure theme-mode.env is up-to-date and sourced
if [[ -f "$HOME/.local/state/omarchy/theme-mode.env" ]]; then
  source "$HOME/.local/state/omarchy/theme-mode.env"
elif command -v omarchy-theme-env &>/dev/null; then
  omarchy-theme-env --sync >/dev/null 2>&1
  [[ -f "$HOME/.local/state/omarchy/theme-mode.env" ]] && source "$HOME/.local/state/omarchy/theme-mode.env"
fi

THEME_MODE="${OMARCHY_THEME_MODE:-dark}"
THEME_NAME="${OMARCHY_THEME_NAME:-unknown}"

is_light_theme() {
  [[ "$THEME_MODE" == "light" ]]
}

COLOR_RESET="\033[0m"
COLOR_BOLD="\033[1m"
COLOR_ITALIC="\033[3m"
COLOR_DIM="\033[2m"

if is_light_theme; then
  COLOR_TITLE="\033[38;5;130m"     # Deep amber/bronze
  COLOR_DIVIDER="\033[38;5;54m"    # Deep royal plum
  COLOR_THIN_DIV="\033[38;5;240m"  # Readable slate
  COLOR_HEAD="\033[38;5;234m"      # Deep charcoal/black
  COLOR_TEXT="\033[38;5;235m"      # Crisp dark charcoal body text (never white/gray)
  COLOR_MUTED="\033[38;5;240m"     # Readable slate (never washed-out DIM)
  COLOR_BULLET="\033[38;5;240m"    # Visible bullet
  COLOR_BLUE="\033[38;5;25m"       # Deep cobalt blue
  COLOR_MAGENTA="\033[38;5;127m"   # Deep raspberry/magenta
  COLOR_GREEN="\033[38;5;28m"      # Deep forest green
  COLOR_ORANGE="\033[38;5;166m"    # Deep burnt orange
  COLOR_PURPLE="\033[38;5;91m"     # Deep royal purple
  COLOR_CYAN="\033[38;5;30m"       # Deep peacock teal
  COLOR_YELLOW="\033[38;5;130m"    # Rich golden amber
  COLOR_RED="\033[38;5;160m"       # Crimson red
else
  COLOR_TITLE="\033[38;5;220m"     # Bright gold
  COLOR_DIVIDER="\033[38;5;141m"   # Lavender purple
  COLOR_THIN_DIV="\033[38;5;244m"  # Soft gray
  COLOR_HEAD="\033[38;5;255m"      # Bright white header
  COLOR_TEXT="\033[38;5;253m"      # Light foreground body text
  COLOR_MUTED="\033[38;5;245m"     # Muted gray
  COLOR_BULLET="\033[38;5;245m"    # Bullet dot
  COLOR_BLUE="\033[38;5;75m"       # Sky blue
  COLOR_MAGENTA="\033[38;5;207m"   # Bright magenta
  COLOR_GREEN="\033[38;5;84m"      # Mint green
  COLOR_ORANGE="\033[38;5;208m"    # Bright orange
  COLOR_PURPLE="\033[38;5;141m"    # Lavender purple
  COLOR_CYAN="\033[38;5;51m"       # Electric cyan
  COLOR_YELLOW="\033[38;5;220m"    # Bright yellow
  COLOR_RED="\033[38;5;196m"       # Bright red
fi
