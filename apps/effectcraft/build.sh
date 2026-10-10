#!/usr/bin/env bash
# ==============================================================================
# EffectCraft Build-from-Source Script with Omarchy Dynamic Theming Patch
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${HOME}/.cache/src/effectcraft"
REPO_URL="https://github.com/storytold/effectcraft.git"
PATCH_FILE="${SCRIPT_DIR}/effectcraft-theme-unlock.patch"

echo "==> Building EffectCraft with Omarchy Dynamic Theming Support..."

if [[ ! -d "${BUILD_DIR}/.git" ]]; then
  echo "  -> Cloning upstream EffectCraft repository..."
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
cargo build --release -p effectcraft -p effectcraft-cli

echo "  -> Installing binaries to ~/.local/bin/..."
mkdir -p "${HOME}/.local/bin"
cp -a "${BUILD_DIR}/target/release/effectcraft" "${HOME}/.local/bin/effectcraft.real"
cp -a "${BUILD_DIR}/target/release/effectcraft-cli" "${HOME}/.local/bin/effectcraft-cli"
if [[ -f "${SCRIPT_DIR}/../../bin/effectcraft" ]]; then
  cp -a "${SCRIPT_DIR}/../../bin/effectcraft" "${HOME}/.local/bin/effectcraft"
  chmod +x "${HOME}/.local/bin/effectcraft"
fi
if [[ -f "${SCRIPT_DIR}/../../bin/omarchy-sync-effectcraft" ]]; then
  cp -a "${SCRIPT_DIR}/../../bin/omarchy-sync-effectcraft" "${HOME}/.local/bin/omarchy-sync-effectcraft"
  chmod +x "${HOME}/.local/bin/omarchy-sync-effectcraft"
fi

echo "==> [OK] Build complete! Run apps/effectcraft/install.sh to finalize desktop integration."
