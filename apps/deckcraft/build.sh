#!/usr/bin/env bash
# ==============================================================================
# DeckCraft Build-from-Source Script with Omarchy Dynamic Theming Patch
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${HOME}/.cache/src/deckcraft"
REPO_URL="https://github.com/storytold/deckcraft.git"
PATCH_FILE="${SCRIPT_DIR}/deckcraft-theme-unlock.patch"

echo "==> Building DeckCraft with Omarchy Dynamic Theming Support..."

if [[ ! -d "${BUILD_DIR}/.git" ]]; then
  echo "  -> Cloning upstream DeckCraft repository..."
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
cargo build --release -p deckcraft -p deckcraft-cli

echo "  -> Installing binaries to ~/.local/bin/..."
mkdir -p "${HOME}/.local/bin"
cp -a "${BUILD_DIR}/target/release/deckcraft" "${HOME}/.local/bin/deckcraft.real"
cp -a "${BUILD_DIR}/target/release/deckcraft-cli" "${HOME}/.local/bin/deckcraft-cli"
if [[ -f "${SCRIPT_DIR}/deckcraft-wrapper.sh" ]]; then
  cp -a "${SCRIPT_DIR}/deckcraft-wrapper.sh" "${HOME}/.local/bin/deckcraft"
  chmod +x "${HOME}/.local/bin/deckcraft"
fi
if [[ -f "${SCRIPT_DIR}/omarchy-sync-deckcraft" ]]; then
  cp -a "${SCRIPT_DIR}/omarchy-sync-deckcraft" "${HOME}/.local/bin/omarchy-sync-deckcraft"
  chmod +x "${HOME}/.local/bin/omarchy-sync-deckcraft"
fi

echo "==> [OK] Build complete! Run apps/deckcraft/install.sh to finalize desktop integration."
