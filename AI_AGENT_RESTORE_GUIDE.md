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
16 themes with all assets and wallpapers included:
- `moodpeak` (**Active theme**)
- `sakura-mochi`, `aetheria`, `akaito`, `amekoji`, `artzen`, `city-783`, `harbor`, `harbordark`, `nous` (light-mode research theme), `omagen1`, `omarchy_signature`, `quattrocento-light`, `synthetica`.

### E. Shell Plugins (`plugins/` -> `~/.config/omarchy/plugins/`)
24 plugins included with complete source code:
- **`io.github.ellion369.omagent`**: Personal AI Assistant with 3-lane multi-intent router (Flash chat, Web search, Herdr coding execution), Nothing Phone PWA intercom bridge, and Quickshell glass HUD overlay.
- **`reomarchy.workspace-switcher`**: Visual workspace switcher with hold-Super activation, live screencopy previews, active window titles, corner marks, bottom navigation HUD (`← →`, `↑ ↓`, `1-9`, `↵`, `esc`), and type-to-filter search (includes custom patch).
- **`kenny.nightlight`**: Night light color temperature bar control widget.
- **`mryll.printbar`**: Printer hardware status and G2060 maintenance panel (includes custom patch).
- **`soham.agents`**: Bespoke user-forked Omarchy agents selector.
- **`mahmoodkhalil57.qrgen`**: QR generator bar widget with dynamic theme foreground/background adaptation (includes custom patch).
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
- **`pretty.omagen`**: Dynamic palette generation bar plugin.

### F. Custom Binaries & Helper Scripts (`bin/` -> `~/.local/bin/`)
- `omaagent` & `omagent`: Launch and toggle Omagent Quickshell assistant overlay.
- `omagent-crash-watch`: Proactive systemd-coredump monitor; triggers automated debugging via `diagnose-crash` and `ce-debug` in Herdr.
- `omagent-voice`: Push-to-talk voice intercom triggering Voxtype dictation into Omagent HUD (`Super+V`).
- `omagent-mobile-bridge`: Async HTTP + WebSocket daemon (port 7890) serving Nothing Phone PWA with end-to-end voice streaming and Lavish artifact integration.
- `fetch`: Ultra-fast C/ASCII 3D spinning donut system fetcher configured for Omarchy.
- `omarchy-wayland-inhibit`: Compiled C Wayland protocol idle-inhibitor client.
- `omarchy-video-idle-inhibit`: Daemon monitoring MPRIS and PipeWire audio streams to prevent screensaver interruption during media playback.
- `omarchy-launch-screensaver`: Intelligent screensaver launcher respecting media and user stay-awake flags.
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


9. **Pi Harness Integration**:
   - `configs/pi/agent/AGENTS.md` -> `~/.pi/agent/AGENTS.md` (AXI, Omarchy, and multi-agent rules).
   - `~/.pi/agent/skills/` links to all skills in `~/.agents/skills/`.
   - `firstmate launch pi` or setting default via `omarchy default agent pi`.


10. **Desktop Tools, Flatpaks & Lavish**:
   - `bin/cleaning`: Laptop keyboard/trackpad lock script for cleaning.
   - `bin/discord` and `desktop-entries/`: Desktop app launchers.
   - Flatpaks: `com.stremio.Stremio` tracked in `meta/flatpak-packages.txt`.
   - `lavish-axi` repository tracked in `meta/external-repos.json`, with skills `lavish` and `lavish-design` in `agents/skills/`.


11. **Zen Browser Customization & Theming Engine**:
   - `configs/zen/chrome/` contains `userChrome.css`, `userContent.css`, `zen-themes.css`, and modular mods (`omarchy-theme`, `omarchy-zen-glass`, `omarchy-darkreader`).
   - `configs/zen/MODS.md`: Full architectural specification of the 4-layer glass architecture (Hyprland blur/opacity -> Gecko transparency -> Chrome window canvas -> Solid tab content).
   - `configs/zen/extensions/`: Packaged XPIs for Dark Reader, Free Download Manager, SponsorBlock, Return YouTube Dislike, and uBlock Origin.
   - `bin/omarchy-sync-zen` compiles active theme palette into `zen-themes.css` and dynamic variables.
   - `restore.sh` distributes stylesheets and extensions to all Zen profiles and runs the sync engine.

