#!/usr/bin/env bash
# ==============================================================================
# VectorCraft Build-from-Source Script with Omarchy Dynamic Theming Patch
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${HOME}/.cache/src/vectorcraft"
REPO_URL="https://github.com/storytold/vectorcraft.git"
PATCH_FILE="${SCRIPT_DIR}/vectorcraft-theme-unlock.patch"

echo "==> Building VectorCraft with Omarchy Dynamic Theming Support..."

if [[ ! -d "${BUILD_DIR}/.git" ]]; then
  echo "  -> Cloning upstream VectorCraft repository..."
  mkdir -p "$(dirname "${BUILD_DIR}")"
  git clone "${REPO_URL}" "${BUILD_DIR}"
fi

cd "${BUILD_DIR}"

if [[ -f "${PATCH_FILE}" ]]; then
  echo "  -> Applying Omarchy LiveTokens dynamic theming patch..."
  git checkout -- Cargo.toml crates/ui-egui/src/lib.rs crates/ui-egui/src/theme.rs 2>/dev/null || true
  git apply "${PATCH_FILE}"
fi

echo "  -> Compiling optimized release build with cargo..."
cargo build --release -p vectorcraft -p vectorcraft-cli

echo "  -> Installing binaries to ~/.local/bin/..."
mkdir -p "${HOME}/.local/bin"
cp -a "${BUILD_DIR}/target/release/vectorcraft" "${HOME}/.local/bin/vectorcraft.real"
cp -a "${BUILD_DIR}/target/release/vectorcraft-cli" "${HOME}/.local/bin/vectorcraft-cli"

echo "==> [OK] Build complete! Run apps/vectorcraft/install.sh to finalize desktop integration."
