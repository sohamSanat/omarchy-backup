#!/usr/bin/env bash
# ==============================================================================
# PhotoCraft Standalone Installer / Restorer for Omarchy Linux
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="${HOME}/.local/bin"
TARGET_CONFIG="${HOME}/.config/photocraft"
TARGET_HOOKS="${HOME}/.config/omarchy/hooks/theme-set.d"
TARGET_DESKTOP="${HOME}/.local/share/applications"
TARGET_ICONS="${HOME}/.local/share/icons/hicolor"
TARGET_MIME="${HOME}/.local/share/mime/packages"

echo "==> Installing PhotoCraft for Omarchy Linux..."

# 1. Unpack release binaries
mkdir -p "${TARGET_BIN}"
if [[ -f "${SCRIPT_DIR}/build/photocraft-linux-x86_64.tar.xz" ]]; then
  echo "  -> Extracting precompiled release build to ${TARGET_BIN}..."
  tar -xJf "${SCRIPT_DIR}/build/photocraft-linux-x86_64.tar.xz" -C "${TARGET_BIN}" --strip-components=1
  chmod +x "${TARGET_BIN}/photocraft" "${TARGET_BIN}/photocraft.real" "${TARGET_BIN}/photocraft-cli" "${TARGET_BIN}/omarchy-sync-photocraft"
else
  echo "  [ERROR] Release archive build/photocraft-linux-x86_64.tar.xz not found!"
  exit 1
fi

# 2. Install desktop entry
mkdir -p "${TARGET_DESKTOP}"
if [[ -f "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.photocraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/../../desktop-entries/ai.storyteller.photocraft.desktop" "${TARGET_DESKTOP}/"
elif [[ -f "${SCRIPT_DIR}/ai.storyteller.photocraft.desktop" ]]; then
  cp -a "${SCRIPT_DIR}/ai.storyteller.photocraft.desktop" "${TARGET_DESKTOP}/"
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

# 4. Install MIME types
if [[ -f "${SCRIPT_DIR}/mime/ai.storyteller.photocraft.xml" ]]; then
  echo "  -> Registering MIME types (.pcraft, .psb, .qoi)..."
  mkdir -p "${TARGET_MIME}"
  cp -a "${SCRIPT_DIR}/mime/ai.storyteller.photocraft.xml" "${TARGET_MIME}/"
  if command -v update-mime-database >/dev/null 2>&1; then
    update-mime-database "${HOME}/.local/share/mime" 2>/dev/null || true
  fi
fi

# 5. Restore configurations (if not already present)
mkdir -p "${TARGET_CONFIG}"
for cfg in preferences.json theme.json ui.ron; do
  if [[ -f "${SCRIPT_DIR}/../../configs/photocraft/${cfg}" && ! -f "${TARGET_CONFIG}/${cfg}" ]]; then
    cp -a "${SCRIPT_DIR}/../../configs/photocraft/${cfg}" "${TARGET_CONFIG}/"
  fi
done

# Ensure control token exists with secure permissions
if [[ ! -f "${TARGET_CONFIG}/control.token" ]]; then
  python3 -c 'import secrets; print(secrets.token_hex(32))' > "${TARGET_CONFIG}/control.token"
  chmod 600 "${TARGET_CONFIG}/control.token"
fi

# 6. Install theme synchronization hook
mkdir -p "${TARGET_HOOKS}"
if [[ -f "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/photocraft-sync.sh" ]]; then
  cp -a "${SCRIPT_DIR}/../../configs/omarchy/hooks/theme-set.d/photocraft-sync.sh" "${TARGET_HOOKS}/"
  chmod +x "${TARGET_HOOKS}/photocraft-sync.sh"
fi

# 7. Sync current active theme immediately
if [[ -x "${TARGET_BIN}/omarchy-sync-photocraft" ]]; then
  "${TARGET_BIN}/omarchy-sync-photocraft" 2>/dev/null || true
fi

echo "==> [OK] PhotoCraft successfully installed and integrated with Omarchy Linux!"
