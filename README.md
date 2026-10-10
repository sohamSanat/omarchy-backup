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
  - **Adaptive Execution Policy (`omagent_core/execution_policy.py`)**: Sizing tier dynamically matches task scope:
    - `needle`: Single-agent, single-provider path (budget: 8 tool calls, 10 min) for narrow local fixes without subagent overhead.
    - `standard`: Focused implementation path (budget: 24 tool calls, 45 min) with targeted verification.
    - `sword`: Full multi-agent swarm & verification path (budget: 64 tool calls, 4 agents, 90 min) for architecture, security, migrations, and release-scale work.
    - UI tasks always receive at least the `standard` rendered-design policy.
  - **Structured Design Contracts & 3-Concept Selection**: Generates 3 structurally unique concept candidates differing across ≥3 independent axes (information architecture, composition, typography, interaction signature, motion policy, asset strategy).
  - **Adaptive Alignment Protocol**: Replaces rigid 6-question interviews with dynamic gap analysis. Asks only for unresolved high-impact contract fields; comprehensive briefs proceed directly to concept selection.
  - **Deterministic Multi-Viewport Visual QA (`omagent_core/visual_qa.py`)**: Local perceptual fingerprinting across desktop (1440x900), tablet (768x1024), and mobile (375x812). Detects near-duplicates and template convergence.
  - **Independent Visual Review Receipts & Bounded Repairs (`omagent_core/quality/`)**: Quality engine strictly gates completion on independent visual review receipts, preventing self-approval and orchestrating up to 2 bounded same-run repair passes.
  - **Execution Backend Containment**: Controller reserves all workspace, tab, pane, and agent identities upfront; Herdr and Firstmate act as pure execution backends; `omagent-screenshot` enforces `--workspace` confinement and `--allow-host` whitelisting.
  - **137 Automated Unit & Integration Tests**: Comprehensive network-free deterministic validation test suite (`python3 -m unittest discover -s tests -p 'test_*.py'`).
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

### 4. 🌐 Zen Browser Dynamic Customization Ecosystem (Primary Workstation Browser)

Zen Browser is Soham's primary daily-driver workstation browser on Omarchy Linux. It is deeply connected to Omarchy's system-level theming pipeline, native Wayland transparency, and Hyprland compositor blur effects.

