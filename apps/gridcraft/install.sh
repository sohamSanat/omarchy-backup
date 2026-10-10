#!/usr/bin/env bash
# ==============================================================================
# GridCraft Standalone Installer / Restorer for Omarchy Linux
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="${HOME}/.local/bin"
TARGET_CONFIG="${HOME}/.config/gridcraft"
TARGET_HOOKS="${HOME}/.config/omarchy/hooks/theme-set.d"
TARGET_DESKTOP="${HOME}/.local/share/applications"
TARGET_METAINFO="${HOME}/.local/share/metainfo"
TARGET_MIME="${HOME}/.local/share/mime/packages"
TARGET_ICONS="${HOME}/.local/share/icons/hicolor"

echo "==> Installing GridCraft for Omarchy Linux..."

# 1. Unpack release binaries if archive exists
mkdir -p "${TARGET_BIN}"
if [[ -f "${SCRIPT_DIR}/build/gridcraft-linux-x86_64.tar.xz" ]]; then
  echo "  -> Extracting precompiled release build to ${TARGET_BIN}..."
  tar -xJf "${SCRIPT_DIR}/build/gridcraft-linux-x86_64.tar.xz" -C "${TARGET_BIN}" --strip-components=1
  chmod +x "${TARGET_BIN}/gridcraft" "${TARGET_BIN}/gridcraft.real" "${TARGET_BIN}/gridcraft-cli" "${TARGET_BIN}/omarchy-sync-gridcraft"
fi

# 2. Install desktop entry, metainfo, and MIME package
mkdir -p "${TARGET_DESKTOP}" "${TARGET_METAINFO}" "${TARGET_MIME}"
if [[ -f "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.gridcraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.gridcraft.desktop" "${TARGET_DESKTOP}/"
elif [[ -f "${SCRIPT_DIR}/ai.storyteller.gridcraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/ai.storyteller.gridcraft.desktop" "${TARGET_DESKTOP}/"
fi
if [[ -f "${SCRIPT_DIR}/metainfo/ai.storyteller.gridcraft.metainfo.xml" ]]; then
  cp -a "${SCRIPT_DIR}/metainfo/ai.storyteller.gridcraft.metainfo.xml" "${TARGET_METAINFO}/"
fi
if [[ -f "${SCRIPT_DIR}/mime/ai.storyteller.gridcraft.xml" ]]; then
  cp -a "${SCRIPT_DIR}/mime/ai.storyteller.gridcraft.xml" "${TARGET_MIME}/"
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
for cfg in theme.json ui.json prefs.json; do
  if [[ -f "${SCRIPT_DIR}/../../configs/gridcraft/${cfg}" && ! -f "${TARGET_CONFIG}/${cfg}" ]]; then
    cp -a "${SCRIPT_DIR}/../../configs/gridcraft/${cfg}" "${TARGET_CONFIG}/"
  fi
done

# 5. Install theme synchronization hook
mkdir -p "${TARGET_HOOKS}"
if [[ -f "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/gridcraft-sync.sh" ]]; then
  cp -a "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/gridcraft-sync.sh" "${TARGET_HOOKS}/"
  chmod +x "${TARGET_HOOKS}/gridcraft-sync.sh"
fi

# 6. Sync current active theme immediately
if [[ -x "${TARGET_BIN}/omarchy-sync-gridcraft" ]]; then
  "${TARGET_BIN}/omarchy-sync-gridcraft" 2>/dev/null || true
fi

echo "==> [OK] GridCraft successfully installed and integrated with Omarchy Linux!"
