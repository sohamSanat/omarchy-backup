#!/usr/bin/env bash
# Hook to ring a "ting" and terminal bell whenever Antigravity CLI prompts
# the user for manual input in selecting an option (e.g. ask_question).

set -euo pipefail

PAYLOAD=$(cat 2>/dev/null || true)

TOOL_NAME=""
if [ -n "$PAYLOAD" ]; then
  TOOL_NAME=$(python3 -c '
import sys, json
try:
    d = json.loads(sys.argv[1])
    tc = d.get("toolCall", {})
    print(tc.get("name", ""))
except Exception:
    pass
' "$PAYLOAD" 2>/dev/null || true)
fi

# Log for verification
echo "$(date -Is) - PreToolUse hook invoked for tool: '$TOOL_NAME'" >> /home/soham/.gemini/antigravity-cli/ring-ting.log 2>/dev/null || true

# If this is an option selection prompt (ask_question)
if [[ "$TOOL_NAME" =~ (ask_question|askQuestion|question) ]]; then
  (
    SOUND_FILE="/home/soham/.gemini/antigravity-cli/sounds/ting.wav"
    if [ ! -f "$SOUND_FILE" ]; then
      SOUND_FILE="/usr/share/sounds/freedesktop/stereo/bell.oga"
    fi

    # 1. Primary audio: play pleasant "ting" sound
    if command -v pw-play >/dev/null 2>&1 && [ -f "$SOUND_FILE" ]; then
      pw-play "$SOUND_FILE" < /dev/null 2>/dev/null || true
    elif command -v canberra-gtk-play >/dev/null 2>&1; then
      canberra-gtk-play -i bell -d "antigravity" 2>/dev/null || true
    elif command -v paplay >/dev/null 2>&1 && [ -f /usr/share/sounds/freedesktop/stereo/bell.oga ]; then
      paplay /usr/share/sounds/freedesktop/stereo/bell.oga < /dev/null 2>/dev/null || true
    elif command -v mpv >/dev/null 2>&1 && [ -f /usr/share/sounds/freedesktop/stereo/bell.oga ]; then
      mpv --no-video --really-quiet /usr/share/sounds/freedesktop/stereo/bell.oga < /dev/null 2>/dev/null || true
    fi

    # 2. Terminal BEL: emit ASCII 0x07 (\a) to active TTY / PTS to trigger terminal visual/audio bell
    if [ -w /dev/tty ]; then
      printf '\a' > /dev/tty 2>/dev/null || true
    fi

    for pt in /dev/pts/*; do
      if [ -w "$pt" ] && [ "$pt" != "/dev/pts/ptmx" ]; then
        printf '\a' > "$pt" 2>/dev/null || true
      fi
    done

    echo "$(date -Is) - ting rung successfully for $TOOL_NAME" >> /home/soham/.gemini/antigravity-cli/ring-ting.log 2>/dev/null || true
  ) >/dev/null 2>&1 & disown
fi

# Output allow decision for PreToolUse
printf '{"decision": "allow"}\n'
exit 0
