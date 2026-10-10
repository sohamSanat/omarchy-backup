#!/usr/bin/env bash
# ==============================================================================
# GridCraft Build-from-Source Script with Omarchy Dynamic Theming Patch
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${HOME}/.cache/src/gridcraft"
REPO_URL="https://github.com/storytold/gridcraft.git"
PATCH_FILE="${SCRIPT_DIR}/gridcraft-theme-unlock.patch"

echo "==> Building GridCraft with Omarchy Dynamic Theming Support..."

if [[ ! -d "${BUILD_DIR}/.git" ]]; then
  echo "  -> Cloning upstream GridCraft repository..."
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
cargo build --release -p gridcraft -p gridcraft-cli

echo "  -> Installing binaries to ~/.local/bin/..."
mkdir -p "${HOME}/.local/bin"
cp -a "${BUILD_DIR}/target/release/gridcraft" "${HOME}/.local/bin/gridcraft.real"
cp -a "${BUILD_DIR}/target/release/gridcraft-cli" "${HOME}/.local/bin/gridcraft-cli"

echo "==> [OK] Build complete! Run apps/gridcraft/install.sh to finalize desktop integration."