#### 🧩 Core Architecture & Profile Management
- **Symlinked Profile Configuration (`~/.zen -> ~/.config/zen`)**: Managed profiles (`agmdnjeb.Default (release)`), `profiles.ini`, `installs.ini`, and `Profile Groups` backed up in [`configs/zen/`](file:///home/soham/omarchy-backup/configs/zen).
- **Native Wayland Transparency Engine**: Custom `user.js` preferences enforce hardware transparency without canvas glitches:
  - `zen.widget.linux.transparency: true` & `browser.tabs.allow_transparent_browser: true`
  - `toolkit.legacyUserProfileCustomizations.stylesheets: true`
  - `zen.themes.disable-all: false` & dynamic accent synchronization.
- **Launcher Integration**: Symlinked executable `~/.local/bin/zen -> ~/.local/share/zen/zen` with desktop registration (`zen.desktop`).

#### 🎨 Live Theming & Frosted Glass Mods
1. **Omarchy Dynamic System Theme (`omarchy-sync-zen`)**:
   - Compiles template [`configs/omarchy/themed/zen.css.tpl`](file:///home/soham/omarchy-backup/configs/omarchy/themed/zen.css.tpl) into `~/.local/state/omarchy/current/theme/zen.css` using high-contrast perceptual palette synthesis.
   - Symlinked into `<profile>/chrome/zen-omarchy-theme.css` and imported by `userChrome.css`.
   - Propagates semantic tokens (`--omarchy-bg`, `--omarchy-fg`, `--omarchy-accent`, `--omarchy-surface`, `--omarchy-border`, `--omarchy-border-subtle`) across the vertical tab bar, URL bar, dialogs, and toolbar in real time.
   - Automatically dispatched on every theme switch by [`configs/omarchy/hooks/theme-set.d/zen-sync.sh`](file:///home/soham/omarchy-backup/configs/omarchy/hooks/theme-set.d/zen-sync.sh).
2. **Frosted Glass Default Tab (`omarchy-zen-glass`)**:
   - Transforms default empty/new tab areas (`about:blank`, `about:newtab`, `about:home`) into transparent frosted glass matching the Ghostty terminal, allowing wallpaper and Hyprland blur to shine through.
   - Preserves 100% solid opacity and crisp readability for all loaded web pages via strict `@-moz-document` scoping in `userContent.css`.
   - Template: [`configs/omarchy/themed/zen-content.css.tpl`](file:///home/soham/omarchy-backup/configs/omarchy/themed/zen-content.css.tpl). CLI controller: `omarchy-zen-glass` (`--status`, `--toggle`).

#### 🕶️ Omarchy Dark Reader Integration (`configs/zen/mods/darkreader/`)
- **Custom-Engineered Browser Extension (`addon@darkreader.org.xpi` v4.9.999.1)**:
  - Dedicated `omarchy` toggle button in the extension popup with accent glow indicators.
  - **ITU-R BT.601 Perceptual Luminance Math**: Guarantees dark backgrounds are never misclassified as light mode even on custom palettes, and automatically switches to high-contrast charcoal typography (`#4d2e1a`) on light parchment themes (Akaito `#f3e4cb`).
  - **Deep Web-App Customization**: Injects tailored CSS variables and selectors for YouTube (fixes masthead, chip clouds, rich grids, mini-guides, reels, and video containers), GitHub (`--bgColor-*`), and Reddit (Shreddit).
  - Non-destructive state toggling preserving user default settings when Omarchy mode is deactivated.

#### 📦 Pre-Packaged Extensions Suite & Native Messaging
All essential workstation extensions are backed up as reproducible `.xpi` packages in [`configs/zen/extensions/`](file:///home/soham/omarchy-backup/configs/zen/extensions):
- **`addon@darkreader.org.xpi`**: Patched Omarchy Dark Reader mod.
- **`uBlock0@raymondhill.net.xpi`**: uBlock Origin adblocker.
- **`sponsorBlocker@ajay.app.xpi`**: SponsorBlock automated YouTube segment skipper.
- **`{762f9885-5a13-4abd-9c77-433dcd38b8fd}.xpi`**: Return YouTube Dislike.
- **`{60493d8c-aec8-448e-a247-5d2cfa047d69}.xpi`**: Ambient Light for YouTube.
- **`fdm_ffext2@freedownloadmanager.org.xpi`**: Free Download Manager extension with native messaging host (`native-messaging-hosts/org.freedownloadmanager.fdm5.cnh.json`).
- **`websiteblocker@wesleybranton.com.xpi`**: Distraction-free website blocker.
- **Shortcuts & Mod Registry**: Complete keymap mappings in `zen-keyboard-shortcuts.json` and mod specifications in [`MODS.md`](file:///home/soham/omarchy-backup/configs/zen/MODS.md).

### 5. 🌐 Brave Origin Secondary Browser Theming Ecosystem
- **Transparent NTP Canvas (`~/.config/omarchy/brave-polish/`)**: Unpacked MV3 companion extension that renders the active theme's colors and wallpapers onto a transparent canvas directly over Hyprland.
- **Theme Templates (`configs/omarchy/themed/`)**: `brave-ntp.css.tpl`, `brave-polish.css.tpl`, `brave-polish.json.tpl`, `brave-manifest.json.tpl`, `brave-global.css.tpl`.
- **Brave Dark Reader Fork (`configs/omarchy/brave-darkreader/`)**: Full Chromium MV3 port of Zen's Dark Reader mod featuring ITU-R BT.601 perceptual luminance checking and dual-mode color mathematics.
- **Managed Policy (`/etc/brave/policies/managed/omarchy-ntp.json`)**: Locks Brave's New Tab Page URL to the Omarchy NTP extension canvas.
- **CLI & Automated Hook**: `omarchy-sync-brave` (`--sync`, `--status`) invoked automatically on every theme change via `~/.config/omarchy/hooks/theme-set.d/brave-sync.sh`.
- **Chromium & Brave Startup Flags**: `configs/chromium-flags.conf`, `configs/brave-origin-nightly-flags.conf` (pre-loads Brave Polish and essential system extensions), and `configs/environment.d/brave.conf`.

### 6. 🎨 The Storyteller Craft Application Suite & Creative Cloud (10 Pro Workstations)

The **Storyteller Craft Suite** is Soham's custom-engineered creative and office application ecosystem for Omarchy Linux. Built with Rust, `egui`, and `wgpu`, each application has been specifically patched and extended with deep Omarchy desktop integration, live dynamic per-theme color adaptation, headless AI agent control interfaces via the Model Context Protocol (MCP), and centralized supervision via **CraftCloud**.

#### 🧰 Suite Applications & Roles
| Application | Version | Category | Role & Upstream Base | Artifacts & Binaries |
| :--- | :--- | :--- | :--- | :--- |
| **CraftCloud** | `0.1.0` | Suite Hub | Creative Cloud command center, process supervisor, unified recent files | `craftcloud`, `ai.storyteller.craftcloud.desktop` |
| **PhotoCraft** | `0.5.0` | Raster Graphics | Layered photo editing, PSD/QOI engine, Vulkan GPU acceleration | `photocraft.real`, `photocraft-cli`, `ai.storyteller.photocraft.desktop` |
| **VectorCraft** | `0.4.0` | Vector Graphics | Scalable vector illustration, SVG editor, precision Bezier curves | `vectorcraft.real`, `vectorcraft-cli`, `ai.storyteller.vectorcraft.desktop` |
| **FilmCraft** | `0.4.0` | Video Editing | Multi-track non-linear video editing workstation, Lumetri scopes | `filmcraft.real`, `filmcraft-cli`, `ai.storyteller.filmcraft.desktop` |
| **EffectCraft** | `0.6.0` | Motion Graphics | After Effects alternative, 300+ VFX, graph editor, 3D camera compositing | `effectcraft.real`, `effectcraft-cli`, `ai.storyteller.effectcraft.desktop` |
| **LightCraft** | `0.4.0` | RAW Photo Catalog | Non-destructive RAW developer, library organizer (Lightroom alternative) | `lightcraft.real`, `lightcraft-cli`, `ai.storyteller.lightcraft.desktop` |
| **PdfCraft** | `0.4.0` | Document Workbench | PDF forms, digital signing, annotations, redaction, OCR, export | `pdfcraft.real`, `pdfcraft-cli`, `ai.storyteller.pdfcraft.desktop` |
| **WordCraft** | `0.3.0` | Document Processor | Microsoft Word alternative in pure Rust, ribbon UI, styles, DOCX/ODT | `wordcraft.real`, `wordcraft-cli`, `ai.storyteller.wordcraft.desktop` |
| **GridCraft** | `0.3.0` | Spreadsheets | Excel alternative in pure Rust, formula engine, charting, XLSX fidelity | `gridcraft.real`, `gridcraft-cli`, `ai.storyteller.gridcraft.desktop` |
| **DeckCraft** | `0.3.0` | Presentations | PowerPoint alternative in pure Rust, slide transitions, PPTX fidelity | `deckcraft.real`, `deckcraft-cli`, `ai.storyteller.deckcraft.desktop` |

#### 🌟 Workstation Profiles & Deep Capabilities

1. **[CraftCloud](file:///home/soham/omarchy-backup/apps/craftcloud)** (`v0.1.0` — Unified Creative Suite Hub & Command Center):
   - **Central Launchpad & Supervisor**: Native Rust desktop command center (`eframe`/`egui`/`wgpu`) overseeing all 9 Craft creative tools. Tracks running PIDs, memory usage, and execution states.
   - **Recent Documents Aggregator**: System-wide discovery scanning for `.pcraft`, `.psd`, `.vectorcraft`, `.filmcraft`, `.ecproj`, `.dng`, `.pdf`, `.docx`, `.xlsx`, and `.pptx` documents, allowing one-click resumption from a single dashboard.
   - **Quick Tools**: Fast asset format conversions and exports without launching full heavy workspaces.
   - **Full Source Backup**: Preserved in [`apps/craftcloud/source/`](file:///home/soham/omarchy-backup/apps/craftcloud/source) for independent maintenance and compilation.

2. **[WordCraft](file:///home/soham/omarchy-backup/apps/wordcraft)** (`v0.3.0` — Microsoft Word Alternative):
   - **Clean-Room Pure Rust**: Clean-room word processing workstation with zero C/C++ office bloat.
   - **Format Fidelity**: Native round-trip editing for `.docx`, `.docm`, `.dotx`, `.odt`, `.rtf`, `.txt`, `.md`, and `.html`.
   - **Ribbon & Layout Engine**: Classic tabbed ribbon UI (Home, Insert, Layout, References, Review, View), rich paragraph styles, multi-column sections, footnotes, citations, and table styling.
   - **Track Changes & Review**: In-line insertion/deletion diff tracking, author color attribution, and threaded document annotations.
   - **MCP Tools**: 16 tool schemas in [`mcp/wordcraft/`](file:///home/soham/omarchy-backup/mcp/wordcraft) for headless agent inspection, text replacement, and automated document compilation.

3. **[GridCraft](file:///home/soham/omarchy-backup/apps/gridcraft)** (`v0.3.0` — Microsoft Excel Alternative):
   - **High-Performance Spreadsheet Engine**: Clean-room spreadsheet workstation in pure Rust with topological dependency calculation.
   - **Excel Formula Compatibility**: 100+ standard formulas (`SUM`, `AVERAGE`, `VLOOKUP`, `INDEX`, `MATCH`, financial, date/time, and logic expressions).
   - **Data Formats & Charts**: Native `.xlsx`, `.xlsm`, `.csv`, `.tsv` support, in-cell formatting, conditional formatting rules, and embedded chart generation (bar, line, scatter, pie).
   - **MCP Tools**: 22 tool schemas in [`mcp/gridcraft/`](file:///home/soham/omarchy-backup/mcp/gridcraft) for workbook inspection, range queries, formula evaluation, and table automation.

4. **[EffectCraft](file:///home/soham/omarchy-backup/apps/effectcraft)** (`v0.6.0` — Adobe After Effects Alternative):
   - **Motion Graphics & VFX Compositor**: Pro visual effects workstation built in pure Rust with 300+ GPU-accelerated effects.
   - **Graph Editor & Curve Keyframing**: Temporal and spatial Bezier graph editor with sub-frame accuracy, velocity handles, and math expressions.
   - **Camera & 3D Layers**: 3D layer transforms, point/spot lights, depth-of-field, and motion paths.
   - **Project Pipeline**: Native `.ecproj`, `.ecprojx`, After Effects `.aep` / JSON project import, and pure-Rust video encoding (H.264, HEVC, ProRes, WebM).
   - **MCP Tools**: 22 tool schemas in [`mcp/effectcraft/`](file:///home/soham/omarchy-backup/mcp/effectcraft) for layer keyframe scripting, effect parameter adjustment, and frame rendering.

5. **[DeckCraft](file:///home/soham/omarchy-backup/apps/deckcraft)** (`v0.3.0` — Microsoft PowerPoint Alternative):
   - **Slide Presentation Workstation**: Clean-room PowerPoint-style presentation app in pure Rust with native `.pptx`, `.potx`, `.ppsx` round-trip fidelity.
   - **Layouts & Smart Shapes**: Master slide layouts, vector shape creation, smart alignment guides, tables, charts, and media embeds.
   - **Transitions & Timings**: Smooth slide transitions, element animations, and sequence choreography.
   - **Presenter Display**: Dual-monitor presenter display with speaker notes, elapsed timer HUD, and thumbnail slide sorter.
   - **MCP Tools**: 24 tool schemas in [`mcp/deckcraft/`](file:///home/soham/omarchy-backup/mcp/deckcraft) for slide creation, text manipulation, and headless slide rendering.

6. **[PhotoCraft](file:///home/soham/omarchy-backup/apps/photocraft)** (`v0.5.0` — Adobe Photoshop Alternative):
   - **Layered Raster Graphics**: High-fidelity layered image editing, non-destructive layer masks, adjustment layers, blend modes, and retouching.
   - **Format Engine**: Full support for `.psd`, `.psb`, `.pcraft`, `.png`, `.jpg`, `.webp`, `.qoi`, and `.exr`.
   - **Hardware Acceleration**: GPU canvas rendering powered by Vulkan and `wgpu`.

7. **[VectorCraft](file:///home/soham/omarchy-backup/apps/vectorcraft)** (`v0.4.0` — Adobe Illustrator Alternative):
   - **Vector Illustration Workstation**: High-precision Bezier curve editor, multi-artboard canvas, Pathfinder boolean operations, and stroke profiles.
   - **Vector Pipeline**: Native `.svg`, `.svgz`, `.ai`, `.eps`, `.pdf` vector file import/export.

8. **[FilmCraft](file:///home/soham/omarchy-backup/apps/filmcraft)** (`v0.4.0` — Adobe Premiere Pro Alternative):
   - **Non-Linear Video Editor (NLE)**: Multi-track video and audio timeline, razor blade splitting, ripple edits, transitions, and audio envelope keyframing.
   - **Color & Scopes**: Lumetri-style color grading, waveform vectorscopes, histogram analysis, and 3D LUT application.

9. **[LightCraft](file:///home/soham/omarchy-backup/apps/lightcraft)** (`v0.4.0` — Adobe Lightroom Alternative):
   - **RAW Photo Catalog & Developer**: Non-destructive RAW processing engine (`.dng`, `.arw`, `.cr2`, `.cr3`, `.nef`, `.raf`).
   - **Smart Studio**: Exposure/white balance calibration, parametric tone curves, AI denoise integration, face recognition clustering, and HDR/panorama merges.

10. **[PdfCraft](file:///home/soham/omarchy-backup/apps/pdfcraft)** (`v0.4.0` — Adobe Acrobat Alternative):
    - **PDF Manipulation Workstation**: PDF inspection, annotation, interactive form filling, digital signature stamping, OCR extraction, page reordering, and redaction.

#### ⚙️ Unified Engineering Architecture
1. **LiveTokens Dynamic Theming Engine (`theme-unlock.patch`)**:
   - Each app contains a custom Rust module (`crates/ui-egui/src/theme.rs` & `lib.rs`) introducing `LiveTokens`.
   - The GUI polls its respective theme specification (`~/.config/<app>/theme.json`) every **400ms**.
   - When a theme change occurs, `LiveTokens::poll` dynamically repaints panels, chrome, canvas, fields, buttons, and borders in place without restarting the application.
2. **Omarchy Synchronization Layer (`omarchy-sync-<app>`)**:
   - High-contrast Python palette math reads `/home/soham/.local/state/omarchy/current/theme/colors.toml` and synthesizes 20–37 semantic surface tokens tailored to that application's visual hierarchy.
   - Automatically dispatched by Omarchy theme-set hooks: `~/.config/omarchy/hooks/theme-set.d/<app>-sync.sh`.
   - On running instances, the sync script connects to the app's loopback control socket (`~/.config/<app>/control.json` or ephemeral port) to trigger an immediate frame flush for zero-latency repainting.
3. **Headless Automation & Antigravity MCP Integration**:
   - Each app ships with a companion CLI binary (`<app>-cli`) supporting headless rendering, batch operations, format conversion, and stdio Model Context Protocol (MCP) server mode.
   - Over **550+ tool schemas** are backed up in `mcp/` and registered into Antigravity (`~/.gemini/antigravity-cli/mcp/`) allowing AI agents to inspect projects, manipulate layers/timelines/spreadsheets/slides, and export media programmatically.
4. **Compact Release Bundling & Git Compatibility**:
   - Full release binaries (~30MB–100MB each) are stripped (`strip --strip-unneeded`) and compressed with multi-threaded `xz -9 -T0` into `apps/<app>/build/<app>-linux-x86_64.tar.xz`.
   - Every archive is strictly under **43 MB** (well below GitHub's 50MB warning threshold and 100MB hard limit), enabling lightning-fast cloning and zero-compilation recovery.

#### 🤖 AI Agent Restoration Playbook
For any future AI agent restoring this workflow:
1. **Automated Recovery**: Running `./restore.sh` automatically invokes all 10 `apps/<app>/install.sh` scripts, registers desktop shortcuts, installs MIME databases, generates icon caches, places theme hooks, and performs an initial palette synchronization.
2. **Standalone Installation**: Any Craft app can be restored independently at any time:
   ```bash
   apps/craftcloud/install.sh
   apps/photocraft/install.sh
   apps/vectorcraft/install.sh
   apps/filmcraft/install.sh
   apps/effectcraft/install.sh
   apps/lightcraft/install.sh
   apps/pdfcraft/install.sh
   apps/wordcraft/install.sh
   apps/gridcraft/install.sh
   apps/deckcraft/install.sh
   ```
3. **Building from Source**: If re-compilation is ever required, run `apps/<app>/build.sh`. This clones the upstream repository (`https://github.com/storytold/<app>.git`) or accesses the backed-up source in `apps/<app>/source`, applies the verified `apps/<app>/<app>-theme-unlock.patch`, builds release targets via `cargo build --release -p <app> -p <app>-cli`, and installs the resulting binaries.
4. **Verification Gates**:
   - Binaries exist in `~/.local/bin/` (`<app>`, `<app>.real`, `<app>-cli`, `omarchy-sync-<app>`) and are executable (`chmod +x`).
   - Desktop entry is recognized by `update-desktop-database ~/.local/share/applications`.
   - Theme sync works: running `omarchy-sync-<app>` cleanly produces `~/.config/<app>/theme.json`.
   - Native Wayland execution works; if running in virtualized/nested environments, use `env <APP>_FORCE_XWAYLAND=1 <app>`.

### 7. 🛠️ Utilities, Standalone Apps & System Services
- **Standalone Auxiliary Apps (`apps/`)**:
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
- **Visual Workspace Switcher Snapshot Engine**: `plugins/reomarchy.workspace-switcher` with `scripts/capture-previews.sh` utilizing grim to take static PNG snapshots per monitor before overlay summoning, eliminating heavy live screencopy lag.
- **`omarchy-dictate` (`Super + H`, `Super + Alt + V`)**: Primary Google Gemini 3.5 Transcribe dictation engine with Voxtype Aura HUD integration, local Whisper fallback, and direct wtype text injection.
- **`soham.omagent`**: Custom command pill overlay assistant (`Alt + Space`) with tri-mode routing (`LOCAL`, `WEB`, `CODE`), live interactive Firstmate steering (`--steer`), bidirectional chat replies (`firstmate reply`), Herdr workspace/tab orchestration, and background Antigravity harness execution with `omagent-harness-view` terminal streaming and seamless CLI handover via `Ctrl + E`.
- **`pretty.omagen`**: Wallpaper generator and styling plugin enhanced with custom interactive wallpaper browser (`bin/omagen-wallpaper-browser`, `WallpaperBrowserApp.qml`, and `WallpaperBridge.js`).
- **`omagent-agent-status`**: CLI session watcher polling and formatting the latest actions and status from active Antigravity/Omagent sessions.
- **`omarchy-fix-fingerprint`**: FPC 10a5:9200 fingerprint controller setup, udev persistence, and suspend/resume reset hook.
- **`cmf-buds-mode`**: CLI utility controlling Active Noise Cancellation modes for Nothing CMF Buds.
- **`omarchy-dictionary-lookup` (`Super + D`)**: Fast dictionary popup for active text selections with automatic clipboard and primary selection extraction.
- **`omarchy-sync-vlc`**: Dynamically writes 4-stop slider gradient and dark/light palette into `~/.config/vlc/vlcrc`.
- **Fastfetch Enhancements**: `fastfetch-arch-anim` (smooth spinning Arch ASCII animation) and `fastfetch-theme-accent` (theme accent mapper).
- **`fetch`**: Ultra-fast C/ASCII 3D donut spinning system info fetcher with Omarchy profile.
- **Wayland Idle Inhibitors**: `omarchy-wayland-inhibit` (compiled C Wayland protocol client) and `omarchy-video-idle-inhibit` (MPRIS and PipeWire audio stream daemon with screensaver lock-guard).
- **Sunshine & Tablet Mode Streaming**: `bin/tablet-mode` and `configs/sunshine/` enabling zero-latency wireless streaming and virtual display scaling to Redmi Pad SE via `HEADLESS-1` (1200x2000 90° portrait or 2000x1200 landscape).
- **EasyEffects Audio Ecosystem & Navbar Switcher**: Full integration including `plugins/soham.easyeffects/` (with `purge-preset.sh`, stock baseline protection, mouse-wheel scrolling, and modal confirmation), all 6 curated IEM Equalizer presets in `configs/easyeffects/output/` (Diablo, Daybreak, Nightfall, Maestro Mini, Nightingale, Tangzu Wan'er Stock), hardware routing autoload rules in `configs/easyeffects/autoload/output/`, database configurations in `configs/easyeffects/db/`, autostart entry `configs/autostart/easyeffects.desktop`, and systemd service `configs/systemd/user/easyeffects.service`.
- **Navigation Guide Modal**: `plugins/nav-guide` centered overlay modal with background scrim suggesting context-aware shortcuts (`Super + K`).
- **PowerWave Charging Indicator**: `plugins/x692137x.powerwave` with real-time netlink/sysfs power monitoring daemon and `bin/powerwave` CLI trigger.
- **WhatsApp Bridge & Clipboard Pasting**: `plugins/io.github.ricky.whatsapp` with Ctrl+V clipboard image paste integration (`bin/omarchy-whatsapp-paste-image`).
- **Antigravity Interactive Question Ting**: `configs/antigravity-app/gemini-config/hooks/ring-ting.sh` and `sounds/ting.wav` ringing an audio chime and terminal bell whenever interactive choices (`ask_question`) await user input.
- **Agy Command Watcher**: `bin/agy-ting-watcher` tailing logs to emit audio chimes upon background command completion (CPU-optimized polling).
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
├── apps/                    # Standalone GUI applications (CraftCloud, PhotoCraft, VectorCraft, FilmCraft, EffectCraft, LightCraft, PdfCraft, WordCraft, GridCraft, DeckCraft, Photos Gallery, Gallery)
├── bin/                     # Custom binaries and helper executables (~/.local/bin)
├── configs/                 # Dotfiles and application configs (~/.config)
│   ├── omagent/             # Omagent prompt, mobile PWA web client, and config template
│   ├── fetch/               # Fetch configuration and Omarchy ASCII branding
│   ├── photocraft/          # PhotoCraft preferences, egui UI layout, and token schema
│   ├── vectorcraft/         # VectorCraft UI preferences and real-time token schema
│   ├── filmcraft/           # FilmCraft preferences and real-time video token schema
│   ├── effectcraft/         # EffectCraft composition preferences and motion token schema
│   ├── lightcraft/          # LightCraft UI state, RAW library settings, and token schema
│   ├── pdfcraft/            # PdfCraft preferences, UI state, and real-time token schema
│   ├── wordcraft/           # WordCraft document preferences, ribbon UI, and token schema
│   ├── gridcraft/           # GridCraft spreadsheet preferences and token schema
│   ├── deckcraft/           # DeckCraft presentation preferences and token schema
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
