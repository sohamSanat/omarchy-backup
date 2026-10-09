# LightCraft — Omarchy Linux Full App Build & Integration

Full application build, configuration, desktop integration, and live dynamic theming pipeline for [LightCraft](https://github.com/storytold/lightcraft) on Omarchy Linux.

---

## 1. What is Backed Up

1. **Precompiled Release Build Bundle** (`build/lightcraft-linux-x86_64.tar.xz`):
   - `lightcraft.real`: Optimized release RAW photo developer and catalog workbench GUI with custom-engineered `LiveTokens` hot-reloader.
   - `lightcraft-cli`: Headless automation, RAW processing, export pipeline, and stdio Model Context Protocol (MCP) server.
   - `lightcraft`: Launcher wrapper configuring Vulkan GPU backend, theme file, and optional XWayland compatibility.
   - `omarchy-sync-lightcraft`: Python palette synthesis engine converting Omarchy's active `colors.toml` into `~/.config/lightcraft/theme.json` for live 400ms hot-reloads covering 28 surface tokens.
2. **Desktop Integration & Assets**:
   - `desktop-entries/ai.storyteller.lightcraft.desktop`: Freedesktop application entry with MIME associations (JPEG, PNG, TIFF, WebP, DNG, ARW, CR2, CR3, NEF, RAF, ORF, RW2, PEF, AVIF).
   - `metainfo/ai.storyteller.lightcraft.metainfo.xml`: AppStream metadata specification (v0.4.0).
   - `mime/ai.storyteller.lightcraft.xml`: Shared MIME info definitions.
   - `icons/hicolor/`: Complete suite of scalable SVG and raster icons (`16x16` up to `512x512`).
   - `pixmaps/ai.storyteller.lightcraft.png`: High-resolution 256x256 app icon.
3. **Configurations & Engine State**:
   - `configs/lightcraft/theme.json`: Real-time token mapping specification covering 28 photo developer surface tokens.
   - `configs/lightcraft/ui.json`: User interface state, panel layouts, library location (`~/Pictures/LightCraft Library`), and external editor (`photocraft`).
4. **Omarchy Hook**:
   - `configs/omarchy/hooks/theme-set.d/lightcraft-sync.sh`: Auto-dispatched on every `omarchy theme set <name>` to repaint the GUI without restarts.
5. **Antigravity MCP Integration**:
   - `mcp/lightcraft/`: 296 Model Context Protocol tool definitions and AI agent instructions for deep catalog querying, develop parameters, masking, curve adjustments, spot healing, color grading, HDR merge, export, and history tracking.
6. **Source Reproducibility**:
   - `lightcraft-theme-unlock.patch`: Custom Git patch implementing `apply_tokens` and `LiveTokens` polling in LightCraft.
   - `build.sh`: Rebuild script from upstream Git repository.
   - `install.sh`: Instant one-line extraction and system registration.

---

## 2. Restoring on a Fresh Omarchy Setup

Restoring takes seconds from the repository root:

```bash
./restore.sh
```

Or manually install LightCraft standalone:

```bash
apps/lightcraft/install.sh
```

---

## 3. Rebuilding from Source (Optional)

If you ever wish to recompile from source using Rust:

```bash
apps/lightcraft/build.sh
```
