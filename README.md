# 🌸 Omarchy Customizations & Dotfiles Backup

A complete, production-ready backup of all user configurations, custom themes, Quickshell plugins, Hyprland window rules, automation hooks, and helper scripts for **[Omarchy Linux](https://omarchy.org/)**.

This repository ensures your desktop setup is completely reproducible, disaster-proof, and easily restorable onto any fresh Omarchy installation.

---

## 🌟 Customization Highlights

- **Active Theme**: `Aetheria` (with custom live-rendered templates and wallpapers).
- **Status Bar**: Top floating bar (`charlieras262.floating-bar`) loaded with 20 modular plugins.
- **Custom Plugins**: Includes `soham.power` (custom battery limiter & power panel developed by Soham), `chispes.agent-gemini`, `io.github.calebhat.themebook`, `io.github.diegopluna.argus`, `io.github.nilszeilon.omarchy-sensei`, `io.github.ricky.whatsapp`, `mryll.meteobar`, `omamail`, and more.
- **Theme Sync Engine**: Automated hooks (`theme-set.d`) that instantly propagate active theme colors and transparency into:
  - **Zen Browser** (`omarchy-sync-zen` + dynamic `zen.css.tpl`)
  - **Obsidian** (`omarchy-sync-obsidian` + dynamic `obsidian.css.tpl`)
  - **KDE / Qt Apps** (`omarchy-sync-kde` + dynamic `kdeglobals.tpl`)
- **Default AI Agent**: Configured to launch **Antigravity** (`agy`) seamlessly via `omarchy-agent` and quick-launcher menus.
- **Hyprland Overrides**:
  - Rounded corners (`rounding = 10`), custom vibrant glass blur, and drop shadows.
  - Custom window rules for Obsidian background wallpaper bleed-through.
  - Multi-language keyboard layout (`us,dk,eu` toggled via `Left Alt + Right Alt`).
  - High-resolution display scaling (`scale = 2`).
  - Strata file manager bound to `SUPER + SHIFT + F`.
- **Terminals**: Synchronized configs for Alacritty, Foot, Ghostty, and Kitty.

---

## 📁 Repository Structure

```text
omarchy-backup/
├── README.md                      # This file
├── AI_AGENT_RESTORE_GUIDE.md      # Detailed restoration manual for AI Agents
├── restore.sh                     # Automated one-click restoration script
├── configs/
│   ├── omarchy/                   # Shell layout, themebook, menu extensions, templates, hooks
│   ├── hypr/                      # Hyprland Lua configurations, bindings, rules, input
│   ├── terminals/                 # Alacritty, Foot, Ghostty, Kitty
│   ├── btop/                      # btop monitor configuration
│   ├── git/                       # Git global configuration
│   ├── lazygit/                   # Lazygit configuration
│   ├── nvim/                      # Neovim / LazyVim configuration
│   ├── tmux/                      # Tmux terminal multiplexer
│   ├── mise/                      # Tool version manager (node, codex, gemini, opencode, gh)
│   ├── voxtype/                   # Voice dictation config
│   ├── tensaku/                   # Tensaku text checker config
│   ├── omniroute/                 # OmniRoute application settings
│   ├── fastfetch/                 # Fastfetch hardware info config
│   ├── starship.toml              # Starship prompt configuration
│   └── shell/                     # .bashrc and .bash_profile
├── themes/                        # 9 fully asset-packed Omarchy themes
├── plugins/                       # 14 Quickshell status bar plugins & widgets
├── bin/                           # Custom scripts deployed to ~/.local/bin
├── lib/                           # Compiled plugins (~/.local/lib/hypr/hypr-shiny-border.so)
├── desktop-entries/               # Custom application launchers (~/.local/share/applications/)
└── meta/                          # System specs, package manifests, and upstream git sources
```

---


---

## 🤖 Agentic Distro, Herdr & AXI Tooling

This backup integrates frontier agent tooling and multi-agent fleet operations:
- **Herdr Integration**: Configuration (`~/.config/herdr/config.toml`) mapping tmux layouts, panes, tabs, and mouse capture into Herdr.
- **Firstmate Distro**: Fleet manager CLI (`firstmate` / `fm`), task dispatch, and integration with `treehouse` worktrees.
- **no-mistakes**: Automated multi-agent review, verification, auto-repair, and guarded git merge pipeline (`~/.no-mistakes/config.yaml`).
- **AXI Standards & Tools**:
  - Global CLI tools: `gh-axi`, `chrome-devtools-axi`, `tasks-axi`, `quota-axi`, `lavish-axi`.
  - Guidelines and rule set: `~/.agents/rules/axi.md`.
  - Frontier Agent Skills in `~/.agents/skills/`: `herdr`, `firstmate`, `axi`, `agent-architecture-design`, `agent-evals-and-benchmarking`, `agent-memory-and-rag`, `agentic-research-scout`, `mcp-and-tool-engineering`, `multi-agent-orchestrator`.


### 🛠️ Compound Engineering & Agent Suite
- **Treehouse**: Reusable, isolated git worktree engine (`bin/treehouse`, skill in `agents/skills/treehouse`).
- **Compound Engineering Plugin**: 25+ specialized engineering and orchestration skills (`ce-brainstorm`, `ce-plan`, `ce-work`, `ce-code-review`, `ce-debug`, `ce-test-browser`, `lfg`, etc.) in `agents/skills/`.
- **OpenCode & Copilot Integrations**:
  - OpenCode AXI & Herdr plugins: `configs/opencode/plugins/` (`axi-*.js`, `herdr-agent-state.js`, `herdr-tui-session.js`).
  - GitHub Copilot AXI ambient context hook: `configs/copilot/hooks/lavish-axi.json`.
- **External Cloned Repositories**: Tracked in `meta/external-repos.json` (`axi`, `compound-engineering-plugin`, `firstmate`, `foliate`, `treehouse`).


### 🥧 Pi Coding Agent Harness Integration
- **Direct Skill Linkage**: All 45+ agent skills from `~/.agents/skills/` are symlinked into `~/.pi/agent/skills/`, giving Pi instant access to `herdr`, `firstmate`, `treehouse`, and all `ce-*` skills.
- **Global Context & AXI Standards**: `~/.pi/agent/AGENTS.md` equips Pi with AXI tool preference rules, Omarchy safety protocols, and multi-agent coordination instructions.
- **Fleet Orchestration**: Firstmate (`firstmate launch pi` or `FM_HARNESS=pi`) and `no-mistakes` natively drive Pi for multi-agent loops and verification.
- **Omarchy Default**: Selectable via `omarchy default agent pi`.

## 🎨 Themes Included

| Theme | Type | Source / Upstream |
|-------|------|-------------------|
| **🌌 Aetheria** *(Active)* | Custom | [JJDizz1L/aetheria](https://github.com/JJDizz1L/aetheria) |
| **Akaito** | Custom | [stannorbvb-cmd/akaito](https://github.com/stannorbvb-cmd/akaito) |
| **Amekoji** | Custom | [atif-1402/omarchy-amekoji-theme](https://github.com/atif-1402/omarchy-amekoji-theme) |
| **City 783** | Custom | [OldJobobo/omarchy-city-783-theme](https://github.com/OldJobobo/omarchy-city-783-theme) |
| **Synthetica** | Custom | [stannorbvb-cmd/synthetica](https://github.com/stannorbvb-cmd/synthetica) |
| **Sakura Mochi** | Custom | [OldJobobo/omarchy-sakura-mochi-theme](https://github.com/OldJobobo/omarchy-sakura-mochi-theme) |
| **Artzen** | Custom | [tahfizhabib/omarchy-artzen-theme](https://github.com/tahfizhabib/omarchy-artzen-theme) |
| **Harbor** | Custom | [HANCORE-linux/omarchy-harbor-theme](https://github.com/HANCORE-linux/omarchy-harbor-theme) |
| **Harbordark** | Custom | [HANCORE-linux/omarchy-harbordark-theme](https://github.com/HANCORE-linux/omarchy-harbordark-theme) |
| **Moodpeak** | Custom | [HANCORE-linux/omarchy-moodpeak-theme](https://github.com/HANCORE-linux/omarchy-moodpeak-theme) |
| **Quattrocento Light**| Custom | [r-bart/omarchy-quattrocento-light-theme](https://github.com/r-bart/omarchy-quattrocento-light-theme) |

---

## 🧩 Status Bar Plugins Included

| Plugin ID | Description |
|-----------|-------------|
| `soham.power` | Custom battery limiter & power panel developed by Soham |
| `charlieras262.floating-bar` | Floating top status bar container |
| `chispes.agent-gemini` | Coding agent launcher integration (enhanced) |
| `io.github.calebhat.themebook`| Theme catalog and fast switcher (enhanced) |
| `io.github.diegopluna.argus` | System hardware monitoring widget |
| `io.github.elevate08.qs-bitwarden-cli` | Bitwarden status & fingerprint unlock |
| `io.github.nilszeilon.omarchy-sensei` | Interactive keybinding coaching & learning widget |
| `io.github.r-witz.nothing-ear` | Nothing Ear wireless audio device controls |
| `io.github.ricky.whatsapp` | WhatsApp messaging indicator & background daemon |
| `jkoestinger.vpn` | Proton/Wireguard VPN status indicator |
| `krall.switchboard` | Quick settings and controls menu |
| `mryll.meteobar` | Real-time weather indicator |
| `omaconnect` | KDE Connect device sync |
| `omamail` | Email notifications widget |
| `jrmmhm.pocket` | Collapsible widget drawer for grouping tray items |
| `io.github.adamcbrewer.voxtype-aura` | Voice dictation (Voxtype) OSD audio indicator |
| `io.github.weedwhitesandwine.obsiduous` | Obsidian notes & vault quick-capture indicator |
| `x692137x.powerwave` | PowerWave audio visualizer & pulse indicator |
| `reomarchy.workspace-switcher` | Visual card workspace switcher with animations & digit jump |
| `mahmoodkhalil57.qrgen` | Interactive QR Code generator & bar widget with active theme adaptation |

---

## 🚀 Quick Restoration

### Automated One-Step Restore
```bash
git clone https://github.com/sohamSanat/omarchy-backup.git
cd omarchy-backup
./restore.sh
```

> 📖 **For AI Agents & Detailed Step-by-Step Restoration:**
> Read **[`AI_AGENT_RESTORE_GUIDE.md`](AI_AGENT_RESTORE_GUIDE.md)** for exhaustive details, package dependencies, and troubleshooting.
