#!/bin/bash
# Hook triggered on Omarchy theme-set to sync all editors (Cursor, Neovim, VS Code, agy, bat)
THEME_NAME="$1"

CURRENT_THEME_DIR="$HOME/.local/state/omarchy/current/theme"
GENERATED_THEME="$CURRENT_THEME_DIR/vscode-theme.json"
MODE_ENV="$HOME/.local/state/omarchy/theme-mode.env"

is_light=false
if [[ -f "$CURRENT_THEME_DIR/mode" && "$(cat "$CURRENT_THEME_DIR/mode" 2>/dev/null)" == "light" ]]; then
  is_light=true
elif grep -q '^mode\s*=\s*"light"' "$CURRENT_THEME_DIR/colors.toml" 2>/dev/null; then
  is_light=true
elif [[ -f "$MODE_ENV" ]] && grep -q 'OMARCHY_THEME_MODE="light"' "$MODE_ENV"; then
  is_light=true
fi

# 0. Ensure vscode-theme.json is compiled from user template if present
USER_TPL="$HOME/.config/omarchy/themed/vscode-theme.json.tpl"
if [[ -f "$USER_TPL" && -f "$CURRENT_THEME_DIR/colors.toml" ]]; then
  sed_script=$(mktemp)
  while IFS=$'\t' read -r key value; do
    printf "s|{{ %s }}|%s|g\n" "$key" "$value" >>"$sed_script"
    printf "s|{{ %s_strip }}|%s|g\n" "$key" "${value#\#}" >>"$sed_script"
  done < <(omarchy-theme-color --file "$CURRENT_THEME_DIR/colors.toml" --all)
  sed -f "$sed_script" "$USER_TPL" > "$GENERATED_THEME.tmp" && mv "$GENERATED_THEME.tmp" "$GENERATED_THEME"
  rm -f "$sed_script"
fi

# 1. Sync Cursor & VS Code extensions and settings
sync_vscode_like() {
  local ext_base="$1"
  local settings_path="$2"

  [[ -d "$(dirname "$ext_base")" || -d "$(dirname "$settings_path")" ]] || return 0

  local ext_dir="$ext_base/omarchy-theme"
  local ui_theme="vs-dark"
  if [[ "$is_light" == "true" ]]; then
    ui_theme="vs"
  fi

  if [[ -f "$GENERATED_THEME" ]]; then
    mkdir -p "$ext_dir/themes"
    ln -sfn "$GENERATED_THEME" "$ext_dir/themes/omarchy-color-theme.json"

    cat > "$ext_dir/package.json" <<PKG
{
    "name": "omarchy-theme",
    "displayName": "Omarchy",
    "description": "Omarchy color theme",
    "publisher": "local",
    "version": "1.0.0",
    "engines": { "vscode": "^1.70.0" },
    "categories": ["Themes"],
    "contributes": {
        "themes": [{
            "label": "Omarchy",
            "uiTheme": "$ui_theme",
            "path": "./themes/omarchy-color-theme.json"
        }]
    }
}
PKG

    # Update extensions.json
    local extensions_file="$ext_base/extensions.json"
    mkdir -p "$ext_base"
    [[ -f "$extensions_file" ]] || printf '[]\n' >"$extensions_file"

    local tmp
    tmp=$(mktemp)
    if jq \
      --arg id "local.omarchy-theme" \
      --arg version "1.0.0" \
      --arg fs_path "$ext_dir" \
      --arg external "file://$ext_dir" \
      --arg relative "omarchy-theme" \
      'map(select(.identifier.id != $id)) + [{
        identifier: { id: $id },
        version: $version,
        location: {
          "$mid": 1,
          fsPath: $fs_path,
          external: $external,
          path: $fs_path,
          scheme: "file"
        },
        relativeLocation: $relative
      }]' "$extensions_file" >"$tmp" 2>/dev/null; then
      mv "$tmp" "$extensions_file"
    else
      rm -f "$tmp"
    fi

    # Update settings.json
    mkdir -p "$(dirname "$settings_path")"
    [[ -f "$settings_path" ]] || printf '{\n}\n' >"$settings_path"

    tmp=$(mktemp)
    if jq \
      '.["workbench.colorTheme"] = "Omarchy" | .["workbench.preferredLightColorTheme"] = "Omarchy" | .["workbench.preferredDarkColorTheme"] = "Omarchy" | .["editor.semanticHighlighting.enabled"] = true' \
      "$settings_path" >"$tmp" 2>/dev/null; then
      mv "$tmp" "$settings_path"
    else
      rm -f "$tmp"
    fi
  fi
}

