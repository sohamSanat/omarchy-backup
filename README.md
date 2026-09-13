# Omarchy Full Ecosystem Backup

Comprehensive backup and automated restoration repository for **Soham Sanat's Omarchy Linux Workstation** running Arch Linux, Hyprland Wayland compositor, Quickshell (`omarchy-shell`), and the frontier **Omagent** personal AI assistant ecosystem.

Target Repository: `git@github.com:sohamSanat/omarchy-backup.git`  
Branch: `main`

---

## 🌟 Key Ecosystem Components

### 1. 🤖 Omagent Personal AI Assistant & Autonomous Fleet
- **Quickshell HUD (`Alt + Space`, `Super + A`)**: Native blurred glass assistant interface built on Quickshell (`io.github.ellion369.omagent`).
- **Voice Intercom (`Super + V`)**: Push-to-talk microphone integration via Voxtype.
- **3-Lane High-Performance Router (`omagent-route`)**:
  - **Lane 1 (General Knowledge)**: Direct streaming SSE synthesis via Google Gemini 3.8 Flash.
  - **Lane 2 (Web & Research)**: DuckDuckGo live internet retrieval + grounded Gemini synthesis.
  - **Lane 3 (Autonomous Coding Harness)**: Automatically provisions isolated Herdr workspaces, generates isolated Treehouse git worktrees, selects Compound Engineering skills (`ce-work`, `ce-debug`, `ce-optimize`), invokes Google Antigravity (`agy`), and performs dual-agent code reviews.
- **Quota-Aware Failover Harness Pool (`harness_pool.py` & `model_pool.json`)**:
  - Probes Antigravity's 5h session and weekly windows via `quota-axi`.
  - Transparently fails over to the top-ranked free model in `model_pool.json` (e.g. `opencode/big-pickle` gateway) upon reaching 95% quota, and returns automatically once the window resets.
  - Features real one-shot probe verification, pool auto-pruning, and a runtime pane watchdog that sends resume signals on rate limits or triggers mid-run model switches.
- **Mandatory Anti-One-Shot 5-Phase Lifecycle & Visual QA**:
  - Requires implementation, visual verification (`omagent-screenshot <target> preview.png`), sibling peer review in Herdr, UI butter optimization (`ce-ui-optimize`), and clean delivery.
- **Uncapped Multi-Agent Fleet Orchestration (`firstmate-subagent`)**:
  - Directs parallel specialist crewmates across 2x2 Herdr tiling panes (`firstmate subagent spawn/prompt/list/close`) bound to Compound Engineering skill workflows.
  - Grants every subagent on-demand autonomy to invoke any of the 33 Compound Engineering skills (`firstmate skills`, `firstmate skill-read`).
- **Supreme Prompt Primacy Law & Anti-Hijacking Protection**:
  - Eliminates "Reference Image Hijacking": the user's master prompt defines 100% of product domain, entity name, hero copy, navigation items, and features.
  - Reference images act strictly as aesthetic style donors (chromatic chords, lighting, squircle radii, frosted glass, typography tension). Literal cloning of depicted companies or industries is strictly forbidden.
- **Dynamic LLM & Algorithmic Grill-Me Strategic Alignment Protocol (`omagent-route`)**:
  - Contextual 6-question design alignment before code generation: Clarifies reference essence, kinetic physics, header layout laws, atmospheric depth, typography, and contrast rhythms.
  - Features dynamic LLM question generation (`call_llm_dynamic_grill_questions`) with deterministic algorithmic fallback, plus interactive QML cards with inline selection and one-click `proceed` support.
- **Bifurcated UI Routing & Visual Reference Image Deconstruction**:
  - **Track A (Reference Image Provided)**: Automatically locks to **Set 4 (Impeccable)**, completely bypassing archetype choices to prevent style collision; runs geometric and chromatic deconstruction and persists analysis to `solutions/reference_design_language.md` with prompt-primacy headers.
  - **Track B (No Reference Image)**: Interactive UI Archetype Menu (Sets 1, 2, or 3).
- **4 Exclusive UI Design Skill Sets (80 Total Skills in `agents/skills/`)**:
  - **Set 1: Full Aesthetic** (Linear, Stripe Press, Braun minimalism, Swiss typography, Emil Kowalski spring animations).
  - **Set 2: SaaS / Product App** (High-density tables, sticky headers, state machines, WCAG AA contrast).
  - **Set 3: Jaw-Dropping / 3D Showcase** (Three.js WebGL worlds, GLSL shaders, Lenis virtual smooth scroll, GSAP choreography, anti-slop review).
  - **Set 4: Impeccable Visual Reference Alignment** (`impeccable`: non-invasive reference fidelity, honors pinned aesthetics, zero archetype collision, out-of-distribution craft).
  - **Supreme Precedence & Header Laws**: Rigid single-line navigation (`white-space: nowrap !important;`), centered vertical baselines, and mandatory post-UI animation pass.
