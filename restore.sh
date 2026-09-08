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
mkdir -p "${USER_HOME}/.config/omarchy/brave-polish"
mkdir -p "${USER_HOME}/.config/omarchy/brave-darkreader"
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

if [[ -d "${SCRIPT_DIR}/configs/omarchy/brave-polish" ]]; then
  echo "  -> Restoring Brave Origin Polish companion extension..."
  mkdir -p "${USER_HOME}/.config/omarchy/brave-polish"
  cp -a "${SCRIPT_DIR}/configs/omarchy/brave-polish/." "${USER_HOME}/.config/omarchy/brave-polish/"
fi
if [[ -d "${SCRIPT_DIR}/configs/omarchy/brave-darkreader" ]]; then
  echo "  -> Restoring Brave Dark Reader MV3 fork extension..."
  mkdir -p "${USER_HOME}/.config/omarchy/brave-darkreader"
  cp -a "${SCRIPT_DIR}/configs/omarchy/brave-darkreader/." "${USER_HOME}/.config/omarchy/brave-darkreader/"
fi

# Make all installed hooks executable
find "${USER_HOME}/.config/omarchy/hooks" -type f -exec chmod +x {} +
echo "  [OK] Omarchy core configs, brave mods, extensions, templates, and hooks restored."

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
if [[ -f "${SCRIPT_DIR}/configs/chromium-flags.conf" ]]; then
  cp -a "${SCRIPT_DIR}/configs/chromium-flags.conf" "${USER_HOME}/.config/"
  echo "  [OK] Restored Chromium / Brave Wayland ozone flags: ~/.config/chromium-flags.conf"
fi
if [[ -f "${SCRIPT_DIR}/configs/brave/policies/managed/omarchy-ntp.json" ]]; then
  echo "  -> Restoring Brave Origin managed policies..."
  if [[ -w "/etc/brave/policies/managed" ]]; then
    cp -a "${SCRIPT_DIR}/configs/brave/policies/managed/omarchy-ntp.json" "/etc/brave/policies/managed/"
    echo "  [OK] Installed Brave managed policy: /etc/brave/policies/managed/omarchy-ntp.json"
  elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    sudo mkdir -p "/etc/brave/policies/managed"
    sudo cp -a "${SCRIPT_DIR}/configs/brave/policies/managed/omarchy-ntp.json" "/etc/brave/policies/managed/"
    echo "  [OK] Installed Brave managed policy via sudo: /etc/brave/policies/managed/omarchy-ntp.json"
  else
    echo "  [NOTE] Run the following to enable the Omarchy New Tab Page policy in Brave Origin:"
    echo "         sudo mkdir -p /etc/brave/policies/managed && sudo cp ${SCRIPT_DIR}/configs/brave/policies/managed/omarchy-ntp.json /etc/brave/policies/managed/"
  fi
fi
if [[ -d "${SCRIPT_DIR}/configs/systemd/user" ]]; then
  mkdir -p "${USER_HOME}/.config/systemd/user"
  cp -a "${SCRIPT_DIR}/configs/systemd/user/." "${USER_HOME}/.config/systemd/user/"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload 2>/dev/null || true
  fi
  echo "  [OK] Systemd user services restored."
fi
if [[ -d "${SCRIPT_DIR}/configs/Omacom" ]]; then
  mkdir -p "${USER_HOME}/.config/Omacom"
  cp -a "${SCRIPT_DIR}/configs/Omacom/." "${USER_HOME}/.config/Omacom/"
fi
if [[ -d "${SCRIPT_DIR}/configs/fcitx5" ]]; then
  mkdir -p "${USER_HOME}/.config/fcitx5"
  cp -a "${SCRIPT_DIR}/configs/fcitx5/." "${USER_HOME}/.config/fcitx5/"