# Sync Cursor
sync_vscode_like "$HOME/.cursor/extensions" "$HOME/.config/Cursor/User/settings.json"

# Sync Antigravity IDE
sync_vscode_like "$HOME/.antigravity-ide/extensions" "$HOME/.config/Antigravity IDE/User/settings.json"

# Sync VS Code / VSCodium if present
sync_vscode_like "$HOME/.vscode/extensions" "$HOME/.config/Code/User/settings.json"
sync_vscode_like "$HOME/.vscode-oss/extensions" "$HOME/.config/VSCodium/User/settings.json"

# 2. Sync Antigravity CLI (agy)
AGY_SETTINGS="$HOME/.gemini/antigravity-cli/settings.json"
if [[ -f "$AGY_SETTINGS" ]]; then
  agy_theme_pref="THEME_PREFERENCE_DARK"
  if [[ "$is_light" == "true" ]]; then
    agy_theme_pref="THEME_PREFERENCE_LIGHT"
  fi
  tmp=$(mktemp)
  if jq --arg pref "$agy_theme_pref" '.themePreference = $pref' "$AGY_SETTINGS" >"$tmp" 2>/dev/null; then
    mv "$tmp" "$AGY_SETTINGS"
  else
    rm -f "$tmp"
  fi
fi

# 3. Sync Antigravity Base App
ANTIGRAVITY_TPL="$HOME/.config/omarchy/themed/antigravity.css.tpl"
GENERATED_ANTIGRAVITY_CSS="$CURRENT_THEME_DIR/antigravity.css"
if [[ -f "$ANTIGRAVITY_TPL" && -f "$CURRENT_THEME_DIR/colors.toml" ]]; then
  sed_script=$(mktemp)
  while IFS=$'\t' read -r key value; do
    printf "s|{{ %s }}|%s|g\n" "$key" "$value" >>"$sed_script"
    printf "s|{{ %s_strip }}|%s|g\n" "$key" "${value#\#}" >>"$sed_script"
  done < <(omarchy-theme-color --file "$CURRENT_THEME_DIR/colors.toml" --all)
  sed -f "$sed_script" "$ANTIGRAVITY_TPL" > "$GENERATED_ANTIGRAVITY_CSS.tmp" && mv "$GENERATED_ANTIGRAVITY_CSS.tmp" "$GENERATED_ANTIGRAVITY_CSS"
  rm -f "$sed_script"
fi

GEMINI_CONFIG="$HOME/.gemini/config/config.json"
if [[ -f "$GEMINI_CONFIG" ]]; then
  app_theme_mode="THEME_MODE_DARK"
  if [[ "$is_light" == "true" ]]; then
    app_theme_mode="THEME_MODE_LIGHT"
  fi
  tmp=$(mktemp)
  if jq --arg mode "$app_theme_mode" '.userSettings.themeMode = $mode' "$GEMINI_CONFIG" >"$tmp" 2>/dev/null; then
    mv "$tmp" "$GEMINI_CONFIG"
  else
    rm -f "$tmp"
  fi
fi

# 4. Sync Cursor Base App (Cursor Glass / Agents)
CURSOR_GLASS_TPL="$HOME/.config/omarchy/themed/cursor-glass.css.tpl"
GENERATED_CURSOR_GLASS_CSS="$CURRENT_THEME_DIR/cursor-glass.css"
if [[ -f "$CURSOR_GLASS_TPL" && -f "$CURRENT_THEME_DIR/colors.toml" ]]; then
  sed_script=$(mktemp)
  while IFS=$'\t' read -r key value; do
    printf "s|{{ %s }}|%s|g\n" "$key" "$value" >>"$sed_script"
    printf "s|{{ %s_strip }}|%s|g\n" "$key" "${value#\#}" >>"$sed_script"
  done < <(omarchy-theme-color --file "$CURRENT_THEME_DIR/colors.toml" --all)
  sed -f "$sed_script" "$CURSOR_GLASS_TPL" > "$GENERATED_CURSOR_GLASS_CSS.tmp" && mv "$GENERATED_CURSOR_GLASS_CSS.tmp" "$GENERATED_CURSOR_GLASS_CSS"
  rm -f "$sed_script"
  if [[ -d "$HOME/.local/share/cursor/resources/app/out/vs/workbench" ]]; then
    cp "$GENERATED_CURSOR_GLASS_CSS" "$HOME/.local/share/cursor/resources/app/out/vs/workbench/cursor-glass.css"
  fi
fi
