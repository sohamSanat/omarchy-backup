#!/usr/bin/env bash
set -e

# ==============================================================================
# Uninstaller for the system-wide Omarchy Gemini / Antigravity Agent Collector
# https://github.com/Chispes/omarchy-agent-gemini
#
# This undoes install.sh only. If the plugin itself is still enabled, its
# service keeps refreshing the usage record from the copy of the collector
# inside the plugin directory, and the Gemini tab stays. To remove the plugin:
#   omarchy plugin remove chispes.agent-gemini
# ==============================================================================

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
BIN_DEST="/usr/bin/omarchy-agent-usage-gemini"
OMARCHY_BIN_LINK="$OMARCHY_PATH/bin/omarchy-agent-usage-gemini"
ASSETS_DEST="$OMARCHY_PATH/shell/plugins/agents/assets"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/agents/usage/gemini.json"

echo "==> Uninstalling Omarchy Gemini Usage Collector..."

# Remove binaries and symlinks
if [ -f "$BIN_DEST" ]; then
    echo "--> Removing $BIN_DEST..."
    sudo rm -f "$BIN_DEST"
fi

if [ -L "$OMARCHY_BIN_LINK" ] || [ -f "$OMARCHY_BIN_LINK" ]; then
    echo "--> Removing $OMARCHY_BIN_LINK..."
    sudo rm -f "$OMARCHY_BIN_LINK"
fi

# Remove assets
if [ -f "$ASSETS_DEST/gemini.svg" ]; then
    echo "--> Removing $ASSETS_DEST/gemini.svg..."
    sudo rm -f "$ASSETS_DEST/gemini.svg"
fi

if [ -f "$ASSETS_DEST/gemini-light.svg" ]; then
    echo "--> Removing $ASSETS_DEST/gemini-light.svg..."
    sudo rm -f "$ASSETS_DEST/gemini-light.svg"
fi

# Remove generated usage state
if [ -f "$STATE_FILE" ]; then
    echo "--> Removing state file $STATE_FILE..."
    rm -f "$STATE_FILE"
fi

# Passed through explicitly: run under sudo the environment is reset, and the
# update would then glob /bin instead of Omarchy's own bin and refresh nothing.
echo "--> Refreshing Omarchy agents..."
if command -v omarchy-agent-usage-update >/dev/null 2>&1; then
    OMARCHY_PATH="$OMARCHY_PATH" omarchy-agent-usage-update --force || true
fi

echo ""
echo "✅ System-wide Gemini Agent collector removed."
echo "The plugin itself, if still enabled, keeps its own tab:"
echo "  omarchy plugin remove chispes.agent-gemini"
