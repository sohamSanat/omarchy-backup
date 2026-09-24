#!/bin/bash
set -euo pipefail

PRESET_NAME="${1:-}"

if [[ -z "$PRESET_NAME" ]]; then
  echo "Error: No preset name provided" >&2
  exit 1
fi

# Protect stock baseline preset
if [[ "${PRESET_NAME,,}" =~ stock ]]; then
  echo "Error: Cannot purge stock preset: $PRESET_NAME" >&2
  exit 1
fi

PRESET_DIR="$HOME/.local/share/easyeffects/output"
PRESET_FILE="$PRESET_DIR/$PRESET_NAME.json"

# 1. Remove EasyEffects preset file
if [[ -f "$PRESET_FILE" ]]; then
  rm -f "$PRESET_FILE"
  echo "Purged EasyEffects preset file: $PRESET_FILE"
fi

# 2. If this preset was currently active in EasyEffects, fallback to Stock preset
CURRENT_ACTIVE=$(easyeffects -s 2>/dev/null | grep -i '^output:' | sed 's/^output:\s*//I' | xargs)
if [[ "$CURRENT_ACTIVE" == "$PRESET_NAME" ]]; then
  STOCK_PRESET=$(find "$PRESET_DIR" -maxdepth 1 -name "*[sS]tock*.json" -printf "%f\n" 2>/dev/null | sed 's/\.json$//' | head -n 1)
  if [[ -n "$STOCK_PRESET" ]]; then
    easyeffects -l "$STOCK_PRESET" 2>/dev/null || true
    echo "Switched active preset back to stock: $STOCK_PRESET"
  else
    easyeffects -b 1 2>/dev/null || true
    echo "Bypassed equalizer (no stock preset found)"
  fi
fi

# 3. Clean up matching raw AutoEQ download files in ~/Downloads
DOWNLOADS_DIR="$HOME/Downloads"
if [[ -d "$DOWNLOADS_DIR" ]]; then
  python3 -c '
import os, sys

preset = sys.argv[1].lower()
# Clean punctuation and split into significant search tokens
for ch in "-_()[]":
    preset = preset.replace(ch, " ")
tokens = [t for t in preset.split() if len(t) > 2 and t not in ["crinear", "tangzu", "waner", "red", "lion", "iem", "the"]]

if not tokens:
    sys.exit(0)

dl = os.path.expanduser("~/Downloads")
for f in os.listdir(dl):
    lf = f.lower()
    if lf.endswith(".txt") and any(t in lf for t in tokens):
        p = os.path.join(dl, f)
        try:
            os.remove(p)
            print("Purged matching download file:", p)
        except Exception as e:
            print("Error removing download file:", p, e, file=sys.stderr)
' "$PRESET_NAME"
fi

# 4. Notify desktop
notify-send -a "EasyEffects" "Preset Purged" "Purged '$PRESET_NAME' and associated files from system." 2>/dev/null || true

echo "Purge complete: $PRESET_NAME"
