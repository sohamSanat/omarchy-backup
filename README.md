# Omarchy Full Ecosystem Backup

Comprehensive backup and automated restoration repository for **Soham Sanat's Omarchy Linux Workstation** running Arch Linux, Hyprland Wayland compositor, Quickshell (`omarchy-shell`), and the frontier **Omagent** personal AI assistant ecosystem.

Target Repository: `git@github.com:sohamSanat/omarchy-backup.git`  
Branch: `main`

---

## 🌟 Key Ecosystem Components

### 1. 🤖 Omagent Personal AI Assistant
- **Quickshell HUD (`Alt + Space`)**: Native blurred glass assistant interface built on Quickshell (`io.github.ellion369.omagent`).
- **Voice Intercom (`Super + V`)**: Push-to-talk microphone integration via Voxtype.
- **3-Lane High-Performance Router (`omagent-route`)**:
  - **Lane 1 (General Knowledge)**: Direct streaming SSE synthesis via Google Gemini 3.8 Flash.
  - **Lane 2 (Web & Research)**: DuckDuckGo live internet retrieval + grounded Gemini synthesis.
  - **Lane 3 (Autonomous Coding)**: Automatically provisions isolated Herdr workspaces, generates isolated Treehouse git worktrees, selects Compound Engineering skills (`ce-work`, `ce-debug`, `ce-optimize`), invokes Google Antigravity (`agy`) or Pi Harness, and performs dual-agent code reviews.
- **Nothing Phone PWA & Voice Bridge (`omagent-mobile-bridge`)**:
  - Python aiohttp HTTPS + WSS daemon listening on port `7890` serving `~/.config/omagent/mobile-web`.
  - Bidirectional mobile audio streaming, Whisper/Voxtype transcription, and Lavish review surfaces.
- **Proactive Crash Watcher (`omagent-crash-watch`)**:
  - Background systemd user service monitoring `systemd-coredump` journal logs.
  - Immediately dispatches interactive notifications with 1-click automated debugging via `diagnose-crash` and `ce-debug`.

### 2. ⚡ Autonomous AI Coding & Agent Fleet
- **Agent Runtimes**: Google Antigravity CLI (`agy`), Antigravity IDE, Cursor IDE, and Pi Harness.
- **Firstmate & Herdr**: Agent fleet multiplexing with multi-pane isolation and socket control.
- **Treehouse**: Reusable, isolated git worktree pooling.
- **Compound Engineering Skills (`~/.agents/skills`)**: `ce-work`, `ce-debug`, `ce-optimize`, `ce-plan`, `ce-ideate`, `ce-pov`, `ce-code-review`, `ce-compound`, `lfg`, `diagnose-crash`, `omarchy`.
- **AXI Ergonomic Tooling**: `gh-axi`, `quota-axi`, `tasks-axi`, `lavish-axi`, `no-mistakes`.
- **Repo Learnings**: Preserved in `~/.agents/learnings/` (`omarchy_theming.md`, `cli_threshold_falsiness_and_bash_subshells.md`).

### 3. 🎨 Visual Experience, Bar & Theming Pipeline
- **Theme Collection**: 16 curated themes (`moodpeak` [Active], `nous` [Light research], `sakura-mochi`, `aetheria`, `akaito`, `amekoji`, `artzen`, `city-783`, `harbor`, `harbordark`, `omagen1`, `omarchy_signature`, `quattrocento-light`, `synthetica`).
- **Floating Bar**: 26 modular plugins in `plugins/` (`io.github.ellion369.omagent`, `reomarchy.workspace-switcher`, `tristonarmstrong.dictionary`, `bhanu.omavideos`, `soham.power`, `mryll.printbar`, `mahmoodkhalil57.qrgen`, `io.github.ricky.whatsapp`, etc.).
- **Visual Workspace Switcher v2**: Hold-Super HUD with screencopy previews, active window titles, corner marks, bottom keymap HUD (`← →`, `↑ ↓`, `1-9`, `↵`, `esc`), and live search filter.
- **Dynamic Theming Engine**: `omarchy theme set` instantly propagates colors across KDE/Qt (`kdeglobals`), GTK 4, terminal emulators (Ghostty, Alacritty, Kitty, Foot), Zen Browser (userChrome, Dark Reader), Brave Origin Browser, VLC Media Player, Obsidian, Foliate, and ytkew.
- **Universal Theming Library & Environment**: `omarchy_theme.py` (high-contrast palette math ensuring dark text on light themes) and `omarchy-theme-env` CLI for terminal environment variable sync (`OMARCHY_THEME_MODE`, `COLORFGBG`).

