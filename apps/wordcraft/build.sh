#!/usr/bin/env bash
# ==============================================================================
# WordCraft Build-from-Source Script with Omarchy Dynamic Theming Patch
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${HOME}/.cache/src/wordcraft"
REPO_URL="https://github.com/storytold/wordcraft.git"
PATCH_FILE="${SCRIPT_DIR}/wordcraft-theme-unlock.patch"

echo "==> Building WordCraft with Omarchy Dynamic Theming Support..."

if [[ ! -d "${BUILD_DIR}/.git" ]]; then
  echo "  -> Cloning upstream WordCraft repository..."
  mkdir -p "$(dirname "${BUILD_DIR}")"
  git clone "${REPO_URL}" "${BUILD_DIR}"
fi

cd "${BUILD_DIR}"

if [[ -f "${PATCH_FILE}" ]]; then
  echo "  -> Applying Omarchy LiveTokens dynamic theming patch..."
  git checkout -- crates/ui-egui/src/lib.rs crates/ui-egui/src/theme.rs 2>/dev/null || true
  git apply "${PATCH_FILE}"
fi

echo "  -> Compiling optimized release build with cargo..."
cargo build --release -p wordcraft -p wordcraft-cli

echo "  -> Installing binaries to ~/.local/bin/..."
mkdir -p "${HOME}/.local/bin"
cp -a "${BUILD_DIR}/target/release/wordcraft" "${HOME}/.local/bin/wordcraft.real"
cp -a "${BUILD_DIR}/target/release/wordcraft-cli" "${HOME}/.local/bin/wordcraft-cli"
if [[ -f "${SCRIPT_DIR}/../../bin/wordcraft" ]]; then
  cp -a "${SCRIPT_DIR}/../../bin/wordcraft" "${HOME}/.local/bin/wordcraft"
  chmod +x "${HOME}/.local/bin/wordcraft"
fi
if [[ -f "${SCRIPT_DIR}/../../bin/omarchy-sync-wordcraft" ]]; then
  cp -a "${SCRIPT_DIR}/../../bin/omarchy-sync-wordcraft" "${HOME}/.local/bin/omarchy-sync-wordcraft"
  chmod +x "${HOME}/.local/bin/omarchy-sync-wordcraft"
fi

echo "==> [OK] Build complete! Run apps/wordcraft/install.sh to finalize desktop integration."
