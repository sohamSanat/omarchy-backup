#!/usr/bin/env bash
# ==============================================================================
# PhotoCraft Build-from-Source Script with Omarchy Dynamic Theming Patch
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${HOME}/.cache/src/photocraft"
REPO_URL="https://github.com/storytold/photocraft.git"
PATCH_FILE="${SCRIPT_DIR}/photocraft-theme-unlock.patch"

echo "==> Building PhotoCraft with Omarchy Dynamic Theming Support..."

if [[ ! -d "${BUILD_DIR}/.git" ]]; then
  echo "  -> Cloning upstream PhotoCraft repository..."
  mkdir -p "$(dirname "${BUILD_DIR}")"
  git clone "${REPO_URL}" "${BUILD_DIR}"
fi

cd "${BUILD_DIR}"

if [[ -f "${PATCH_FILE}" ]]; then
  echo "  -> Applying Omarchy LiveTokens unlock patch..."
  git checkout -- Cargo.toml crates/ui-egui/src/lib.rs crates/ui-egui/src/theme.rs 2>/dev/null || true
  git apply "${PATCH_FILE}"
fi

echo "  -> Compiling optimized release build with cargo..."
cargo build --release -p photocraft -p photocraft-cli

echo "  -> Installing binaries to ~/.local/bin/..."
mkdir -p "${HOME}/.local/bin"
cp -a "${BUILD_DIR}/target/release/photocraft" "${HOME}/.local/bin/photocraft.real"
cp -a "${BUILD_DIR}/target/release/photocraft-cli" "${HOME}/.local/bin/photocraft-cli"

echo "==> [OK] Build complete! Run apps/photocraft/install.sh to finalize desktop integration."
