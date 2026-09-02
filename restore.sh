#!/usr/bin/env bash
# ==============================================================================
# Omarchy Full Customization Restore Script
# Backs up existing configs and restores all themes, plugins, Hyprland rules,
# bar layouts, custom hooks, helper scripts, and application configs.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_TIMESTAMP="$(date +%s)"
USER_HOME="$HOME"

echo "========================================================"
echo "  Omarchy Configuration Restoration"
echo "  Source: ${SCRIPT_DIR}"
echo "  Target: ${USER_HOME}"
echo "========================================================"

# Safety check: Verify we are on an Omarchy system
if ! command -v omarchy >/dev/null 2>&1; then
  echo "WARNING: 'omarchy' CLI command was not found in PATH."
  echo "Are you sure this is an Omarchy installation?"
  read -rp "Continue anyway? (y/N): " confirm
  if [[ "${confirm,,}" != "y" ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Function to safely create a backup of an existing target before overwriting
backup_if_exists() {
  local target="$1"
  if [[ -e "$target" ]]; then
    local backup_path="${target}.pre-restore.${BACKUP_TIMESTAMP}"
    echo "  [Backup] Existing $(basename "$target") -> $(basename "$backup_path")"
    cp -r "$target" "$backup_path"
  fi
}

echo ""
echo "==> Step 1: Ensuring directories exist..."
mkdir -p "${USER_HOME}/.config/omarchy"
mkdir -p "${USER_HOME}/.config/omarchy/themes"
mkdir -p "${USER_HOME}/.config/omarchy/plugins"
mkdir -p "${USER_HOME}/.config/omarchy/hooks"
mkdir -p "${USER_HOME}/.config/omarchy/extensions"
mkdir -p "${USER_HOME}/.config/omarchy/themed"
mkdir -p "${USER_HOME}/.config/omarchy/defaults"
mkdir -p "${USER_HOME}/.config/omarchy/branding"
mkdir -p "${USER_HOME}/.config/hypr"
mkdir -p "${USER_HOME}/.config/fastfetch"
mkdir -p "${USER_HOME}/.local/bin"
mkdir -p "${USER_HOME}/.local/lib/hypr"
mkdir -p "${USER_HOME}/.local/lib/omarchy-whatsapp"
mkdir -p "${USER_HOME}/.local/share/applications"

echo ""
echo "==> Step 2: Restoring Omarchy core configurations..."
backup_if_exists "${USER_HOME}/.config/omarchy/shell.json"
backup_if_exists "${USER_HOME}/.config/omarchy/themebook.json"
backup_if_exists "${USER_HOME}/.config/omarchy/battery-limiter.json"

cp -a "${SCRIPT_DIR}/configs/omarchy/shell.json" "${USER_HOME}/.config/omarchy/"
cp -a "${SCRIPT_DIR}/configs/omarchy/themebook.json" "${USER_HOME}/.config/omarchy/"
cp -a "${SCRIPT_DIR}/configs/omarchy/battery-limiter.json" "${USER_HOME}/.config/omarchy/"
cp -a "${SCRIPT_DIR}/configs/omarchy/branding/." "${USER_HOME}/.config/omarchy/branding/"
cp -a "${SCRIPT_DIR}/configs/omarchy/defaults/." "${USER_HOME}/.config/omarchy/defaults/"
cp -a "${SCRIPT_DIR}/configs/omarchy/extensions/." "${USER_HOME}/.config/omarchy/extensions/"
cp -a "${SCRIPT_DIR}/configs/omarchy/themed/." "${USER_HOME}/.config/omarchy/themed/"
cp -a "${SCRIPT_DIR}/configs/omarchy/hooks/." "${USER_HOME}/.config/omarchy/hooks/"

# Make all installed hooks executable
find "${USER_HOME}/.config/omarchy/hooks" -type f -exec chmod +x {} +
echo "  [OK] Omarchy core configs, extensions, templates, and hooks restored."

echo ""
echo "==> Step 3: Restoring Hyprland configuration..."
backup_if_exists "${USER_HOME}/.config/hypr/hyprland.lua"
backup_if_exists "${USER_HOME}/.config/hypr/bindings.lua"
backup_if_exists "${USER_HOME}/.config/hypr/looknfeel.lua"
backup_if_exists "${USER_HOME}/.config/hypr/input.lua"
backup_if_exists "${USER_HOME}/.config/hypr/monitors.lua"

cp -a "${SCRIPT_DIR}/configs/hypr/." "${USER_HOME}/.config/hypr/"
echo "  [OK] Hyprland configuration restored."

echo ""
echo "==> Step 4: Restoring terminal configurations..."
for term in alacritty foot ghostty kitty; do
  if [[ -d "${SCRIPT_DIR}/configs/terminals/${term}" ]]; then
    mkdir -p "${USER_HOME}/.config/${term}"
    cp -a "${SCRIPT_DIR}/configs/terminals/${term}/." "${USER_HOME}/.config/${term}/"
    echo "  [OK] Terminal restored: ${term}"
  fi
done

echo ""
echo "==> Step 5: Restoring shell, CLI tools, and desktop configs..."
if [[ -f "${SCRIPT_DIR}/configs/starship.toml" ]]; then
  cp -a "${SCRIPT_DIR}/configs/starship.toml" "${USER_HOME}/.config/"
fi
if [[ -d "${SCRIPT_DIR}/configs/btop" ]]; then
  mkdir -p "${USER_HOME}/.config/btop"
  cp -a "${SCRIPT_DIR}/configs/btop/." "${USER_HOME}/.config/btop/"
fi
if [[ -d "${SCRIPT_DIR}/configs/git" ]]; then
  mkdir -p "${USER_HOME}/.config/git"
  cp -a "${SCRIPT_DIR}/configs/git/." "${USER_HOME}/.config/git/"
fi
if [[ -d "${SCRIPT_DIR}/configs/lazygit" ]]; then
  mkdir -p "${USER_HOME}/.config/lazygit"
  cp -a "${SCRIPT_DIR}/configs/lazygit/." "${USER_HOME}/.config/lazygit/"
fi
if [[ -d "${SCRIPT_DIR}/configs/nvim" ]]; then
  mkdir -p "${USER_HOME}/.config/nvim"
  cp -a "${SCRIPT_DIR}/configs/nvim/." "${USER_HOME}/.config/nvim/"
fi
if [[ -d "${SCRIPT_DIR}/configs/tmux" ]]; then
  mkdir -p "${USER_HOME}/.config/tmux"
  cp -a "${SCRIPT_DIR}/configs/tmux/." "${USER_HOME}/.config/tmux/"
fi
if [[ -d "${SCRIPT_DIR}/configs/mise" ]]; then
  mkdir -p "${USER_HOME}/.config/mise"
  cp -a "${SCRIPT_DIR}/configs/mise/." "${USER_HOME}/.config/mise/"
fi
if [[ -d "${SCRIPT_DIR}/configs/voxtype" ]]; then
  mkdir -p "${USER_HOME}/.config/voxtype"
  cp -a "${SCRIPT_DIR}/configs/voxtype/." "${USER_HOME}/.config/voxtype/"
fi
if [[ -d "${SCRIPT_DIR}/configs/tensaku" ]]; then
  mkdir -p "${USER_HOME}/.config/tensaku"
  cp -a "${SCRIPT_DIR}/configs/tensaku/." "${USER_HOME}/.config/tensaku/"
fi
if [[ -d "${SCRIPT_DIR}/configs/omniroute" ]]; then
  mkdir -p "${USER_HOME}/.config/omniroute"
  cp -a "${SCRIPT_DIR}/configs/omniroute/." "${USER_HOME}/.config/omniroute/"
fi
if [[ -f "${SCRIPT_DIR}/configs/kdeglobals" ]]; then
  cp -a "${SCRIPT_DIR}/configs/kdeglobals" "${USER_HOME}/.config/"
fi
if [[ -f "${SCRIPT_DIR}/configs/mimeapps.list" ]]; then
  cp -a "${SCRIPT_DIR}/configs/mimeapps.list" "${USER_HOME}/.config/"
fi
if [[ -f "${SCRIPT_DIR}/configs/xdg-terminals.list" ]]; then
  cp -a "${SCRIPT_DIR}/configs/xdg-terminals.list" "${USER_HOME}/.config/"
fi
if [[ -f "${SCRIPT_DIR}/configs/fastfetch/config.jsonc" ]]; then
  cp -a "${SCRIPT_DIR}/configs/fastfetch/config.jsonc" "${USER_HOME}/.config/fastfetch/config.jsonc"
fi
if [[ -f "${SCRIPT_DIR}/configs/shell/bashrc" ]]; then
  backup_if_exists "${USER_HOME}/.bashrc"
  cp -a "${SCRIPT_DIR}/configs/shell/bashrc" "${USER_HOME}/.bashrc"
fi
if [[ -f "${SCRIPT_DIR}/configs/shell/bash_profile" ]]; then
  backup_if_exists "${USER_HOME}/.bash_profile"
  cp -a "${SCRIPT_DIR}/configs/shell/bash_profile" "${USER_HOME}/.bash_profile"
fi

echo ""
echo "==> Step 6: Restoring themes..."
for theme_path in "${SCRIPT_DIR}/themes"/*; do
  if [[ -d "$theme_path" ]]; then
    theme_name="$(basename "$theme_path")"
    echo "  -> Restoring theme: ${theme_name}"
    mkdir -p "${USER_HOME}/.config/omarchy/themes/${theme_name}"
    cp -a "${theme_path}/." "${USER_HOME}/.config/omarchy/themes/${theme_name}/"
  fi
done

echo ""
echo "==> Step 7: Restoring shell plugins..."
for plugin_path in "${SCRIPT_DIR}/plugins"/*; do
  if [[ -d "$plugin_path" ]]; then
    plugin_name="$(basename "$plugin_path")"
    echo "  -> Restoring plugin: ${plugin_name}"
    mkdir -p "${USER_HOME}/.config/omarchy/plugins/${plugin_name}"
    cp -a "${plugin_path}/." "${USER_HOME}/.config/omarchy/plugins/${plugin_name}/"
  fi
done

# Install node dependencies for plugins if needed (e.g. whatsapp daemon)
if [[ -f "${USER_HOME}/.config/omarchy/plugins/io.github.ricky.whatsapp/daemon/package.json" ]]; then
  if command -v npm >/dev/null 2>&1; then
    echo "  -> Installing npm dependencies for whatsapp plugin daemon..."
    (cd "${USER_HOME}/.config/omarchy/plugins/io.github.ricky.whatsapp/daemon" && npm install --omit=dev --silent 2>/dev/null || true)
  fi
fi

echo ""
echo "==> Step 8: Restoring custom scripts and binaries to ~/.local/bin..."
for script_path in "${SCRIPT_DIR}/bin"/*; do
  if [[ -f "$script_path" ]]; then
    script_name="$(basename "$script_path")"
    cp -a "$script_path" "${USER_HOME}/.local/bin/"
    chmod +x "${USER_HOME}/.local/bin/${script_name}"
    echo "  [OK] Installed executable: ~/.local/bin/${script_name}"
  fi
done

# Set up symlinks for plugins if necessary
if [[ -f "${USER_HOME}/.config/omarchy/plugins/soham.power/scripts/battery-limiter.sh" ]]; then
  ln -nsf "${USER_HOME}/.config/omarchy/plugins/soham.power/scripts/battery-limiter.sh" "${USER_HOME}/.local/bin/omarchy-battery-limit"
fi
for wa_bin in omarchy-whatsapp omarchy-whatsapp-ctl omarchy-whatsapp-daemon omarchy-whatsapp-focus omarchy-whatsapp-login omarchy-whatsapp-open; do
  if [[ -f "${USER_HOME}/.config/omarchy/plugins/io.github.ricky.whatsapp/bin/${wa_bin}" ]]; then
    ln -nsf "${USER_HOME}/.config/omarchy/plugins/io.github.ricky.whatsapp/bin/${wa_bin}" "${USER_HOME}/.local/bin/${wa_bin}"
  fi
done

echo ""
echo "==> Step 9: Restoring custom libraries..."
if [[ -f "${SCRIPT_DIR}/lib/hypr/hypr-shiny-border.so" ]]; then
  cp -a "${SCRIPT_DIR}/lib/hypr/hypr-shiny-border.so" "${USER_HOME}/.local/lib/hypr/"
  echo "  [OK] Installed ~/.local/lib/hypr/hypr-shiny-border.so"
fi
if [[ -f "${SCRIPT_DIR}/lib/omarchy-whatsapp/sweep" ]]; then
  cp -a "${SCRIPT_DIR}/lib/omarchy-whatsapp/sweep" "${USER_HOME}/.local/lib/omarchy-whatsapp/"
  chmod +x "${USER_HOME}/.local/lib/omarchy-whatsapp/sweep"
  echo "  [OK] Installed ~/.local/lib/omarchy-whatsapp/sweep"
fi

echo ""
echo "==> Step 10: Restoring desktop launchers..."
if [[ -d "${SCRIPT_DIR}/desktop-entries" ]]; then
  cp -a "${SCRIPT_DIR}/desktop-entries/." "${USER_HOME}/.local/share/applications/"
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${USER_HOME}/.local/share/applications" 2>/dev/null || true
  fi
  echo "  [OK] Desktop applications registered."
fi

echo ""
echo "==> Step 11: Applying customizations and restarting components..."
if command -v omarchy >/dev/null 2>&1; then
  echo "  -> Setting theme: Sakura Mochi"
  omarchy theme set "Sakura Mochi" || true

  echo "  -> Setting font: JetBrainsMono Nerd Font"
  omarchy font set "JetBrainsMono Nerd Font" || true

  echo "  -> Restarting Omarchy shell..."
  omarchy restart shell || true

  echo "  -> Reloading terminals..."
  omarchy restart terminal || true
fi

if command -v hyprctl >/dev/null 2>&1; then
  echo "  -> Reloading Hyprland..."
  hyprctl reload || true
  echo "  -> Checking Hyprland configuration for errors..."
  hyprctl configerrors || true
fi

echo ""
echo "========================================================"
echo "  Customizations Restored Successfully!"
echo "  - Current theme: Sakura Mochi"
echo "  - Current font: JetBrainsMono Nerd Font"
echo "  - Bar Layout: Custom floating bar with 14 plugins"
echo "  - Window Manager: Hyprland with blur, scale 2, and custom bindings"
echo "========================================================"
