#!/usr/bin/env bash
# ==============================================================================
# CraftCloud Standalone Installer / Restorer for Omarchy Linux
# Creative Suite Command Center & Unified Hub for Craft Applications
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="${HOME}/.local/bin"
TARGET_DESKTOP="${HOME}/.local/share/applications"
TARGET_ICONS="${HOME}/.local/share/icons/hicolor"
TARGET_PROJECTS="${HOME}/craftcloud"

echo "==> Installing CraftCloud for Omarchy Linux..."

# 1. Unpack release binary if archive exists
mkdir -p "${TARGET_BIN}"
if [[ -f "${SCRIPT_DIR}/build/craftcloud-linux-x86_64.tar.xz" ]]; then
  echo "  -> Extracting precompiled release build to ${TARGET_BIN}..."
  tar -xJf "${SCRIPT_DIR}/build/craftcloud-linux-x86_64.tar.xz" -C "${TARGET_BIN}" --strip-components=1
  chmod +x "${TARGET_BIN}/craftcloud"
elif [[ -f "${SCRIPT_DIR}/../../bin/craftcloud" ]]; then
  cp -a "${SCRIPT_DIR}/../../bin/craftcloud" "${TARGET_BIN}/craftcloud"
  chmod +x "${TARGET_BIN}/craftcloud"
fi

# 2. Restore CraftCloud source repository if missing
if [[ ! -d "${TARGET_PROJECTS}/src" && -d "${SCRIPT_DIR}/source" ]]; then
  echo "  -> Restoring CraftCloud source code to ${TARGET_PROJECTS}..."
  mkdir -p "${TARGET_PROJECTS}"
  cp -a "${SCRIPT_DIR}/source/." "${TARGET_PROJECTS}/"
fi

# 3. Install desktop entry
mkdir -p "${TARGET_DESKTOP}"
if [[ -f "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.craftcloud.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.craftcloud.desktop" "${TARGET_DESKTOP}/"
elif [[ -f "${SCRIPT_DIR}/ai.storyteller.craftcloud.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/ai.storyteller.craftcloud.desktop" "${TARGET_DESKTOP}/"
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${TARGET_DESKTOP}" 2>/dev/null || true
fi

# 4. Install icons
if [[ -d "${SCRIPT_DIR}/icons/hicolor" ]]; then
  echo "  -> Installing application icons..."
  for size_dir in "${SCRIPT_DIR}/icons/hicolor"/*; do
    if [[ -d "$size_dir" ]]; then
      size_name="$(basename "$size_dir")"
      mkdir -p "${TARGET_ICONS}/${size_name}/apps"
      cp -a "${size_dir}/apps/"* "${TARGET_ICONS}/${size_name}/apps/" 2>/dev/null || true
    fi
  done
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "${TARGET_ICONS}" 2>/dev/null || true
  fi
fi

echo "==> [OK] CraftCloud successfully installed and registered with Omarchy Linux!"