12. **Printer Suite**:
   - `bin/printer` & `bin/printbar` provide complete hardware monitoring for Canon PIXMA G2060.

13. **Omarchy Dark Reader Mod for Zen Browser**:
   - Source: `configs/zen/mods/darkreader/`
   - Prebuilt XPI: `configs/zen/extensions/addon@darkreader.org.xpi`
   - Perceptual luminance calculation (`OmarchyManager.isColorLight`) using ITU-R BT.601 formula to prevent dark backgrounds from being misclassified as light mode.
   - Dual-mode light/dark color math (`modifyOmarchyDarkSchemeColor`, `modifyOmarchyLightBgColor`, `modifyOmarchyLightFgColor`), converting light foregrounds to high-contrast dark tones (`#4d2e1a`) in light themes.
   - Dynamic stylesheet injection for major web platforms including comprehensive YouTube interface styling (`#page-manager`, `ytd-masthead`, searchbox, filters, video titles, channel names, player controls) and Reddit (Shreddit).
   - Templates: `configs/omarchy/themed/zen-darkreader*.tpl`
   - Synced via `omarchy-sync-zen --sync` and auto-hooked to theme switches.


14. **Cursor IDE, Antigravity IDE & Antigravity App**:
   - `configs/cursor/`: User settings, Herdr hooks, 24 cursor skills, and `omarchy-theme` extension.
   - `configs/antigravity-ide/`: IDE settings, extension list, and `omarchy-theme` extension.
   - `configs/antigravity-app/`: Desktop app state, Preferences, and `~/.gemini/config/` plugin/hook configurations.
   - `restore.sh` automatically links `omarchy-theme` to active `vscode-theme.json` so editors match Omarchy Linux themes.


15. **New Applications, Portals & Daemons**:
   - `configs/foliate/` & `bin/foliate`: Dynamic Foliate e-book reader.
   - `configs/qdirstat/` & `bin/qdirstat`: QDirStat disk analyzer.
   - `configs/xdg-desktop-portal/` & `configs/dbus-services/`: Strata as default file manager & Wayland file chooser portal.
   - `bin/omarchy-video-idle-inhibit` & `systemd/user/`: Video/media idle inhibitor daemon.
   - `configs/fdm/` & `lib/libomarchy-fdm-theme.so`: Free Download Manager theming and browser native messaging host.
   - `themes/omagen1` & `themes/omarchy_signature`: New themes.
   - `plugins/pretty.omagen`: Visual theme designer studio plugin.


16. **YouTube Music (ytkew) & Complete Theme Hooks Suite**:
   - `bin/ytkew` & `configs/ytkew/`: Terminal music player with dynamic cover art and spectrum bars.
   - `configs/omarchy/hooks/theme-set.d/`: Full hook suite synchronizing ytkew, Foliate, Discord, Zen, FDM, and editors on theme switch.
   - `configs/hypr/input.lua`: 3-finger touchpad swipe gestures for workspace switcher.

17. **Omagent Personal Assistant Ecosystem**:
   - **`plugins/io.github.ellion369.omagent`**: Quickshell glass overlay HUD invoked via `ALT + SPACE` or CLI `omaagent`/`omagent`.
   - **`omagent-route`**: High-performance multi-intent router:
     - **Lane 1 (General)**: Instant answers streamed via Google Gemini 3.8 Flash SSE (`streamGenerateContent`).
     - **Lane 2 (Web Research)**: Real-time web retrieval via DuckDuckGo and grounded synthesis with Gemini 3.8 Flash.
     - **Lane 3 (Autonomous Coding & Engineering)**: Automatically creates isolated Herdr workspaces, generates branch-isolated Treehouse worktrees, selects optimal Compound Engineering skills (`ce-work`, `ce-debug`, `ce-optimize`), executes via Google Antigravity CLI (`agy`) or Pi Harness, and performs dual-agent code review.
   - **Nothing Phone PWA & Voice Intercom (`omagent-mobile-bridge`)**:
     - Daemon running on port 7890 (HTTPS/WSS) serving `~/.config/omagent/mobile-web`.
     - Real-time bidirectional voice streaming from mobile to Linux host via WebSocket, transcribing with local Voxtype/Whisper and generating responses.
     - Mobile interface renders interactive Lavish feedback surfaces.
   - **`omagent-crash-watch`**:
     - Background systemd user service monitoring `systemd-coredump` journal logs.
     - On application crash, displays an interactive notification allowing 1-click automatic debugging and symbolization via `diagnose-crash` and `ce-debug`.
   - **Security & TLS**:
     - `~/.config/omagent/config.json` is configured with `"coding_harness": "antigravity"`, `"fast_model": "gemini-3.8-flash"`.
     - API keys are protected (`YOUR_GEMINI_API_KEY` placeholder in backup).
     - Local self-signed TLS certificates (`cert.pem`, `key.pem`) are generated in `~/.config/omagent/ssl/` automatically by `restore.sh`.
   - **Identity & Coding Instructions**:
     - `agent_identity.md`: Jarvis-like persona architecture, tri-lane tech stack, and tool specification.
     - `coding_agent_prompt.md`: Instructions for autonomous software engineering via Antigravity CLI (`agy`) and Pi Harness with Herdr workspaces.

