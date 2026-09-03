# Omarchy Restoration & Customization Guide for AI Agents

> **Audience**: Any AI agent (Antigravity, Claude, Codex, OpenCode, Gemini, etc.) or developer restoring these configurations onto a fresh or existing [Omarchy](https://omarchy.org/) Linux installation.
> **Author / Original Environment**: Soham Sanat (`sohamSanat`), Omarchy 4.0.2-1 on Arch Linux + Hyprland (Wayland).

---

## 1. Core System Architecture & Critical Rules

Omarchy is an opinionated Arch Linux distribution featuring Hyprland as the Wayland compositor and Quickshell (`omarchy-shell`) providing the top status bar, OSD, notifications, and menus.

### The Golden Rule
**NEVER EDIT ANYTHING IN `/usr/share/omarchy/`**.
- That directory is managed strictly by upstream Omarchy package updates and migrations. Any local modifications there will be wiped during the next `omarchy update`.
- All user overrides **MUST** reside in `~/.config/` or `~/.local/`.
- Reading `/usr/share/omarchy/` is completely safe and encouraged for reference.

---

## 2. Inventory of Customizations in this Backup

This repository contains the full snapshot of user customizations:

### A. Omarchy Core (`configs/omarchy/` -> `~/.config/omarchy/`)
1. **`shell.json`**:
   - Floating bar layout (`charlieras262.floating-bar`) at the top.
   - Configured sections:
     - **Left**: `omarchy.workspaces`, `omarchy.agents`, `krall.switchboard`.
     - **Center**: `omarchy.clock` (custom format `dddd HH:mm`), `omarchy.keyboard-layout`, `mryll.meteobar`, `io.github.diegopluna.argus`, `omarchy.system-update`.
     - **Right**: `omarchy.tray`, `io.github.ricky.whatsapp`, `omamail`, `io.github.nilszeilon.omarchy-sensei`, `io.github.elevate08.qs-bitwarden-cli` (with fingerprint unlock & 60s clipboard clear), `jkoestinger.vpn`, `io.github.r-witz.nothing-ear`, `omaconnect`, `omarchy.bluetooth`, `omarchy.network`, `omarchy.audio`, `omarchy.monitor`, `soham.power`.
   - Idle screen lock timers: screensaver at 150s, lock at 300s.
2. **`extensions/omarchy-menu.jsonc`**:
   - Replaced default Gemini menu entry with **Antigravity AI Agent** (`setup.default.agent.antigravity`).
   - Integrated **Omarchy Sensei** coaching actions and shortcuts across menus.
   - Integrated **ThemeBook** picker (`style.theme`).
3. **`defaults/agent`**: Set to `antigravity`.
4. **`battery-limiter.json` & `themebook.json`**: Preserved settings for battery charge limiting (80%) and theme switcher catalog.
5. **`themed/`**: Custom theme templates (`.tpl`) that dynamically recompile on `omarchy theme set`:
   - `gum_env.lua.tpl`: CLI prompt colors.
   - `kdeglobals.tpl`: KDE / Qt theme colors.
   - `obsidian.css.tpl`: Dynamic Obsidian app styling based on system theme.
   - `zen.css.tpl`: Zen Browser custom CSS colors and window transparency.
6. **`hooks/`**:
   - `theme-set.d/`: `kde-sync.sh`, `obsidian-sync.sh`, `zen-sync.sh` (syncs active theme across KDE, Obsidian, and Zen Browser).
   - `post-update.d/`: `omarchy-sensei` refresher, `setup-agent.hook`, `setup-fingerprint.hook`, `install-voxtype.hook`.

### B. Hyprland Window Manager (`configs/hypr/` -> `~/.config/hypr/`)
1. **`hyprland.lua`**:
   - Loads `sensei.lua` before Omarchy defaults.
   - Custom window rule: Obsidian glass transparency (`opacity = "0.85 0.78"`).
   - Dynamically loads `border-fx.lua`.
2. **`bindings.lua`**:
   - Unbinds default file manager keys (`SUPER + SHIFT + F`, `SUPER + ALT + SHIFT + F`) and binds them to **Strata**.
3. **`looknfeel.lua`**:
   - Rounded corners: `rounding = 10`.
   - Advanced blur: `size = 6, passes = 2, noise = 0.05, contrast = 1.05, brightness = 1.02, vibrancy = 0.2, popups = true`.
   - Drop shadows: `range = 15, render_power = 3, color = rgba(00000044)`.
4. **`input.lua`**:
   - Multi-keyboard layout: `kb_layout = "us,dk,eu"`, toggle with `Left Alt + Right Alt` (`grp:alts_toggle`), `intl` variant.
   - Sensitivity: `0.25`, flat mouse acceleration profile.
   - Touchpad: natural scroll, clickfinger behavior, scroll factor `0.2`, `disable_while_typing = false`, 3-finger drag.
5. **`monitors.lua`**:
   - Display scaling: `GDK_SCALE = 2` and monitor scale = `2`.
6. **`hyprsunset.conf`**: Identity profile at 07:00 to eliminate default blue tint.
7. **`border-fx.lua` & `sensei.lua`**: Custom border effects and Sensei key coaching.

### C. Terminals & Tools (`configs/terminals/`, `configs/`)
- `alacritty.toml`, `foot.ini`, `ghostty/config`, `kitty.conf`.
- `starship.toml`, `btop/btop.conf`, `git/config`, `lazygit/config.yml`.
- `nvim/` (LazyVim user configurations).
- `tmux/tmux.conf`, `mise/config.toml`, `voxtype/config.toml`, `tensaku/config.toml`.
- `fastfetch/config.jsonc` (custom hardware/OS display using Omarchy ASCII art).
- `bashrc` and `bash_profile`.

### D. Themes (`themes/` -> `~/.config/omarchy/themes/`)
9 themes with all assets and wallpapers included:
- `sakura-mochi` (**Active theme**)
- `aetheria`, `artzen`, `harbor`, `harbordark`, `moodpeak`, `purple-moon`, `quattrocento-light`, `aether`.

### E. Shell Plugins (`plugins/` -> `~/.config/omarchy/plugins/`)
20 plugins included with complete source code:
- **`mahmoodkhalil57.qrgen`**: QR generator bar widget with dynamic theme foreground/background adaptation (includes custom patch).
- **`reomarchy.workspace-switcher`**: Visual workspace switcher with hold-Super activation, live screencopy previews, and digit jumping (includes custom patch).
- **`io.github.adamcbrewer.voxtype-aura`**: Native audio recording OSD for Voxtype dictation.
- **`io.github.weedwhitesandwine.obsiduous`**: Obsidian status & indexing bar widget (includes custom vault path resolution patch).
- **`x692137x.powerwave`**: PowerWave audio wave animation indicator.
- **`jrmmhm.pocket`**: Collapsible drawer plugin that groups tray and status widgets together.
- **`soham.power`**: Fully custom battery limiter & power panel plugin written by Soham.
- **`charlieras262.floating-bar`**: Custom floating status bar container.
- **`chispes.agent-gemini`**: Enhanced with custom launcher commands.
- **`io.github.calebhat.themebook`**: Enhanced theme browser with catalog support.
- **`io.github.diegopluna.argus`**: Enhanced hardware monitor.
- **`io.github.nilszeilon.omarchy-sensei`**: Keybinding tutor plugin with custom patches.
- **`io.github.elevate08.qs-bitwarden-cli`**: Bitwarden bar widget with fingerprint unlock.
- **`io.github.ricky.whatsapp`**: WhatsApp bar widget & daemon.
- **`io.github.r-witz.nothing-ear`**: Nothing Ear device controller.
- **`jkoestinger.vpn`**: VPN connection widget.
- **`krall.switchboard`**: Quick settings switcher.
- **`mryll.meteobar`**: Weather bar widget.
- **`omaconnect`**: KDE Connect bar integration.
- **`omamail`**: Email notification widget.

### F. Custom Binaries & Helper Scripts (`bin/` -> `~/.local/bin/`)
- `omarchy-agent`: Launch coding agents; updated to natively support **Antigravity** (`agy`).
- `omarchy-default-agent`: Get/set default coding agent; updated to support Antigravity.
- `omarchy-sensei`: Sensei coaching tool CLI.
- `omarchy-sync-kde`: Renders `kdeglobals` and applies color scheme to KDE/Qt apps.
- `omarchy-sync-obsidian`: Extracts theme colors and writes them to Obsidian CSS snippets.
- `omarchy-sync-zen`: Injects Omarchy CSS variables, userChrome.css, userContent.css, and transparency into Zen Browser.
- `omniroute` & `omniroute-desktop`: OmniRoute desktop launchers.

### G. Custom Libraries (`lib/` -> `~/.local/lib/`)
- `hypr/hypr-shiny-border.so`: Compiled Hyprland border plugin used by `border-fx.lua`.
- `omarchy-whatsapp/sweep`: Session cleaner script for WhatsApp widget.

---


### H. Herdr, Firstmate, no-mistakes & AXI Tooling
1. **Herdr (`configs/herdr/config.toml` -> `~/.config/herdr/config.toml`)**:
   - Terminal multiplexer config with prefix `ctrl+space`, custom pane splitting, tab switching, and follow-cwd settings.
2. **Firstmate (`bin/firstmate`, `bin/treehouse`, `configs/firstmate/`)**:
   - Agent fleet orchestrator CLI (`firstmate` and `fm` symlink).
   - Git worktree runner `treehouse`.
3. **no-mistakes (`configs/no-mistakes/config.yaml` -> `~/.no-mistakes/config.yaml`)**:
   - Multi-agent auto-fix, guarded branch synchronization, review provenance capture, and intent extraction.
4. **Agent Skills & Rules (`agents/` -> `~/.agents/`)**:
   - Rules: `agents/rules/axi.md` (AXI token-efficient tooling guidelines).
   - Skills: `herdr`, `firstmate`, `axi`, `agent-architecture-design`, `agent-evals-and-benchmarking`, `agent-memory-and-rag`, `agentic-research-scout`, `mcp-and-tool-engineering`, `multi-agent-orchestrator`.
5. **AXI Global CLIs**:
   - Install via npm: `npm install -g gh-axi chrome-devtools-axi tasks-axi quota-axi lavish-axi`.


6. **Compound Engineering Skills & Treehouse**:
   - `agents/skills/` contains the full offline copies of all 34+ skills including `treehouse`, `lfg`, and the entire `ce-*` workflow suite (`ce-plan`, `ce-work`, `ce-code-review`, `ce-debug`, etc.).
7. **OpenCode & Copilot AXI Context**:
   - `configs/opencode/` -> `~/.config/opencode/`
   - `configs/copilot/hooks/lavish-axi.json` -> `~/.copilot/hooks/lavish-axi.json`
8. **External Repositories**:
   - Refer to `meta/external-repos.json` to inspect or clone upstream repos (`axi`, `compound-engineering-plugin`, `firstmate`, `foliate`, `treehouse`).

## 3. Fast Restoration (Automated)

To apply everything at once, simply clone this repository onto the target Omarchy machine and execute:

```bash
cd omarchy-backup
./restore.sh
```

The script will:
1. Create timestamped backups of any pre-existing config files before touching them.
2. Deploy all configuration files, themes, plugins, scripts, libraries, and desktop entries.
3. Fix file permissions (`chmod +x`).
4. Reinstall Node dependencies for the WhatsApp daemon if `npm` is present.
5. Apply the active theme (`Sakura Mochi`) and font (`JetBrainsMono Nerd Font`).
6. Reload the shell, terminals, and Hyprland.

---

## 4. Manual Step-by-Step Restoration Protocol

If you prefer to apply configurations incrementally or debug an issue, follow these steps in order:

### Step 1: Install Required Packages
Check `meta/aur-packages.txt` and `meta/installed-packages.txt`. At minimum, ensure these packages are installed:
```bash
# Core tools & AUR packages
omarchy pkg aur add brave-origin-nightly-bin fetch-git libfprint-fpc1022 meteobar-bin
# Note: Strata file manager binary lives in ~/.local/bin/strata or can be installed via cargo/AUR
```

Ensure `mise` tools are installed:
```bash
mise install
```

### Step 2: Deploy Omarchy Core & Themes
```bash
cp -a configs/omarchy/. ~/.config/omarchy/
chmod +x ~/.config/omarchy/hooks/*/*

cp -a themes/. ~/.config/omarchy/themes/
cp -a plugins/. ~/.config/omarchy/plugins/
```

### Step 3: Deploy Hyprland & Terminals
```bash
cp -a configs/hypr/. ~/.config/hypr/
for term in alacritty foot ghostty kitty; do
  mkdir -p ~/.config/$term
  cp -a configs/terminals/$term/. ~/.config/$term/
done
```

### Step 4: Deploy User Scripts & Libraries
```bash
mkdir -p ~/.local/bin ~/.local/lib/hypr ~/.local/lib/omarchy-whatsapp ~/.local/share/applications

cp -a bin/. ~/.local/bin/
chmod +x ~/.local/bin/*

cp -a lib/hypr/hypr-shiny-border.so ~/.local/lib/hypr/
cp -a lib/omarchy-whatsapp/sweep ~/.local/lib/omarchy-whatsapp/
chmod +x ~/.local/lib/omarchy-whatsapp/sweep

cp -a desktop-entries/. ~/.local/share/applications/
update-desktop-database ~/.local/share/applications 2>/dev/null || true
```

### Step 5: Setup Plugin Symlinks
```bash
ln -nsf ~/.config/omarchy/plugins/soham.power/scripts/battery-limiter.sh ~/.local/bin/omarchy-battery-limit

for wa_bin in omarchy-whatsapp omarchy-whatsapp-ctl omarchy-whatsapp-daemon omarchy-whatsapp-focus omarchy-whatsapp-login omarchy-whatsapp-open; do
  ln -nsf ~/.config/omarchy/plugins/io.github.ricky.whatsapp/bin/$wa_bin ~/.local/bin/$wa_bin
done
```

### Step 6: Deploy Other Configurations
```bash
cp -a configs/starship.toml ~/.config/
cp -a configs/btop ~/.config/
cp -a configs/git ~/.config/
cp -a configs/lazygit ~/.config/
cp -a configs/nvim ~/.config/
cp -a configs/tmux ~/.config/
cp -a configs/mise ~/.config/
cp -a configs/voxtype ~/.config/
cp -a configs/tensaku ~/.config/
cp -a configs/omniroute ~/.config/
cp -a configs/kdeglobals ~/.config/
cp -a configs/mimeapps.list ~/.config/
cp -a configs/xdg-terminals.list ~/.config/
cp -a configs/fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc
cp -a configs/shell/bashrc ~/.bashrc
cp -a configs/shell/bash_profile ~/.bash_profile
```

### Step 7: Apply Theming & Restart Services
```bash
# 1. Apply theme and font
omarchy theme set "Aetheria"
omarchy font set "JetBrainsMono Nerd Font"

# 2. Rescan plugins and restart quickshell
omarchy-shell shell rescanPlugins
omarchy restart shell
omarchy restart terminal

# 3. Reload Hyprland and validate
hyprctl reload
hyprctl configerrors
```

---

## 5. Verification Checklist for the AI Agent

Run these commands after restoration to verify system health:

| Component | Verification Command | Expected Outcome |
|-----------|----------------------|------------------|
| **Theme** | `omarchy theme current` | Prints `Aetheria` |
| **Font** | `omarchy font current` | Prints `JetBrainsMono Nerd Font` |
| **Hyprland** | `hyprctl configerrors` | Prints `ok` (no syntax errors) |
| **Default Agent** | `omarchy-default-agent` | Prints `antigravity` |
| **Status Bar** | `pgrep -a omarchy-shell` | Running, floating bar with widgets visible |
| **Sensei** | `omarchy-sensei status` | Operational |
| **Zen Sync** | `omarchy-sync-zen` | Completes with exit code 0 |
| **KDE Sync** | `omarchy-sync-kde` | Completes with exit code 0 |
| **Keybindings** | `omarchy menu keybindings --print` | Includes custom Strata shortcuts |

---

## 6. Common Pitfalls & Troubleshooting

1. **Quickshell widgets do not immediately show**:
   - Cause: Quickshell plugins cache.
   - Fix: Run `omarchy-shell shell rescanPlugins` and then `omarchy restart shell`.
2. **WhatsApp plugin daemon complains about missing node_modules**:
   - Cause: `node_modules` is excluded from git (best practice).
   - Fix: `cd ~/.config/omarchy/plugins/io.github.ricky.whatsapp/daemon && npm install --omit=dev`.
3. **Hyprland shiny border plugin fails to load**:
   - Cause: ABI mismatch if Hyprland was updated to a newer major version.
   - Fix: Check `hyprctl plugins list`. If incompatible, rebuild `hypr-shiny-border` from source for the current Hyprland version.
4. **Git warns about embedded repos**:
   - Handled: All nested `.git` directories in themes and plugins were cleanly stripped in this backup. Upstream repository URLs are preserved in `meta/themes-sources.json` and `meta/plugins-sources.json`.