fi
if [[ -d "${SCRIPT_DIR}/configs/zen" ]]; then
  echo "  -> Restoring Zen Browser customizations, Dark Reader mod & styles..."
  mkdir -p "${USER_HOME}/.config/zen"
  if [[ -f "${SCRIPT_DIR}/configs/zen/MODS.md" ]]; then
    cp -a "${SCRIPT_DIR}/configs/zen/MODS.md" "${USER_HOME}/.config/zen/"
  fi
  if [[ -d "${SCRIPT_DIR}/configs/zen/native-messaging-hosts" ]]; then
    mkdir -p "${USER_HOME}/.config/zen/native-messaging-hosts"
    cp -a "${SCRIPT_DIR}/configs/zen/native-messaging-hosts/." "${USER_HOME}/.config/zen/native-messaging-hosts/"
  fi
  if [[ -d "${SCRIPT_DIR}/configs/zen/mods/darkreader" ]]; then
    mkdir -p "${USER_HOME}/.config/zen/mods/darkreader"
    cp -a "${SCRIPT_DIR}/configs/zen/mods/darkreader/." "${USER_HOME}/.config/zen/mods/darkreader/"
  fi
  for profile_dir in "${USER_HOME}/.config/zen"/*; do
    if [[ -d "$profile_dir" && ( "$profile_dir" == *"Default"* || -f "$profile_dir/prefs.js" ) ]]; then
      mkdir -p "$profile_dir/chrome"
      cp -a "${SCRIPT_DIR}/configs/zen/chrome/." "$profile_dir/chrome/"
      cp -a "${SCRIPT_DIR}/configs/zen/user.js" "$profile_dir/user.js" 2>/dev/null || true
      cp -a "${SCRIPT_DIR}/configs/zen/"*.json "$profile_dir/" 2>/dev/null || true
      if [[ -d "${SCRIPT_DIR}/configs/zen/extensions" ]]; then
        mkdir -p "$profile_dir/extensions"
        cp -a "${SCRIPT_DIR}/configs/zen/extensions/." "$profile_dir/extensions/"
      fi
    fi
  done
  echo "  [OK] Zen Browser chrome CSS, Dark Reader mod, extensions, shortcuts, and preferences restored."
fi
if [[ -d "${SCRIPT_DIR}/configs/herdr" ]]; then
  mkdir -p "${USER_HOME}/.config/herdr"
  cp -a "${SCRIPT_DIR}/configs/herdr/." "${USER_HOME}/.config/herdr/"
fi
if [[ -d "${SCRIPT_DIR}/configs/no-mistakes" ]]; then
  mkdir -p "${USER_HOME}/.no-mistakes"
  cp -a "${SCRIPT_DIR}/configs/no-mistakes/." "${USER_HOME}/.no-mistakes/"
fi
if [[ -d "${SCRIPT_DIR}/configs/firstmate/config" ]]; then
  mkdir -p "${USER_HOME}/firstmate/config"
  cp -a "${SCRIPT_DIR}/configs/firstmate/config/." "${USER_HOME}/firstmate/config/"
fi
if [[ -d "${SCRIPT_DIR}/configs/opencode" ]]; then
  mkdir -p "${USER_HOME}/.config/opencode"
  cp -a "${SCRIPT_DIR}/configs/opencode/." "${USER_HOME}/.config/opencode/"
fi
if [[ -d "${SCRIPT_DIR}/configs/copilot" ]]; then
  mkdir -p "${USER_HOME}/.copilot"
  cp -a "${SCRIPT_DIR}/configs/copilot/." "${USER_HOME}/.copilot/"
fi
if [[ -d "${SCRIPT_DIR}/configs/pi" ]]; then
  mkdir -p "${USER_HOME}/.pi/agent/themes"
  cp -a "${SCRIPT_DIR}/configs/pi/agent/." "${USER_HOME}/.pi/agent/"
fi
if [[ -d "${SCRIPT_DIR}/configs/cursor" ]]; then
  echo "  -> Restoring Cursor IDE settings, skills, and omarchy-theme..."
  mkdir -p "${USER_HOME}/.config/Cursor/User"
  cp -a "${SCRIPT_DIR}/configs/cursor/User/." "${USER_HOME}/.config/Cursor/User/"
  mkdir -p "${USER_HOME}/.cursor/extensions"
  cp -a "${SCRIPT_DIR}/configs/cursor/argv.json" "${USER_HOME}/.cursor/" 2>/dev/null || true
  cp -a "${SCRIPT_DIR}/configs/cursor/hooks.json" "${USER_HOME}/.cursor/" 2>/dev/null || true
  cp -a "${SCRIPT_DIR}/configs/cursor/herdr-agent-state.sh" "${USER_HOME}/.cursor/" 2>/dev/null || true
  chmod +x "${USER_HOME}/.cursor/herdr-agent-state.sh" 2>/dev/null || true
  cp -a "${SCRIPT_DIR}/configs/cursor/extensions/." "${USER_HOME}/.cursor/extensions/" 2>/dev/null || true
  cp -a "${SCRIPT_DIR}/configs/cursor/skills-cursor" "${USER_HOME}/.cursor/" 2>/dev/null || true
  # Link Omarchy color theme to active theme
  mkdir -p "${USER_HOME}/.cursor/extensions/omarchy-theme/themes"
  ln -nsf "${USER_HOME}/.local/state/omarchy/current/theme/vscode-theme.json" "${USER_HOME}/.cursor/extensions/omarchy-theme/themes/omarchy-color-theme.json"
  if [[ -f "${USER_HOME}/.local/share/cursor/bin/cursor" ]]; then
    ln -nsf "${USER_HOME}/.local/share/cursor/bin/cursor" "${USER_HOME}/.local/bin/cursor"
    ln -nsf "${USER_HOME}/.local/share/cursor/bin/cursor-tunnel" "${USER_HOME}/.local/bin/cursor-tunnel"
  fi
  echo "  [OK] Cursor IDE settings, skills, and theme restored."
fi
if [[ -d "${SCRIPT_DIR}/configs/antigravity-ide" ]]; then
  echo "  -> Restoring Antigravity IDE settings and omarchy-theme..."
  mkdir -p "${USER_HOME}/.config/Antigravity IDE/User"
  cp -a "${SCRIPT_DIR}/configs/antigravity-ide/User/." "${USER_HOME}/.config/Antigravity IDE/User/"
  mkdir -p "${USER_HOME}/.antigravity-ide/extensions"
  cp -a "${SCRIPT_DIR}/configs/antigravity-ide/argv.json" "${USER_HOME}/.antigravity-ide/" 2>/dev/null || true
  cp -a "${SCRIPT_DIR}/configs/antigravity-ide/extensions/." "${USER_HOME}/.antigravity-ide/extensions/" 2>/dev/null || true
  # Link Omarchy color theme to active theme
  mkdir -p "${USER_HOME}/.antigravity-ide/extensions/omarchy-theme/themes"
  ln -nsf "${USER_HOME}/.local/state/omarchy/current/theme/vscode-theme.json" "${USER_HOME}/.antigravity-ide/extensions/omarchy-theme/themes/omarchy-color-theme.json"
  if [[ -f "${USER_HOME}/.local/share/antigravity-ide/bin/antigravity-ide" ]]; then
    ln -nsf "${USER_HOME}/.local/share/antigravity-ide/bin/antigravity-ide" "${USER_HOME}/.local/bin/antigravity-ide"
  fi
  echo "  [OK] Antigravity IDE settings and theme restored."
fi
if [[ -d "${SCRIPT_DIR}/configs/antigravity-app" ]]; then
  echo "  -> Restoring Antigravity Desktop App and Gemini agent configurations..."
  mkdir -p "${USER_HOME}/.config/Antigravity"
  cp -a "${SCRIPT_DIR}/configs/antigravity-app/app_storage.json" "${USER_HOME}/.config/Antigravity/" 2>/dev/null || true
  cp -a "${SCRIPT_DIR}/configs/antigravity-app/Preferences" "${USER_HOME}/.config/Antigravity/" 2>/dev/null || true
  if [[ -d "${SCRIPT_DIR}/configs/antigravity-app/gemini-config" ]]; then
    mkdir -p "${USER_HOME}/.gemini/config/hooks"
    cp -a "${SCRIPT_DIR}/configs/antigravity-app/gemini-config/." "${USER_HOME}/.gemini/config/"
    chmod +x "${USER_HOME}/.gemini/config/hooks/herdr-agent-state.sh" 2>/dev/null || true
  fi
  if [[ -f "${USER_HOME}/.local/bin/agy" ]]; then
    ln -nsf "${USER_HOME}/.local/bin/agy" "${USER_HOME}/.local/bin/antigravity"
  fi
  echo "  [OK] Antigravity Desktop App configurations restored."
fi
if [[ -d "${SCRIPT_DIR}/lib" ]]; then
  echo "  -> Restoring custom system libraries..."
  mkdir -p "${USER_HOME}/.local/lib"
  cp -a "${SCRIPT_DIR}/lib/." "${USER_HOME}/.local/lib/"
fi
if [[ -d "${SCRIPT_DIR}/configs/foliate" ]]; then
  echo "  -> Restoring Foliate configuration and theme..."
  mkdir -p "${USER_HOME}/.config/com.github.johnfactotum.Foliate"
  cp -a "${SCRIPT_DIR}/configs/foliate/." "${USER_HOME}/.config/com.github.johnfactotum.Foliate/"
fi
if [[ -d "${SCRIPT_DIR}/configs/ytkew" ]]; then
  echo "  -> Restoring ytkew YouTube Music configuration..."
  mkdir -p "${USER_HOME}/.config/ytkew/themes"
  cp -a "${SCRIPT_DIR}/configs/ytkew/." "${USER_HOME}/.config/ytkew/"
fi
if [[ -d "${SCRIPT_DIR}/configs/qdirstat" ]]; then
  echo "  -> Restoring QDirStat configurations..."
  mkdir -p "${USER_HOME}/.config/QDirStat"
  cp -a "${SCRIPT_DIR}/configs/qdirstat/." "${USER_HOME}/.config/QDirStat/"
fi
if [[ -d "${SCRIPT_DIR}/configs/fdm" ]]; then
  echo "  -> Restoring Free Download Manager configurations..."
  mkdir -p "${USER_HOME}/.config/Softdeluxe" "${USER_HOME}/.config/autostart" "${USER_HOME}/.config/zen/native-messaging-hosts"
  cp -a "${SCRIPT_DIR}/configs/fdm/Free Download Manager.conf" "${USER_HOME}/.config/Softdeluxe/" 2>/dev/null || true
  cp -a "${SCRIPT_DIR}/configs/fdm/FDM.desktop" "${USER_HOME}/.config/autostart/" 2>/dev/null || true
  cp -a "${SCRIPT_DIR}/configs/fdm/org.freedownloadmanager.fdm5.cnh.json" "${USER_HOME}/.config/zen/native-messaging-hosts/" 2>/dev/null || true
fi
if [[ -d "${SCRIPT_DIR}/configs/gtk-4.0" ]]; then
  echo "  -> Restoring GTK 4 custom styling..."
  mkdir -p "${USER_HOME}/.config/gtk-4.0"
  cp -a "${SCRIPT_DIR}/configs/gtk-4.0/." "${USER_HOME}/.config/gtk-4.0/"
fi
if [[ -d "${SCRIPT_DIR}/configs/ristretto" ]]; then
  echo "  -> Restoring Ristretto image viewer configuration..."
  mkdir -p "${USER_HOME}/.config/ristretto"
  cp -a "${SCRIPT_DIR}/configs/ristretto/." "${USER_HOME}/.config/ristretto/"
fi
if [[ -d "${SCRIPT_DIR}/configs/xfce4" ]]; then
  mkdir -p "${USER_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml"
  cp -a "${SCRIPT_DIR}/configs/xfce4/xfconf/xfce-perchannel-xml/." "${USER_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/" 2>/dev/null || true
fi
if [[ -d "${SCRIPT_DIR}/configs/fetch" ]]; then
  echo "  -> Restoring fetch configuration..."
  mkdir -p "${USER_HOME}/.config/fetch"
  cp -a "${SCRIPT_DIR}/configs/fetch/config" "${USER_HOME}/.config/fetch/" 2>/dev/null || true
  ln -nsf "${USER_HOME}/.config/omarchy/branding/about.txt" "${USER_HOME}/.config/fetch/logo.txt"
fi
if [[ -d "${SCRIPT_DIR}/configs/omagent" ]]; then
  echo "  -> Restoring Omagent AI assistant configurations & mobile web PWA..."
  mkdir -p "${USER_HOME}/.config/omagent/ssl" "${USER_HOME}/.local/state/omagent/sessions"
  cp -a "${SCRIPT_DIR}/configs/omagent/coding_agent_prompt.md" "${USER_HOME}/.config/omagent/" 2>/dev/null || true
  cp -a "${SCRIPT_DIR}/configs/omagent/agent_identity.md" "${USER_HOME}/.config/omagent/" 2>/dev/null || true
  if [[ -d "${SCRIPT_DIR}/configs/omagent/mobile-web" ]]; then
    mkdir -p "${USER_HOME}/.config/omagent/mobile-web"
    cp -a "${SCRIPT_DIR}/configs/omagent/mobile-web/." "${USER_HOME}/.config/omagent/mobile-web/"
  fi
  if [[ ! -f "${USER_HOME}/.config/omagent/config.json" ]]; then
    cp -a "${SCRIPT_DIR}/configs/omagent/config.json" "${USER_HOME}/.config/omagent/config.json"
    echo "  [INFO] Installed template ~/.config/omagent/config.json. Please update with your Gemini API key."
  fi
  # Generate self-signed TLS cert if missing for secure mobile PWA / WebSocket
  if [[ ! -f "${USER_HOME}/.config/omagent/ssl/cert.pem" || ! -f "${USER_HOME}/.config/omagent/ssl/key.pem" ]]; then
    echo "  -> Generating local self-signed TLS certificates for Omagent mobile bridge..."
    openssl req -x509 -newkey rsa:2048 -nodes \
      -keyout "${USER_HOME}/.config/omagent/ssl/key.pem" \
      -out "${USER_HOME}/.config/omagent/ssl/cert.pem" \
      -days 365 -subj "/CN=omagent.local" 2>/dev/null || true
    chmod 600 "${USER_HOME}/.config/omagent/ssl/key.pem" 2>/dev/null || true
  fi
fi
if [[ -d "${SCRIPT_DIR}/configs/omarchy/homelab-launcher" ]]; then
  mkdir -p "${USER_HOME}/.config/omarchy/homelab-launcher"
  cp -a "${SCRIPT_DIR}/configs/omarchy/homelab-launcher/." "${USER_HOME}/.config/omarchy/homelab-launcher/"
fi
if [[ -d "${SCRIPT_DIR}/configs/strata" ]]; then
  mkdir -p "${USER_HOME}/.config/strata"
  cp -a "${SCRIPT_DIR}/configs/strata/." "${USER_HOME}/.config/strata/"
fi
if [[ -d "${SCRIPT_DIR}/configs/xdg-desktop-portal" ]]; then
  echo "  -> Restoring XDG Desktop Portal and Strata portal config..."
  mkdir -p "${USER_HOME}/.config/xdg-desktop-portal" "${USER_HOME}/.local/share/xdg-desktop-portal/portals"
  cp -a "${SCRIPT_DIR}/configs/xdg-desktop-portal/portals.conf" "${USER_HOME}/.config/xdg-desktop-portal/" 2>/dev/null || true
  cp -a "${SCRIPT_DIR}/configs/xdg-desktop-portal/hyprland-portals.conf" "${USER_HOME}/.config/xdg-desktop-portal/" 2>/dev/null || true
  cp -a "${SCRIPT_DIR}/configs/xdg-desktop-portal/strata.portal" "${USER_HOME}/.local/share/xdg-desktop-portal/portals/" 2>/dev/null || true
fi
if [[ -d "${SCRIPT_DIR}/configs/dbus-services" ]]; then
  mkdir -p "${USER_HOME}/.local/share/dbus-1/services"
  cp -a "${SCRIPT_DIR}/configs/dbus-services/." "${USER_HOME}/.local/share/dbus-1/services/"
fi
if [[ -d "${SCRIPT_DIR}/agents" ]]; then
  mkdir -p "${USER_HOME}/.agents/rules" "${USER_HOME}/.agents/skills" "${USER_HOME}/.agents/learnings"
  cp -a "${SCRIPT_DIR}/agents/rules/." "${USER_HOME}/.agents/rules/"
  cp -a "${SCRIPT_DIR}/agents/skills/." "${USER_HOME}/.agents/skills/"
  if [[ -d "${SCRIPT_DIR}/agents/learnings" ]]; then
    cp -a "${SCRIPT_DIR}/agents/learnings/." "${USER_HOME}/.agents/learnings/"
  fi
  echo "  [OK] Agent rules, skills, and learnings restored."
  mkdir -p "${USER_HOME}/.pi/agent/skills"
  for sk in "${USER_HOME}/.agents/skills"/*; do
    if [[ -e "$sk" ]]; then
      sk_name="$(basename "$sk")"
      ln -nsf "$sk" "${USER_HOME}/.pi/agent/skills/${sk_name}"
    fi
  done
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
if [[ -f "${USER_HOME}/.local/bin/omaagent" ]]; then
  ln -nsf "${USER_HOME}/.local/bin/omaagent" "${USER_HOME}/.local/bin/omagent"
fi
if [[ -f "${USER_HOME}/.local/bin/firstmate" ]]; then
  ln -nsf "${USER_HOME}/.local/bin/firstmate" "${USER_HOME}/.local/bin/fm"
fi
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
if [[ -f "${SCRIPT_DIR}/lib/omarchy_theme.py" ]]; then
  PYTHON_USER_SITE="$(python3 -m site --user-site 2>/dev/null || echo "${USER_HOME}/.local/lib/python3.14/site-packages")"
  mkdir -p "$PYTHON_USER_SITE"
  cp -a "${SCRIPT_DIR}/lib/omarchy_theme.py" "${PYTHON_USER_SITE}/"
  echo "  [OK] Installed Python theme library: ${PYTHON_USER_SITE}/omarchy_theme.py"
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
if [[ -d "${SCRIPT_DIR}/pixmaps" ]]; then
  mkdir -p "${USER_HOME}/.local/share/pixmaps"
  cp -a "${SCRIPT_DIR}/pixmaps/." "${USER_HOME}/.local/share/pixmaps/"
  if [[ -f "${SCRIPT_DIR}/pixmaps/antigravity.png" ]]; then
    mkdir -p "${USER_HOME}/.local/share/icons/hicolor/256x256/apps"
    cp -a "${SCRIPT_DIR}/pixmaps/antigravity.png" "${USER_HOME}/.local/share/icons/hicolor/256x256/apps/"
    mkdir -p "${USER_HOME}/.local/share/icons/hicolor/scalable/apps"
    cp -a "${SCRIPT_DIR}/pixmaps/ytkew.svg" "${USER_HOME}/.local/share/icons/hicolor/scalable/apps/" 2>/dev/null || true
  fi
fi

if command -v flatpak >/dev/null 2>&1; then
  echo "  -> Ensuring Flatpak user remote and apps..."
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
  if [[ -f "${SCRIPT_DIR}/meta/flatpak-packages.txt" ]]; then
    flatpak install --user -y flathub com.stremio.Stremio 2>/dev/null || true
  fi
fi

echo ""
echo "==> Step 11: Applying customizations and restarting components..."
if command -v systemctl >/dev/null 2>&1; then
  echo "  -> Reloading systemd user daemon and enabling user services..."
  systemctl --user daemon-reload 2>/dev/null || true
  systemctl --user enable omagent-crash-watch.service omagent-mobile-bridge.service 2>/dev/null || true
fi

if command -v omarchy >/dev/null 2>&1; then
  echo "  -> Setting theme: Moodpeak"
  omarchy theme set "Moodpeak" || true

  if [[ -x "${USER_HOME}/.local/bin/omarchy-sync-zen" ]]; then
    echo "  -> Syncing Zen Browser with active Omarchy theme..."
    "${USER_HOME}/.local/bin/omarchy-sync-zen" 2>/dev/null || true
  fi

  if [[ -x "${USER_HOME}/.local/bin/omarchy-sync-brave" ]]; then
    echo "  -> Syncing Brave Origin with active Omarchy theme..."
    "${USER_HOME}/.local/bin/omarchy-sync-brave" --sync 2>/dev/null || true
  fi

  if [[ -x "${USER_HOME}/.local/bin/omarchy-sync-vlc" ]]; then
    echo "  -> Syncing VLC with active Omarchy theme..."
    "${USER_HOME}/.local/bin/omarchy-sync-vlc" --sync 2>/dev/null || true
  fi

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
echo "  - Current theme: Moodpeak"
echo "  - Current font: JetBrainsMono Nerd Font"
echo "  - Bar Layout: Custom floating bar with 14 plugins"
echo "  - Window Manager: Hyprland with blur, scale 2, and custom bindings"
echo "========================================================"