18. **Brave Origin Browser Customization & Theming Suite**:
   - **Companion Unpacked MV3 Extension (`configs/omarchy/brave-polish/`)**:
     - Replaces default NTP with a transparent Omarchy canvas (`ntp.html`, `ntp.js`, `ntp.css`) displaying the active theme colors and wallpaper directly over Hyprland.
     - Injects site polish for major platforms (`loader.js`, `global.js`, `polish.css`, `global.css`) such as YouTube, GitHub, and Reddit with zero-restart hot-reloading.
   - **Brave Dark Reader Fork (`configs/omarchy/brave-darkreader/`)**:
     - Full Chromium MV3 port of the Zen Dark Reader mod.
     - Integrates ITU-R BT.601 perceptual luminance checking and dual-mode color mathematics (`modifyOmarchyDarkSchemeColor`, `modifyOmarchyLightBgColor`, `modifyOmarchyLightFgColor`) to prevent washed-out text on light themes.
   - **Theme Templates (`configs/omarchy/themed/`)**:
     - `brave-ntp.css.tpl`, `brave-polish.css.tpl`, `brave-polish.json.tpl`, `brave-manifest.json.tpl`, `brave-global.css.tpl`.
   - **Synchronization Engine & Hooks**:
     - `bin/omarchy-sync-brave`: CLI tool supporting `--sync` and `--status`.
     - `configs/omarchy/hooks/theme-set.d/brave-sync.sh`: Hot-applies theme tokens to Brave on every `omarchy theme set`.
   - **Managed NTP Policy & Flags**:
     - `configs/brave/policies/managed/omarchy-ntp.json`: Sets `NewTabPageLocation` to the extension's `ntp.html`.
     - `configs/chromium-flags.conf`: Sets Wayland ozone flags and default system extensions.

19. **Dictionary Lookup & OmaVideos Plugins**:
   - **`plugins/tristonarmstrong.dictionary`**:
     - Floating bar dictionary widget with pronunciation, part-of-speech tabs, audio playback, word search, and history.
     - Includes `bin/omarchy-dictionary-lookup`, bound globally to `SUPER + D` in `configs/hypr/bindings.lua` to look up selected text instantly.
     - Supercharged with Gemini AI spelling suggestions: automatically discovers API key from `GEMINI_API_KEY` or `~/.config/omagent/config.json`, suggests the 5 closest real dictionary words for misspellings, features the top closest match card with one-click lookup, and falls back to Damerau-Levenshtein local fuzzy matching if offline.
   - **`plugins/bhanu.omavideos`**:
     - Video and media management plugin for the floating bar.
   - **`plugins/charlieras262.floating-bar`**:
     - Fixed background opacity logic (`0.0` when transparent, `1.0` when opaque) and disabled accidental double-click transparency toggling.

20. **VLC Dynamic Theming & Terminal Art**:
   - **`bin/omarchy-sync-vlc` & `configs/omarchy/hooks/theme-set.d/vlc-sync.sh`**:
     - Derives a 4-stop slider gradient and dark/light palette mode from the active Omarchy theme and writes them directly into `~/.config/vlc/vlcrc`.
   - **`bin/fastfetch-arch-anim`**:
     - Smooth animated ASCII spinning Arch Linux banner for terminal sessions.
   - **`bin/fastfetch-theme-accent`**:
     - Dynamically maps the active theme's hex accent color to the nearest xterm-256 color for fastfetch and CLI banners.

