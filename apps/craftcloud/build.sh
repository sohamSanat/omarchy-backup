#!/usr/bin/env bash
# ==============================================================================
# CraftCloud Build-from-Source Script
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PROJECTS="${HOME}/craftcloud"

echo "==> Building CraftCloud Creative Suite Hub..."

# Ensure source directory exists
if [[ ! -d "${TARGET_PROJECTS}/src" && -d "${SCRIPT_DIR}/source" ]]; then
  echo "  -> Initializing source repository from backup..."
  mkdir -p "${TARGET_PROJECTS}"
  cp -a "${SCRIPT_DIR}/source/." "${TARGET_PROJECTS}/"
fi

cd "${TARGET_PROJECTS}"

echo "  -> Compiling optimized release build with cargo..."
cargo build --release

echo "  -> Installing binary to ~/.local/bin/..."
mkdir -p "${HOME}/.local/bin"
cp -a "${TARGET_PROJECTS}/target/release/craftcloud" "${HOME}/.local/bin/craftcloud"
chmod +x "${HOME}/.local/bin/craftcloud"

echo "==> [OK] Build complete! Run apps/craftcloud/install.sh to finalize desktop integration."