### 4. 🌐 Brave Origin Browser Theming Ecosystem
- **Transparent NTP Canvas (`~/.config/omarchy/brave-polish/`)**: Unpacked MV3 companion extension that renders the active theme's colors and wallpapers onto a transparent canvas directly over Hyprland.
- **Theme Templates (`configs/omarchy/themed/`)**: `brave-ntp.css.tpl`, `brave-polish.css.tpl`, `brave-polish.json.tpl`, `brave-manifest.json.tpl`, `brave-global.css.tpl`.
- **Brave Dark Reader Fork (`configs/omarchy/brave-darkreader/`)**: Full Chromium MV3 port of Zen's Dark Reader mod featuring ITU-R BT.601 perceptual luminance checking and dual-mode color mathematics.
- **Managed Policy (`/etc/brave/policies/managed/omarchy-ntp.json`)**: Locks Brave's New Tab Page URL to the Omarchy NTP extension canvas.
- **CLI & Automated Hook**: `omarchy-sync-brave` (`--sync`, `--status`) invoked automatically on every theme change via `~/.config/omarchy/hooks/theme-set.d/brave-sync.sh`.
- **Chromium Wayland Flags (`configs/chromium-flags.conf`)**: Ozone Wayland flags, password store integration, and smooth touchpad history navigation.

### 5. 🛠️ Utilities & System Services
- **`omarchy-dictionary-lookup` (`Super + D`)**: Fast dictionary popup for active text selections with automatic clipboard and primary selection extraction.
- **`omarchy-sync-vlc`**: Dynamically writes 4-stop slider gradient and dark/light palette into `~/.config/vlc/vlcrc`.
- **Fastfetch Enhancements**: `fastfetch-arch-anim` (smooth spinning Arch ASCII animation) and `fastfetch-theme-accent` (theme accent mapper).
- **`fetch`**: Ultra-fast C/ASCII 3D donut spinning system info fetcher with Omarchy profile.
- **Wayland Idle Inhibitors**: `omarchy-wayland-inhibit` (compiled C Wayland protocol client) and `omarchy-video-idle-inhibit` (MPRIS and PipeWire audio stream daemon with screensaver lock-guard).
- **Screensaver Launcher**: `omarchy-launch-screensaver` with intelligent audio and stay-awake inhibition.
- **Systemd User Units**: Daemons for Omagent mobile bridge, crash monitor, video inhibitor, WhatsApp bridge, and cleanup timers.

---

## 🚀 Restoration Instructions

### Automated One-Shot Restore
On any fresh or existing Omarchy installation:

```bash
git clone https://github.com/sohamSanat/omarchy-backup.git
cd omarchy-backup
./restore.sh
```

### Post-Restore Setup: Omagent API Key
For security, credentials are not stored in this repository. After running `restore.sh`, edit `~/.config/omagent/config.json`:

```json
{
  "gemini_api_key": "YOUR_ACTUAL_GEMINI_API_KEY",
  "fast_model": "gemini-3.8-flash",
  "web_model": "gemini-3.8-flash",
  "coding_harness": "antigravity",
  "coding_model": "gemini-3.8-flash-high",
  "thinking_level": "high",
  "use_herdr": true,
  "use_treehouse": true
}
```

Self-signed TLS certificates for the Nothing Phone PWA bridge (`~/.config/omagent/ssl/cert.pem` and `key.pem`) are automatically generated by `restore.sh`.

---

## 📂 Repository Directory Layout

```
omarchy-backup/
├── agents/                  # AI agent skills, rules, and durable learnings (~/.agents)
├── bin/                     # Custom binaries and helper executables (~/.local/bin)
├── configs/                 # Dotfiles and application configs (~/.config)
│   ├── omagent/             # Omagent prompt, mobile PWA web client, and config template
│   ├── fetch/               # Fetch configuration and Omarchy ASCII branding
│   ├── hypr/                # Hyprland rules, inputs, look-and-feel, and keybindings
│   ├── omarchy/             # Omarchy shell.json, theme templates, and homelab-launcher
│   ├── terminals/           # Alacritty, Ghostty, Kitty, Foot configs
│   ├── zen/                 # Zen Browser userChrome, Dark Reader mod, user.js
│   └── ...                  # Foliate, ytkew, QDirStat, FDM, Ristretto, Strata
├── desktop-entries/         # Custom XDG desktop application shortcuts
├── lib/                     # Compiled C plugins (hypr-shiny-border.so) and libraries
├── meta/                    # Package lists, theme/plugin sources, and git diff patches
├── pixmaps/                 # Application icons and assets
├── plugins/                 # 24 full Omarchy shell plugins (~/.config/omarchy/plugins)
├── systemd/                 # User systemd service units (~/.config/systemd/user)
├── themes/                  # 16 complete themes (~/.config/omarchy/themes)
├── AI_AGENT_RESTORE_GUIDE.md# Comprehensive architectural and recovery guide for agents
├── restore.sh               # Idempotent system restore script
└── README.md                # System documentation
```

---

## 🛡️ Defensive Backup Guarantees
- **Credential Protection**: Real Gemini API keys and private SSL keys (`*.pem`, `*.key`) are strictly ignored via `.gitignore` and sanitized in configs.
- **Safety Boundary**: `/usr/share/omarchy/` is never modified directly.
- **Idempotency**: Existing configuration files are timestamped and preserved before being overwritten by `restore.sh`.