21. **Universal Omarchy Theming Library & Environment**:
   - **`lib/omarchy_theme.py`**:
     - Python library installed into user site-packages providing `is_light()`, `is_dark()`, and `get_palette()`.
     - Enforces strict contrast rules for light themes (dark text `\033[38;5;235m`, never washed-out DIM or pale neon colors).
   - **`bin/omarchy-theme-env`**:
     - CLI tool exporting `OMARCHY_THEME_MODE` and `COLORFGBG` across all shell and terminal environments.

22. **Omagent Quota-Aware Failover Engine & Fleet Conductor**:
   - **`plugins/io.github.ellion369.omagent/harness_pool.py` & `model_pool.json`**:
     - Automatically checks Antigravity 5h and weekly quota usage with `quota-axi`.
     - Triggers transparent failover to the highest scoring model in `model_pool.json` (such as `opencode/big-pickle`) upon reaching 95% quota, and auto-returns when the window resets.
     - Live probe verification ensures models work before dispatch, accompanied by a runtime pane watchdog that issues resume nudges on rate limits or switches models mid-flight.
     - Test suite located in `tests/test_harness_pool.py`.
   - **`bin/firstmate-subagent`**:
     - Subagent fleet conductor allowing parallel crewmates to be spawned into clean 2x2 Herdr tiling grids (`firstmate subagent spawn/prompt/list/skills/close`).
   - **`bin/omagent-screenshot`**:
     - Headless browser/UI verification utility supporting `--mobile` (375px) and `--tablet` (1024px) for automated visual QA.
   - **`agents/rules/omagent.md` & `agents/rules/ui-sets.md`**:
     - Durable system rules governing Omagent's anti-one-shot 5-phase lifecycle, multi-agent fleet permissions, and UI sets precedence.

23. **The 3 UI Design Skill Sets & 79 Agent Skills (`agents/skills/`)**:
   - Complete standalone backup of all 32 UI and animation skills (5.8MB total):
     - **Set 1 (Full Aesthetic)**: `web-design-engineer`, `animate`, `apple-design`, `ask-sonner`, `review-animations`, `find-animation-opportunities`, `improve-animations`, `prototype-ui`, `pick-ui-library`, `animation-vocabulary`.
     - **Set 2 (SaaS / Product App)**: `ui-design`, `design-systems`, `interaction-design`, `form-design`, `loading-states`, `state-machine-ux`, `color-system`, `layout-grid`, `accessibility-audit`, `visual-critique`.
     - **Set 3 (Jaw-Dropping / 3D Showcase)**: `build-awwwards-quality-sites`, `build-threejs-scroll-worlds`, `cinematic-gsap-lenis-motion-system`, `threejs-landscape`, `gsap-animation`, `cobejs`, `dither-background`, `add-shader-cursor-trail`, `ambient-section-particles`, `no-ai-design-slop`, `audit-ai-design-slop`.
     - **UI Optimization**: `ce-ui-optimize` (60/120fps GPU transitions, organic easing, tactile press compression, safe-area insets).
   - All skills are restored to `~/.agents/skills/` and symlinked into `~/.pi/agent/skills/`.

24. **Pretty Screenshot Plugin & System Tools**:
   - **`plugins/ricardosuman.pretty-screenshot/` & `bin/omarchy-pretty-screenshot`**:
     - Beautiful wallpaper-framed screenshots bound to `Print` in `configs/hypr/bindings.lua`.
   - **`bin/cmf-buds-mode`**:
     - ANC mode switcher for Nothing CMF Buds.
   - **`bin/voxtype-dictate-toggle`**:
     - Dictation toggle script bound to `Super + H` and `Ctrl + H`.
   - **`bin/hermes` & `bin/cursor-agent`**:
     - Hermes agent and Cursor agent CLI wrappers via `mise`.
   - **`configs/goose/` & `configs/kilo/`**:
     - Configurations for Goose and Kilo agent runtimes.

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
omarchy theme set "Moodpeak"
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
| **Theme** | `omarchy theme current` | Prints `Moodpeak` |
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
