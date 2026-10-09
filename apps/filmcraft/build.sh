#!/usr/bin/env bash
# ==============================================================================
# FilmCraft Build-from-Source Script with Omarchy Dynamic Theming Patch
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${HOME}/.cache/src/filmcraft"
REPO_URL="https://github.com/storytold/filmcraft.git"
PATCH_FILE="${SCRIPT_DIR}/filmcraft-theme-unlock.patch"

echo "==> Building FilmCraft with Omarchy Dynamic Theming Support..."

if [[ ! -d "${BUILD_DIR}/.git" ]]; then
  echo "  -> Cloning upstream FilmCraft repository..."
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
cargo build --release -p filmcraft -p filmcraft-cli

echo "  -> Installing binaries to ~/.local/bin/..."
mkdir -p "${HOME}/.local/bin"
cp -a "${BUILD_DIR}/target/release/filmcraft" "${HOME}/.local/bin/filmcraft.real"
cp -a "${BUILD_DIR}/target/release/filmcraft-cli" "${HOME}/.local/bin/filmcraft-cli"

echo "==> [OK] Build complete! Run apps/filmcraft/install.sh to finalize desktop integration."
