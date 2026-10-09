#!/usr/bin/env bash
# ==============================================================================
# PdfCraft Build-from-Source Script with Omarchy Dynamic Theming Patch
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${HOME}/.cache/src/pdfcraft"
REPO_URL="https://github.com/storytold/pdfcraft.git"
PATCH_FILE="${SCRIPT_DIR}/pdfcraft-theme-unlock.patch"

echo "==> Building PdfCraft with Omarchy Dynamic Theming Support..."

if [[ ! -d "${BUILD_DIR}/.git" ]]; then
  echo "  -> Cloning upstream PdfCraft repository..."
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
cargo build --release -p pdfcraft -p pdfcraft-cli

echo "  -> Installing binaries to ~/.local/bin/..."
mkdir -p "${HOME}/.local/bin"
cp -a "${BUILD_DIR}/target/release/pdfcraft" "${HOME}/.local/bin/pdfcraft.real"
cp -a "${BUILD_DIR}/target/release/pdfcraft-cli" "${HOME}/.local/bin/pdfcraft-cli"

echo "==> [OK] Build complete! Run apps/pdfcraft/install.sh to finalize desktop integration."
