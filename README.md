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
- **`ui_concepts/v1` Architecture & Quality Engine (`omagent_core/quality/`)**:
  - **Structured Design Contracts & 3-Concept Selection**: Generates 3 structurally unique concept candidates differing across ≥3 independent axes (information architecture, composition, typography, interaction signature, motion policy, asset strategy).
  - **Adaptive Alignment Protocol**: Replaces rigid 6-question interviews with dynamic gap analysis. Asks only for unresolved high-impact contract fields; comprehensive briefs proceed directly to concept selection.
  - **Deterministic Multi-Viewport Visual QA (`omagent_core/visual_qa.py`)**: Local perceptual fingerprinting across desktop (1440x900), tablet (768x1024), and mobile (375x812). Detects near-duplicates and template convergence.
  - **Independent Visual Review Receipts (`omagent_core/quality/review.py`)**: Quality engine strictly gates completion on independent visual review receipts, preventing self-approval and allowing up to 2 deterministic same-run repair cycles.
  - **Execution Backend Containment**: Controller reserves all workspace, tab, pane, and agent identities upfront; Herdr and Firstmate act as pure execution backends; `omagent-screenshot` enforces `--workspace` confinement and `--allow-host` whitelisting.
  - **132 Automated Unit & Integration Tests**: Comprehensive network-free deterministic validation test suite (`python3 -m unittest discover -s tests -p 'test_*.py'`).
- **Supreme Prompt Primacy Law & Anti-Hijacking Protection**:
  - The user's prompt is 100% sacred truth defining domain, entity name, and features. Reference images donate strictly abstract aesthetic DNA, eliminating reference hijacking.
- **Legacy Compatibility Layer (`omagent_core/legacy_migration.py`)**:
  - Gracefully handles in-flight sessions and maintains backwards compatibility for legacy Sets 1–4 while routing all new requests through `ui_concepts/v1`.
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
- **Floating Bar**: 37 modular plugins in `plugins/` (`nav-guide` [enhanced Super+K context-aware shortcuts teacher], `io.github.ef-code.omarchy-flow` [low-latency Gemini voice dictation], `soham.easyeffects` [navbar IEM EQ switcher & bypass toggle], `soham.pocket-left` [tuck-away widget dock for left bar], `krall.switchboard` [Raycast intelligence launcher], `io.github.ellion369.omagent`, `io.github.i12bp8.fmhy-deck`, `akshit.island`, `io.github.enovara.teach-voxtype`, `tiertek.scratchpad-deck`, `nguyenn.clipboard` [custom attachment cleaner], `reidenxerx.tile-blueprints`, `reomarchy.workspace-switcher`, `ricardosuman.pretty-screenshot`, `tristonarmstrong.dictionary`, `bhanu.omavideos`, `soham.power`, `mryll.printbar`, `mahmoodkhalil57.qrgen`, `io.github.ricky.whatsapp`, etc.).
- **Switchboard Launcher v2 (`krall.switchboard`)**:
  - **Raycast-Like Intelligence Engine (`RaycastSearch.js`)**:
    - **Math Calculator**: Live expression evaluation (`=`), base conversions (`255 to hex`, `10 to bin`, `oct`), percentages (`15% of 80`), scientific functions (`sqrt`, `sin`, `log`, `pow`).
    - **Currency & FX Conversions**: 50+ fiat currencies and crypto with live cache support.
    - **Quick Links System (`configs/omarchy/quicklinks.json`)**: 14 customizable shortcuts (`fmhy`, `yt`, `g`, `gh`, `wiki`, `maps`, `r`, `ddg`, `npm`, `arch`, `aur`, `so`, `ai`).
    - **Timezone Converter**: City, country, and abbreviation lookup with live offset diffs and scheduling math.
    - **FMHY FreeMediaHeckYeah Search**: Built-in SQLite FTS5 search (`scripts/fmhy-search`, `scripts/fmhy-sync.py`), category portals, search recommendations, and 1-click launch to `io.github.i12bp8.fmhy-deck`.
    - **Fuzzy Application Search (`AppSearch.js`)**: Weighted scoring prioritizing prefix matches, acronyms (`gimp` -> GNU Image Manipulation Program), and keyword metadata.
    - **Precise Text Navigation**: Word token jumping (`prevTokenPos`, `nextTokenPos`) and inline cursor editing.
