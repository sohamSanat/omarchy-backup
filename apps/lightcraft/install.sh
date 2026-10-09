#!/usr/bin/env bash
# ==============================================================================
# LightCraft Standalone Installer / Restorer for Omarchy Linux
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="${HOME}/.local/bin"
TARGET_CONFIG="${HOME}/.config/lightcraft"
TARGET_HOOKS="${HOME}/.config/omarchy/hooks/theme-set.d"
TARGET_DESKTOP="${HOME}/.local/share/applications"
TARGET_METAINFO="${HOME}/.local/share/metainfo"
TARGET_MIME="${HOME}/.local/share/mime/packages"
TARGET_ICONS="${HOME}/.local/share/icons/hicolor"

echo "==> Installing LightCraft for Omarchy Linux..."

# 1. Unpack release binaries
mkdir -p "${TARGET_BIN}"
if [[ -f "${SCRIPT_DIR}/build/lightcraft-linux-x86_64.tar.xz" ]]; then
  echo "  -> Extracting precompiled release build to ${TARGET_BIN}..."
  tar -xJf "${SCRIPT_DIR}/build/lightcraft-linux-x86_64.tar.xz" -C "${TARGET_BIN}" --strip-components=1
  chmod +x "${TARGET_BIN}/lightcraft" "${TARGET_BIN}/lightcraft.real" "${TARGET_BIN}/lightcraft-cli" "${TARGET_BIN}/omarchy-sync-lightcraft"
else
  echo "  [ERROR] Release archive build/lightcraft-linux-x86_64.tar.xz not found!"
  exit 1
fi

# 2. Install desktop entry, metainfo, and MIME package
mkdir -p "${TARGET_DESKTOP}" "${TARGET_METAINFO}" "${TARGET_MIME}"
if [[ -f "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.lightcraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.lightcraft.desktop" "${TARGET_DESKTOP}/"
elif [[ -f "${SCRIPT_DIR}/ai.storyteller.lightcraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/ai.storyteller.lightcraft.desktop" "${TARGET_DESKTOP}/"
fi
if [[ -f "${SCRIPT_DIR}/metainfo/ai.storyteller.lightcraft.metainfo.xml" ]]; then
  cp -a "${SCRIPT_DIR}/metainfo/ai.storyteller.lightcraft.metainfo.xml" "${TARGET_METAINFO}/"
fi
if [[ -f "${SCRIPT_DIR}/mime/ai.storyteller.lightcraft.xml" ]]; then
  cp -a "${SCRIPT_DIR}/mime/ai.storyteller.lightcraft.xml" "${TARGET_MIME}/"
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${TARGET_DESKTOP}" 2>/dev/null || true
fi
if command -v update-mime-database >/dev/null 2>&1; then
  update-mime-database "${HOME}/.local/share/mime" 2>/dev/null || true
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

# 4. Restore configurations & UI preferences (if not already present)
mkdir -p "${TARGET_CONFIG}"
for cfg in theme.json ui.json; do
  if [[ -f "${SCRIPT_DIR}/../../configs/lightcraft/${cfg}" && ! -f "${TARGET_CONFIG}/${cfg}" ]]; then
    cp -a "${SCRIPT_DIR}/../../configs/lightcraft/${cfg}" "${TARGET_CONFIG}/"
  fi
done

# 5. Install theme synchronization hook
mkdir -p "${TARGET_HOOKS}"
if [[ -f "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/lightcraft-sync.sh" ]]; then
  cp -a "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/lightcraft-sync.sh" "${TARGET_HOOKS}/"
  chmod +x "${TARGET_HOOKS}/lightcraft-sync.sh"
fi

# 6. Sync current active theme immediately
if [[ -x "${TARGET_BIN}/omarchy-sync-lightcraft" ]]; then
  "${TARGET_BIN}/omarchy-sync-lightcraft" 2>/dev/null || true
fi

echo "==> [OK] LightCraft successfully installed and integrated with Omarchy Linux!"
