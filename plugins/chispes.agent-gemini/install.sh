#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# System-wide installer for the Omarchy Gemini / Antigravity Agent Collector
# https://github.com/Chispes/omarchy-agent-gemini
#
# OPTIONAL. Installed as a plugin (`omarchy plugin add ... --enable`), the
# Gemini tab already appears: the plugin's own service runs the bundled
# collector and writes the usage record, no root involved. This script is for
# the two things that genuinely need root, and nothing else:
#
#   /usr/bin/omarchy-agent-usage-gemini                    the collector, so it
#   $OMARCHY_PATH/bin/omarchy-agent-usage-gemini           refreshes alongside
#                                                          Omarchy's own agents
#   $OMARCHY_PATH/shell/plugins/agents/assets/gemini*.svg  the Gemini mark, in
#                                                          place of the bar glyph
#
# No user configuration is read or written.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$SCRIPT_DIR/bin/omarchy-agent-usage-gemini"
ASSETS_SRC="$SCRIPT_DIR/assets"

OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
BIN_DEST="/usr/bin/omarchy-agent-usage-gemini"
OMARCHY_BIN_DIR="$OMARCHY_PATH/bin"
ASSETS_DEST="$OMARCHY_PATH/shell/plugins/agents/assets"

fail() {
  echo "install.sh: $*" >&2
  exit 1
}

echo "==> Installing Omarchy Gemini Usage Collector system-wide..."

[ -f "$BIN_SRC" ] || fail "collector missing at $BIN_SRC"
command -v python3 >/dev/null 2>&1 || fail "python3 is required to run the collector"

# omarchy-agent-usage-update discovers collectors by globbing
# "$OMARCHY_PATH"/bin/omarchy-agent-usage-* and nothing else, so without that
# directory the collector would install and then never be run by anything.
# Skipping the link quietly is how an install "succeeds" and does nothing.
[ -d "$OMARCHY_BIN_DIR" ] || fail "$OMARCHY_BIN_DIR not found -- is Omarchy installed?"

chmod +x "$BIN_SRC"

echo "--> Installing $BIN_DEST..."
sudo install -m 755 "$BIN_SRC" "$BIN_DEST"

echo "--> Linking $OMARCHY_BIN_DIR/omarchy-agent-usage-gemini..."
sudo ln -sf "$BIN_DEST" "$OMARCHY_BIN_DIR/omarchy-agent-usage-gemini"

# The mark is genuinely optional: the agents panel falls back to its bar glyph
# for a provider that ships no assets/<id>.svg, so a missing directory here
# costs an icon, not the feature.
if [ -d "$ASSETS_DEST" ]; then
  echo "--> Installing icons to $ASSETS_DEST..."
  for icon in gemini.svg gemini-light.svg; do
    if [ -f "$ASSETS_SRC/$icon" ]; then
      sudo install -m 644 "$ASSETS_SRC/$icon" "$ASSETS_DEST/$icon"
    fi
  done
else
  echo "--> Icons skipped ($ASSETS_DEST not found); the panel will use its bar glyph."
fi

# Refresh as the invoking user: the record belongs under their XDG state dir,
# and running the collector as root would write it into root's.
#
# OMARCHY_PATH is passed through explicitly because sudo resets the
# environment. Without it the update globs /bin/omarchy-agent-usage-* instead
# of Omarchy's own bin, finds no collectors at all, and still exits 0 -- an
# install that reports success and refreshes nothing.
echo "--> Updating agent usage data..."
RUN_USER="${SUDO_USER:-$USER}"
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
  sudo -u "$RUN_USER" env OMARCHY_PATH="$OMARCHY_PATH" \
    omarchy-agent-usage-update gemini --force || true
else
  OMARCHY_PATH="$OMARCHY_PATH" omarchy-agent-usage-update gemini --force || true
fi

echo ""
echo "✅ Gemini Agent collector installed system-wide!"
echo "Open the agents panel or refresh with: omarchy agent usage-update"
