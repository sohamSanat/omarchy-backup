#!/usr/bin/env bash
# ==============================================================================
# PdfCraft Standalone Installer / Restorer for Omarchy Linux
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="${HOME}/.local/bin"
TARGET_CONFIG="${HOME}/.config/pdfcraft"
TARGET_DATA="${HOME}/.local/share/pdfcraft"
TARGET_HOOKS="${HOME}/.config/omarchy/hooks/theme-set.d"
TARGET_DESKTOP="${HOME}/.local/share/applications"
TARGET_METAINFO="${HOME}/.local/share/metainfo"
TARGET_MIME="${HOME}/.local/share/mime/packages"
TARGET_ICONS="${HOME}/.local/share/icons/hicolor"

echo "==> Installing PdfCraft for Omarchy Linux..."

# 1. Unpack release binaries
mkdir -p "${TARGET_BIN}"
if [[ -f "${SCRIPT_DIR}/build/pdfcraft-linux-x86_64.tar.xz" ]]; then
  echo "  -> Extracting precompiled release build to ${TARGET_BIN}..."
  tar -xJf "${SCRIPT_DIR}/build/pdfcraft-linux-x86_64.tar.xz" -C "${TARGET_BIN}" --strip-components=1
  chmod +x "${TARGET_BIN}/pdfcraft" "${TARGET_BIN}/pdfcraft.real" "${TARGET_BIN}/pdfcraft-cli" "${TARGET_BIN}/omarchy-sync-pdfcraft"
else
  echo "  [ERROR] Release archive build/pdfcraft-linux-x86_64.tar.xz not found!"
  exit 1
fi

# 2. Install desktop entry, metainfo, and MIME package
mkdir -p "${TARGET_DESKTOP}" "${TARGET_METAINFO}" "${TARGET_MIME}"
if [[ -f "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.pdfcraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.pdfcraft.desktop" "${TARGET_DESKTOP}/"
elif [[ -f "${SCRIPT_DIR}/ai.storyteller.pdfcraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/ai.storyteller.pdfcraft.desktop" "${TARGET_DESKTOP}/"
fi
if [[ -f "${SCRIPT_DIR}/metainfo/ai.storyteller.pdfcraft.metainfo.xml" ]]; then
  cp -a "${SCRIPT_DIR}/metainfo/ai.storyteller.pdfcraft.metainfo.xml" "${TARGET_METAINFO}/"
fi
if [[ -f "${SCRIPT_DIR}/mime/ai.storyteller.pdfcraft.xml" ]]; then
  cp -a "${SCRIPT_DIR}/mime/ai.storyteller.pdfcraft.xml" "${TARGET_MIME}/"
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

# 4. Restore configurations & preferences (if not already present)
mkdir -p "${TARGET_CONFIG}" "${TARGET_DATA}"
if [[ -f "${SCRIPT_DIR}/../../configs/pdfcraft/theme.json" && ! -f "${TARGET_CONFIG}/theme.json" ]]; then
  cp -a "${SCRIPT_DIR}/../../configs/pdfcraft/theme.json" "${TARGET_CONFIG}/"
fi
if [[ -f "${SCRIPT_DIR}/../../configs/pdfcraft/app.ron" && ! -f "${TARGET_DATA}/app.ron" ]]; then
  cp -a "${SCRIPT_DIR}/../../configs/pdfcraft/app.ron" "${TARGET_DATA}/"
fi

# 5. Install theme synchronization hook
mkdir -p "${TARGET_HOOKS}"
if [[ -f "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/pdfcraft-sync.sh" ]]; then
  cp -a "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/pdfcraft-sync.sh" "${TARGET_HOOKS}/"
  chmod +x "${TARGET_HOOKS}/pdfcraft-sync.sh"
fi

# 6. Sync current active theme immediately
if [[ -x "${TARGET_BIN}/omarchy-sync-pdfcraft" ]]; then
  "${TARGET_BIN}/omarchy-sync-pdfcraft" 2>/dev/null || true
fi

echo "==> [OK] PdfCraft successfully installed and integrated with Omarchy Linux!"
