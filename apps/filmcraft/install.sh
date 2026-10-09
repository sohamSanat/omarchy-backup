#!/usr/bin/env bash
# ==============================================================================
# FilmCraft Standalone Installer / Restorer for Omarchy Linux
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="${HOME}/.local/bin"
TARGET_CONFIG="${HOME}/.config/filmcraft"
TARGET_DATA="${HOME}/.local/share/filmcraft"
TARGET_HOOKS="${HOME}/.config/omarchy/hooks/theme-set.d"
TARGET_DESKTOP="${HOME}/.local/share/applications"
TARGET_METAINFO="${HOME}/.local/share/metainfo"
TARGET_ICONS="${HOME}/.local/share/icons/hicolor"

echo "==> Installing FilmCraft for Omarchy Linux..."

# 1. Unpack release binaries
mkdir -p "${TARGET_BIN}"
if [[ -f "${SCRIPT_DIR}/build/filmcraft-linux-x86_64.tar.xz" ]]; then
  echo "  -> Extracting precompiled release build to ${TARGET_BIN}..."
  tar -xJf "${SCRIPT_DIR}/build/filmcraft-linux-x86_64.tar.xz" -C "${TARGET_BIN}" --strip-components=1
  chmod +x "${TARGET_BIN}/filmcraft" "${TARGET_BIN}/filmcraft.real" "${TARGET_BIN}/filmcraft-cli" "${TARGET_BIN}/omarchy-sync-filmcraft"
else
  echo "  [ERROR] Release archive build/filmcraft-linux-x86_64.tar.xz not found!"
  exit 1
fi

# 2. Install desktop entry and metainfo
mkdir -p "${TARGET_DESKTOP}" "${TARGET_METAINFO}"
if [[ -f "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.filmcraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.filmcraft.desktop" "${TARGET_DESKTOP}/"
elif [[ -f "${SCRIPT_DIR}/ai.storyteller.filmcraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/ai.storyteller.filmcraft.desktop" "${TARGET_DESKTOP}/"
fi
if [[ -f "${SCRIPT_DIR}/metainfo/ai.storyteller.filmcraft.metainfo.xml" ]]; then
  cp -a "${SCRIPT_DIR}/metainfo/ai.storyteller.filmcraft.metainfo.xml" "${TARGET_METAINFO}/"
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

# 4. Restore configurations & preferences (if not already present)
mkdir -p "${TARGET_CONFIG}" "${TARGET_DATA}"
if [[ -f "${SCRIPT_DIR}/../../configs/filmcraft/theme.json" && ! -f "${TARGET_CONFIG}/theme.json" ]]; then
  cp -a "${SCRIPT_DIR}/../../configs/filmcraft/theme.json" "${TARGET_CONFIG}/"
fi
if [[ -f "${SCRIPT_DIR}/../../configs/filmcraft/preferences.json" && ! -f "${TARGET_DATA}/preferences.json" ]]; then
  cp -a "${SCRIPT_DIR}/../../configs/filmcraft/preferences.json" "${TARGET_DATA}/"
fi

# 5. Install theme synchronization hook
mkdir -p "${TARGET_HOOKS}"
if [[ -f "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/filmcraft-sync.sh" ]]; then
  cp -a "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/filmcraft-sync.sh" "${TARGET_HOOKS}/"
  chmod +x "${TARGET_HOOKS}/filmcraft-sync.sh"
fi

# 6. Sync current active theme immediately
if [[ -x "${TARGET_BIN}/omarchy-sync-filmcraft" ]]; then
  "${TARGET_BIN}/omarchy-sync-filmcraft" 2>/dev/null || true
fi

echo "==> [OK] FilmCraft successfully installed and integrated with Omarchy Linux!"
