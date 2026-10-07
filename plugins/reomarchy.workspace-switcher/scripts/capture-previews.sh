#!/usr/bin/env bash
# Captures one PNG per currently visible workspace (one per monitor) with
# grim, BEFORE the switcher overlay is summoned, and records them in
# manifest.json. The QML overlay reads that manifest and paints the PNGs as
# the per-workspace previews.
set -u
export PATH=/usr/bin:/bin

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/reomarchy-workspace-switcher"
mkdir -p "$CACHE"

ts=$(date +%s%N)
pairs=$(mktemp "$CACHE/pairs.XXXXXX")
trap 'rm -f "$pairs"' EXIT

hyprctl -j monitors | jq -r '.[] | select(.activeWorkspace.id != null) | "\(.name)\t\(.activeWorkspace.id)"' | \
  while IFS=$'\t' read -r mname wsid; do
    out="$CACHE/ws-${wsid}-${ts}.png"
    if grim -o "$mname" "$out" 2>/dev/null; then
      printf '%s\t%s\t%s\n' "$wsid" "$out" "$mname" >> "$pairs"
    fi
  done

old="$CACHE/manifest.json"
new_ws=$(jq -Rs --argjson ts "$ts" '
  split("\n") | map(select(length > 0)) | map(split("\t")) |
  {ts: $ts, workspaces: (map({(.[0]): {path: .[1], monitor: .[2]}}) | add // {})}' "$pairs")

# Merge: fresh captures override, older entries (hidden workspaces) persist
# until their PNG is pruned below.
if [ -s "$old" ]; then
  merged=$(jq -s '.[0] as $o | .[1] as $n |
    {ts: $n.ts, workspaces: (($o.workspaces // {}) * ($n.workspaces // {}))}' \
    "$old" <(printf '%s\n' "$new_ws") 2>/dev/null) || merged="$new_ws"
else
  merged="$new_ws"
fi

tmp="$CACHE/manifest.json.tmp"
printf '%s\n' "$merged" > "$tmp"
mv "$tmp" "$old"

# Prune captures older than a day so the cache cannot grow forever.
find "$CACHE" -maxdepth 1 -name 'ws-*.png' -mmin +1440 -delete 2>/dev/null || true
exit 0
