#!/usr/bin/env bash
# ==============================================================================
# EffectCraft Standalone Installer / Restorer for Omarchy Linux
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="${HOME}/.local/bin"
TARGET_CONFIG="${HOME}/.config/effectcraft"
TARGET_HOOKS="${HOME}/.config/omarchy/hooks/theme-set.d"
TARGET_DESKTOP="${HOME}/.local/share/applications"
TARGET_ICONS="${HOME}/.local/share/icons/hicolor"

echo "==> Installing EffectCraft for Omarchy Linux..."

# 1. Unpack release binaries
mkdir -p "${TARGET_BIN}"
if [[ -f "${SCRIPT_DIR}/build/effectcraft-linux-x86_64.tar.xz" ]]; then
  echo "  -> Extracting precompiled release build to ${TARGET_BIN}..."
  tar -xJf "${SCRIPT_DIR}/build/effectcraft-linux-x86_64.tar.xz" -C "${TARGET_BIN}"
  chmod +x "${TARGET_BIN}/effectcraft" "${TARGET_BIN}/effectcraft.real" "${TARGET_BIN}/effectcraft-cli" "${TARGET_BIN}/omarchy-sync-effectcraft"
else
  echo "  [ERROR] Release archive build/effectcraft-linux-x86_64.tar.xz not found!"
  exit 1
fi

# 2. Install desktop entry, metainfo, and MIME package
mkdir -p "${TARGET_DESKTOP}" "${HOME}/.local/share/metainfo" "${HOME}/.local/share/mime/packages"
if [[ -f "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.effectcraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.effectcraft.desktop" "${TARGET_DESKTOP}/"
elif [[ -f "${SCRIPT_DIR}/ai.storyteller.effectcraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/ai.storyteller.effectcraft.desktop" "${TARGET_DESKTOP}/"
fi
if [[ -f "${SCRIPT_DIR}/metainfo/ai.storyteller.effectcraft.metainfo.xml" ]]; then
  cp -a "${SCRIPT_DIR}/metainfo/ai.storyteller.effectcraft.metainfo.xml" "${HOME}/.local/share/metainfo/"
fi
if [[ -f "${SCRIPT_DIR}/mime/ai.storyteller.effectcraft.xml" ]]; then
  cp -a "${SCRIPT_DIR}/mime/ai.storyteller.effectcraft.xml" "${HOME}/.local/share/mime/packages/"
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

# 3. Restore configurations & preferences (if not already present)
mkdir -p "${TARGET_CONFIG}"
if [[ -f "${SCRIPT_DIR}/../../configs/effectcraft/theme.json" && ! -f "${TARGET_CONFIG}/theme.json" ]]; then
  cp -a "${SCRIPT_DIR}/../../configs/effectcraft/theme.json" "${TARGET_CONFIG}/"
fi
if [[ -f "${SCRIPT_DIR}/../../configs/effectcraft/prefs.json" && ! -f "${TARGET_CONFIG}/prefs.json" ]]; then
  cp -a "${SCRIPT_DIR}/../../configs/effectcraft/prefs.json" "${TARGET_CONFIG}/"
fi

# 4. Install theme synchronization hook
mkdir -p "${TARGET_HOOKS}"
if [[ -f "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/effectcraft-sync.sh" ]]; then
  cp -a "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/effectcraft-sync.sh" "${TARGET_HOOKS}/"
  chmod +x "${TARGET_HOOKS}/effectcraft-sync.sh"
fi

# 5. Sync current active theme immediately
if [[ -x "${TARGET_BIN}/omarchy-sync-effectcraft" ]]; then
  "${TARGET_BIN}/omarchy-sync-effectcraft" 2>/dev/null || true
fi

echo "==> [OK] EffectCraft successfully installed and integrated with Omarchy Linux!"
