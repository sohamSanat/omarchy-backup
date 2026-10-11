#!/usr/bin/env bash
# ==============================================================================
# HogReaper Standalone Installer / Restorer for Omarchy Linux
# Zero-Overhead RAM and CPU Hardware Governor Daemon & Systemd Service
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="${HOME}/.local/bin"
TARGET_CONFIG="${HOME}/.config/hogreaper"
TARGET_SYSTEMD="${HOME}/.config/systemd/user"
TARGET_PLUGIN="${HOME}/.config/omarchy/plugins/soham.hogreaper"
TARGET_PROJECTS="${HOME}/Projects/hogreaper"

echo "==> Installing HogReaper Hardware Governor for Omarchy Linux..."

# 1. Install CLI binary
mkdir -p "${TARGET_BIN}"
if [[ -f "${SCRIPT_DIR}/../../bin/hogreaper" ]]; then
  echo "  -> Installing precompiled release binary to ${TARGET_BIN}..."
  cp -a "${SCRIPT_DIR}/../../bin/hogreaper" "${TARGET_BIN}/hogreaper"
  chmod +x "${TARGET_BIN}/hogreaper"
elif [[ -f "${TARGET_PROJECTS}/target/release/hogreaper" ]]; then
  cp -a "${TARGET_PROJECTS}/target/release/hogreaper" "${TARGET_BIN}/hogreaper"
  chmod +x "${TARGET_BIN}/hogreaper"
fi

# 2. Restore HogReaper source repository if missing
if [[ ! -d "${TARGET_PROJECTS}/src" && -d "${SCRIPT_DIR}/source" ]]; then
  echo "  -> Restoring HogReaper source code to ${TARGET_PROJECTS}..."
  mkdir -p "${TARGET_PROJECTS}"
  cp -a "${SCRIPT_DIR}/source/." "${TARGET_PROJECTS}/"
fi

# 3. Install user configuration
mkdir -p "${TARGET_CONFIG}"
if [[ -f "${SCRIPT_DIR}/../../configs/hogreaper/config.toml" && ! -f "${TARGET_CONFIG}/config.toml" ]]; then
  echo "  -> Restoring user configuration to ${TARGET_CONFIG}/config.toml..."
  cp -a "${SCRIPT_DIR}/../../configs/hogreaper/config.toml" "${TARGET_CONFIG}/config.toml"
fi

# 4. Install Quickshell navbar plugin
if [[ -d "${SCRIPT_DIR}/../../plugins/soham.hogreaper" ]]; then
  echo "  -> Restoring Quickshell navbar plugin to ${TARGET_PLUGIN}..."
  mkdir -p "${TARGET_PLUGIN}"
  cp -a "${SCRIPT_DIR}/../../plugins/soham.hogreaper/." "${TARGET_PLUGIN}/"
fi

# 5. Install and enable systemd user service
mkdir -p "${TARGET_SYSTEMD}"
if [[ -f "${SCRIPT_DIR}/../../configs/systemd/user/hogreaper.service" ]]; then
  echo "  -> Installing systemd user unit to ${TARGET_SYSTEMD}/hogreaper.service..."
  cp -a "${SCRIPT_DIR}/../../configs/systemd/user/hogreaper.service" "${TARGET_SYSTEMD}/hogreaper.service"
  
  if command -v systemctl >/dev/null 2>&1; then
    echo "  -> Reloading systemd user daemon and enabling hogreaper.service..."
    systemctl --user daemon-reload || true
    systemctl --user enable --now hogreaper.service || true
  fi
fi

echo "==> [OK] HogReaper hardware governor successfully installed and activated!"