- **Visual Workspace Switcher v2**: Hold-Super HUD with screencopy previews, active window titles, corner marks, bottom keymap HUD (`← →`, `↑ ↓`, `1-9`, `↵`, `esc`), and live search filter.
- **Dynamic Theming Engine**: `omarchy theme set` instantly propagates colors across KDE/Qt (`kdeglobals`), GTK 4, terminal emulators (Ghostty, Alacritty, Kitty, Foot), Zen Browser (userChrome, Dark Reader), Brave Origin Browser, VLC Media Player, Obsidian, Foliate, and ytkew.
- **Universal Theming Library & Environment**: `omarchy_theme.py` (high-contrast palette math ensuring dark text on light themes) and `omarchy-theme-env` CLI for terminal environment variable sync (`OMARCHY_THEME_MODE`, `COLORFGBG`).

### 4. 🌐 Brave Origin Browser Theming Ecosystem
- **Transparent NTP Canvas (`~/.config/omarchy/brave-polish/`)**: Unpacked MV3 companion extension that renders the active theme's colors and wallpapers onto a transparent canvas directly over Hyprland.
- **Theme Templates (`configs/omarchy/themed/`)**: `brave-ntp.css.tpl`, `brave-polish.css.tpl`, `brave-polish.json.tpl`, `brave-manifest.json.tpl`, `brave-global.css.tpl`.
- **Brave Dark Reader Fork (`configs/omarchy/brave-darkreader/`)**: Full Chromium MV3 port of Zen's Dark Reader mod featuring ITU-R BT.601 perceptual luminance checking and dual-mode color mathematics.
- **Managed Policy (`/etc/brave/policies/managed/omarchy-ntp.json`)**: Locks Brave's New Tab Page URL to the Omarchy NTP extension canvas.
- **CLI & Automated Hook**: `omarchy-sync-brave` (`--sync`, `--status`) invoked automatically on every theme change via `~/.config/omarchy/hooks/theme-set.d/brave-sync.sh`.
- **Chromium & Brave Startup Flags**: `configs/chromium-flags.conf`, `configs/brave-origin-nightly-flags.conf` (pre-loads Brave Polish and essential system extensions), and `configs/environment.d/brave.conf`.

### 5. 🛠️ Utilities, Standalone Apps & System Services
- **Standalone GUI Applications (`apps/`)**:
  - `apps/photos-gallery`: Windows 11 Fluent Photo Gallery & Vault app with biometric/PIN unlock, image adjustments, and EXIF metadata view (Electron 43). Restored to `~/Projects/photos-gallery` with `p-gallery.desktop` and `bin/p-gallery`.
  - `apps/gallery`: Minimalist desktop photo viewer restored to `~/Projects/gallery` with `gallery.desktop` and `bin/gallery`.
