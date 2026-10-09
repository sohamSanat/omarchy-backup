#!/usr/bin/env bash
# ==============================================================================
# VectorCraft Standalone Installer / Restorer for Omarchy Linux
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="${HOME}/.local/bin"
TARGET_CONFIG="${HOME}/.config/vectorcraft"
TARGET_HOOKS="${HOME}/.config/omarchy/hooks/theme-set.d"
TARGET_DESKTOP="${HOME}/.local/share/applications"
TARGET_ICONS="${HOME}/.local/share/icons/hicolor"

echo "==> Installing VectorCraft for Omarchy Linux..."

# 1. Unpack release binaries
mkdir -p "${TARGET_BIN}"
if [[ -f "${SCRIPT_DIR}/build/vectorcraft-linux-x86_64.tar.xz" ]]; then
  echo "  -> Extracting precompiled release build to ${TARGET_BIN}..."
  tar -xJf "${SCRIPT_DIR}/build/vectorcraft-linux-x86_64.tar.xz" -C "${TARGET_BIN}" --strip-components=1
  chmod +x "${TARGET_BIN}/vectorcraft" "${TARGET_BIN}/vectorcraft.real" "${TARGET_BIN}/vectorcraft-cli" "${TARGET_BIN}/omarchy-sync-vectorcraft"
else
  echo "  [ERROR] Release archive build/vectorcraft-linux-x86_64.tar.xz not found!"
  exit 1
fi

# 2. Install desktop entry
mkdir -p "${TARGET_DESKTOP}"
if [[ -f "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.vectorcraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.vectorcraft.desktop" "${TARGET_DESKTOP}/"
elif [[ -f "${SCRIPT_DIR}/ai.storyteller.vectorcraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/ai.storyteller.vectorcraft.desktop" "${TARGET_DESKTOP}/"
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${TARGET_DESKTOP}" 2>/dev/null || true
fi

# 3. Install icons
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

# 4. Restore configurations (if not already present)
mkdir -p "${TARGET_CONFIG}"
for cfg in ui.json theme.json; do
  if [[ -f "${SCRIPT_DIR}/../../configs/vectorcraft/${cfg}" && ! -f "${TARGET_CONFIG}/${cfg}" ]]; then
    cp -a "${SCRIPT_DIR}/../../configs/vectorcraft/${cfg}" "${TARGET_CONFIG}/"
  fi
done

# 5. Install theme synchronization hook
mkdir -p "${TARGET_HOOKS}"
if [[ -f "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/vectorcraft-sync.sh" ]]; then
  cp -a "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/vectorcraft-sync.sh" "${TARGET_HOOKS}/"
  chmod +x "${TARGET_HOOKS}/vectorcraft-sync.sh"
fi

# 6. Sync current active theme immediately
if [[ -x "${TARGET_BIN}/omarchy-sync-vectorcraft" ]]; then
  "${TARGET_BIN}/omarchy-sync-vectorcraft" 2>/dev/null || true
fi

echo "==> [OK] VectorCraft successfully installed and integrated with Omarchy Linux!"
