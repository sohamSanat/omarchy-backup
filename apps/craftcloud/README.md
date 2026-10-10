# CraftCloud — Omarchy Linux Unified Creative Suite Hub

Full application build, configuration, desktop integration, and source code backup for **CraftCloud** on Omarchy Linux.

---

## 1. What is CraftCloud

CraftCloud is Soham's custom-engineered desktop command center and application hub for the entire Storyteller Craft ecosystem (Adobe Creative Cloud alternative). Built in pure Rust using `eframe`, `egui`, and `wgpu`, it acts as the centralized coordinator and supervisor across all 9 Craft workstations.

### Core Capabilities:
1. **App Registry & Launchpad**: Instant discovery, status monitoring, and single-click launching of PhotoCraft, VectorCraft, FilmCraft, EffectCraft, LightCraft, PdfCraft, WordCraft, GridCraft, and DeckCraft.
2. **Process Supervisor**: Monitors PID lifecycles, active CPU/memory consumption, loopback IPC ports, and background rendering threads across all running Craft apps.
3. **Recent Documents Hub**: Aggregates recently edited `.pcraft`, `.psd`, `.vectorcraft`, `.svg`, `.filmcraft`, `.ecproj`, `.dng`, `.pdf`, `.docx`, `.xlsx`, and `.pptx` documents across the system for immediate resumption.
4. **Quick Tools**: File format conversions, asset extraction, color palette generation, and batch export shortcuts.
5. **Dynamic Theme Engine**: Automatically adopts the active Omarchy theme colors (`colors.toml`), providing a unified look across the desktop.

---

## 2. What is Backed Up

1. **Precompiled Release Build Bundle** (`build/craftcloud-linux-x86_64.tar.xz`):
   - `craftcloud`: Optimized release binary built with Rust and wgpu.
2. **Complete Source Tree** (`source/`):
   - `Cargo.toml`, `Cargo.lock`, `src/` (`main.rs`, `app.rs`, `app_registry.rs`, `process_supervisor.rs`, `recents.rs`, `quick_tools.rs`, `libraries.rs`, `theme.rs`, `ui/`), and `assets/icons/`.
3. **Desktop Integration & Assets**:
   - `desktop-entries/ai.storyteller.craftcloud.desktop`: Freedesktop application entry.
   - `icons/hicolor/`: Complete suite of scalable SVG and raster icons (`16x16` up to `1024x1024`).
   - `pixmaps/ai.storyteller.craftcloud.png`: High-resolution 256x256 app icon.
4. **Reproducibility & Restore**:
   - `install.sh`: Instant one-line extraction, system registration, and source synchronization.
   - `build.sh`: Rebuild script from source via Cargo.

---

## 3. Restoring on a Fresh Omarchy Setup

Restoring takes seconds from the repository root:

```bash
./restore.sh
```

Or manually install CraftCloud standalone:

```bash
apps/craftcloud/install.sh
```

---

## 4. Rebuilding from Source (Optional)

If you ever wish to recompile from source using Rust:

```bash
apps/craftcloud/build.sh
```