- **Voice Intercom & Voxtype IPC Hook (`omarchy-voxtype-hook`)**:
  - Intercepts voice transcription; directly injects speech into active Omagent HUD via Quickshell IPC, eliminating keystroke racing.
- **Nothing Phone PWA & Voice Bridge (`omagent-mobile-bridge`)**:
  - Python aiohttp HTTPS + WSS daemon listening on port `7890` serving `~/.config/omagent/mobile-web`.
  - Bidirectional mobile audio streaming, Whisper/Voxtype transcription, and Lavish review surfaces.
- **Proactive Crash Watcher (`omagent-crash-watch`)**:
  - Background systemd user service monitoring `systemd-coredump` journal logs.
  - Immediately dispatches interactive notifications with 1-click automated debugging via `diagnose-crash` and `ce-debug`.

### 2. ⚡ Autonomous AI Coding & Agent Fleet
- **Agent Runtimes**: Google Antigravity CLI (`agy`), Antigravity IDE, Cursor IDE, Pi Harness, Hermes Agent (`hermes`), and Cursor Agent (`cursor-agent`).
- **Firstmate & Herdr**: Agent fleet multiplexing with multi-pane isolation and socket control.
- **Treehouse**: Reusable, isolated git worktree pooling.
- **Compound Engineering Skills (`~/.agents/skills`)**: 33 specialized methodologies (`ce-work`, `ce-ui-optimize`, `ce-debug`, `ce-optimize`, `ce-plan`, `ce-ideate`, `ce-pov`, `ce-code-review`, `ce-compound`, `lfg`, `diagnose-crash`, `omarchy`, etc.).
- **AXI Ergonomic Tooling**: `gh-axi`, `quota-axi`, `tasks-axi`, `lavish-axi`, `no-mistakes`.
- **System Rules**: `omagent.md`, `ui-sets.md`, `ui-ux-architecture.md`, `axi.md`, `theming.md`.
- **Repo Learnings**: Preserved in `~/.agents/learnings/` (`ui_ux_agentic_architecture.md`, `omarchy_theming.md`, `cli_threshold_falsiness_and_bash_subshells.md`, `argparse_percent_escaping_and_sysfs_negative_current.md`).

### 3. 🎨 Visual Experience, Bar & Theming Pipeline
- **Theme Collection**: 16 curated themes (`moodpeak` [Active], `nous` [Light research], `sakura-mochi`, `aetheria`, `akaito`, `amekoji`, `artzen`, `city-783`, `harbor`, `harbordark`, `omagen1`, `omarchy_signature`, `quattrocento-light`, `synthetica`).
- **Floating Bar**: 27 modular plugins in `plugins/` (`io.github.ellion369.omagent`, `reomarchy.workspace-switcher`, `ricardosuman.pretty-screenshot`, `tristonarmstrong.dictionary`, `bhanu.omavideos`, `soham.power`, `mryll.printbar`, `mahmoodkhalil57.qrgen`, `io.github.ricky.whatsapp`, etc.).
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
- **`agy`**: Antigravity CLI Autonomous Folder-Trust Wrapper (`bin/agy`) that pre-registers workspaces and ensures `always-proceed` permissions in `~/.gemini/antigravity-cli/settings.json` to prevent interactive permission prompts during autonomous coding runs.
- **`firstmate-subagent`**: Multi-agent fleet conductor managing parallel crewmates across Herdr panes (`spawn`, `prompt`, `list`, `skills`, `close`) with automatic workspace trust provisioning.
- **`omagent-screenshot`**: Headless browser screenshot tool (`--mobile`, `--tablet`) for automated visual layout validation.
- **`omarchy-video-idle-inhibit`**: Daemon preventing idle/screensaver lock during media playback and whenever an active Herdr agent swarm workspace is in focus, with screensaver lock-guard.
- **`omarchy-pretty-screenshot` (`Print`)**: Beautiful window/desktop screenshot tool with wallpaper and gradient frames (`plugins/ricardosuman.pretty-screenshot`).
- **`voxtype-dictate-toggle` (`Super + H`, `Ctrl + H`)**: Toggle microphone recording and transcription for Voxtype.
- **`cmf-buds-mode`**: CLI utility controlling Active Noise Cancellation modes for Nothing CMF Buds.
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