- **Ghostty Smooth Cursor Shader**: Custom GLSL shader `configs/terminals/ghostty/shaders/cursor_glide.glsl` enabling cubic-eased cell-to-cell cursor gliding with SDF edge antialiasing.
- **Hyprland Screen Share Picker**: `configs/hyprland-preview-share-picker/config.yaml` applying active Omarchy theme tokens to the Wayland window and output picker.
- **XDG Clean User Dirs Layout**: `configs/user-dirs.dirs` directing projects to `~/Projects` and eliminating home folder clutter.
- **Pretty Screenshot Config**: `configs/omarchy/pretty-screenshot.json` (wallpaper frame, padding, drop shadows).
- **Mise Agentic CLI Runners**: `bin/crush`, `bin/grok`, and `bin/omp` for one-shot tool execution.
- **`agy`**: Antigravity CLI Autonomous Folder-Trust Wrapper (`bin/agy`) that pre-registers workspaces and ensures `always-proceed` permissions in `~/.gemini/antigravity-cli/settings.json` to prevent interactive permission prompts during autonomous coding runs.
- **`firstmate-subagent`**: Multi-agent fleet conductor managing parallel crewmates across Herdr panes (`spawn`, `prompt`, `list`, `skills`, `close`) with automatic workspace trust provisioning.
- **Lid Power & Sleep Handlers**: `omarchy-system-lid-close`, `omarchy-system-lid-open`, and `omarchy-system-wake` bound in `configs/hypr/bindings.lua` to guard against screensaver and DPMS race conditions during suspend/clamshell mode.
- **Bluetooth A2DP Auto-Connect**: `configs/wireplumber/wireplumber.conf.d/bluetooth-a2dp-autoconnect.conf` auto-switches connected Bluetooth headsets to the high-fidelity A2DP profile.
- **Kimchi AI Agent Harness**: `configs/kimchi/` backup containing model catalog (`models.json`), trusted directories, UI settings, and 20 curated themes.
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
- **Sunshine & Tablet Mode Streaming**: `bin/tablet-mode` and `configs/sunshine/` enabling zero-latency wireless streaming and virtual display scaling to Redmi Pad SE via `HEADLESS-1` (1200x2000 90° portrait or 2000x1200 landscape).
- **EasyEffects Audio Ecosystem & Navbar Switcher**: Full integration including `plugins/soham.easyeffects/` (with `purge-preset.sh`, stock baseline protection, mouse-wheel scrolling, and modal confirmation), all 6 curated IEM Equalizer presets in `configs/easyeffects/output/` (Diablo, Daybreak, Nightfall, Maestro Mini, Nightingale, Tangzu Wan'er Stock), hardware routing autoload rules in `configs/easyeffects/autoload/output/`, database configurations in `configs/easyeffects/db/`, autostart entry `configs/autostart/easyeffects.desktop`, and systemd service `configs/systemd/user/easyeffects.service`.
- **Omarchy Flow Voice Dictation**: `plugins/io.github.ef-code.omarchy-flow` and `bin/flowctl` providing ultra-low-latency Gemini 3.5 transcribe & fallback with character injection guards.
- **Antigravity Interactive Question Ting**: `configs/antigravity-app/gemini-config/hooks/ring-ting.sh` and `sounds/ting.wav` ringing an audio chime and terminal bell whenever interactive choices (`ask_question`) await user input.
- **Agy Command Watcher**: `bin/agy-ting-watcher` tailing logs to emit audio chimes upon background command completion.
- **Wayscrollshot & IPv4 Library**: `bin/wayscrollshot` paired with `lib/force_ipv4.so` (`lib/force_ipv4.c`) for reliable full-page scrolling Wayland screenshots over IPv4 networks.
- **Screensaver Launcher**: `omarchy-launch-screensaver` with intelligent audio and stay-awake inhibition.
- **Systemd User Units**: Daemons for EasyEffects, Omagent mobile bridge, crash monitor, video inhibitor, WhatsApp bridge, and cleanup timers.

---

## 🚀 Restoration Instructions

### Automated One-Shot Restore
On any fresh or existing Omarchy installation:

```bash
git clone https://github.com/sohamSanat/omarchy-backup.git
cd omarchy-backup

# Restore all dotfiles, plugins, themes, and standalone apps:
./restore.sh

# Or, on a fresh machine, also reinstall all official pacman, AUR, and npm packages on the fly:
./restore.sh --install-apps
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
├── apps/                    # Standalone GUI applications (Photos Gallery, Gallery) (~/Projects)
├── bin/                     # Custom binaries and helper executables (~/.local/bin)
├── configs/                 # Dotfiles and application configs (~/.config)
│   ├── omagent/             # Omagent prompt, mobile PWA web client, and config template
│   ├── fetch/               # Fetch configuration and Omarchy ASCII branding
│   ├── hypr/                # Hyprland rules, inputs, look-and-feel, and keybindings
│   ├── kimchi/              # Kimchi agent harness, model routing, and themes
│   ├── omarchy/             # Omarchy shell.json, theme templates, and homelab-launcher
│   ├── terminals/           # Alacritty, Ghostty, Kitty, Foot configs
│   ├── wireplumber/         # PipeWire/WirePlumber audio configs and Bluetooth profile rules
│   ├── zen/                 # Zen Browser userChrome, Dark Reader mod, user.js
│   └── ...                  # Foliate, ytkew, QDirStat, FDM, Ristretto, Strata
├── desktop-entries/         # Custom XDG desktop application shortcuts
├── lib/                     # Compiled C plugins (hypr-shiny-border.so) and libraries
├── meta/                    # Package lists, theme/plugin sources, and git diff patches
├── pixmaps/                 # Application icons and assets
├── plugins/                 # 33 full Omarchy shell plugins (~/.config/omarchy/plugins)
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
