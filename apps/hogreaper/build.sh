#!/usr/bin/env bash
# ==============================================================================
# HogReaper Build-from-Source Script
# Zero-Overhead RAM and CPU Hardware Governor for Omarchy Linux
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PROJECTS="${HOME}/Projects/hogreaper"

echo "==> Building HogReaper Hardware Governor..."

# Ensure source directory exists in Projects
if [[ ! -d "${TARGET_PROJECTS}/src" && -d "${SCRIPT_DIR}/source" ]]; then
  echo "  -> Initializing source repository from backup..."
  mkdir -p "${TARGET_PROJECTS}"
  cp -a "${SCRIPT_DIR}/source/." "${TARGET_PROJECTS}/"
fi

BUILD_DIR="${TARGET_PROJECTS}"
if [[ ! -d "${BUILD_DIR}/src" ]]; then
  BUILD_DIR="${SCRIPT_DIR}/source"
fi

cd "${BUILD_DIR}"

echo "  -> Compiling optimized release build with cargo..."
cargo build --release

echo "  -> Installing binary to ~/.local/bin/..."
mkdir -p "${HOME}/.local/bin"
cp -a "${BUILD_DIR}/target/release/hogreaper" "${HOME}/.local/bin/hogreaper"
chmod +x "${HOME}/.local/bin/hogreaper"
strip "${HOME}/.local/bin/hogreaper" 2>/dev/null || true

echo "==> [OK] Build complete! Run apps/hogreaper/install.sh to enable the systemd service."
