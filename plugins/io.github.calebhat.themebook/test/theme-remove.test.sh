#!/bin/bash
# Test theme-remove script logic
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)

# 1. Test slug validation
if "$root/scripts/theme-remove" "" 2>/dev/null; then
  echo "Expected error on empty slug" >&2; exit 1
fi
if "$root/scripts/theme-remove" "../bad" 2>/dev/null; then
  echo "Expected error on path traversal slug" >&2; exit 1
fi
if "$root/scripts/theme-remove" "bad slug!" 2>/dev/null; then
  echo "Expected error on special chars in slug" >&2; exit 1
fi

# 2. Test isolated removal
fake=$(mktemp -d)
trap 'rm -rf "$fake"' EXIT

mkdir -p "$fake/home/.config/omarchy/themes/test-user-theme"
mkdir -p "$fake/home/.config/omarchy/backgrounds/test-user-theme"
mkdir -p "$fake/home/.cache/omarchy/theme-selector/previews"
touch "$fake/home/.cache/omarchy/theme-selector/previews/test-user-theme.png"
touch "$fake/home/.config/omarchy/themes/test-user-theme/colors.toml"

HOME="$fake/home" "$root/scripts/theme-remove" "test-user-theme" >/dev/null 2>&1 || true

if [[ -d "$fake/home/.config/omarchy/themes/test-user-theme" ]]; then
  echo "User theme was not deleted" >&2; exit 1
fi
if [[ -d "$fake/home/.config/omarchy/backgrounds/test-user-theme" ]]; then
  echo "Backgrounds were not deleted" >&2; exit 1
fi
if [[ -f "$fake/home/.cache/omarchy/theme-selector/previews/test-user-theme.png" ]]; then
  echo "Preview cache was not deleted" >&2; exit 1
fi

echo "theme-remove ok"
