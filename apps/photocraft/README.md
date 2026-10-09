# PhotoCraft — Omarchy Linux Full App Build & Integration

Full application build, configuration, desktop integration, and live dynamic theming pipeline for [PhotoCraft](https://github.com/storytold/photocraft) (v0.5.0) on Omarchy Linux.

---

## 1. What is Backed Up

1. **Precompiled Release Build Bundle** (`build/photocraft-linux-x86_64.tar.xz` ~34.8 MB):
   - `photocraft.real`: Optimized release GUI binary compiled with `LiveTokens` unlocked.
   - `photocraft-cli`: Headless engine, file converter, batch processor, and stdio Model Context Protocol (MCP) server.
   - `photocraft`: Launcher wrapper configuring loopback control ports, XWayland tablet tilt/pressure, and automatic initial theme generation.
   - `omarchy-sync-photocraft`: Python theme synthesis engine converting Omarchy's active `colors.toml` palette into `~/.config/photocraft/theme.json` for live 400ms hot-reloads.
2. **Desktop Integration & Assets**:
   - `desktop-entries/ai.storyteller.photocraft.desktop`: Freedesktop application entry with MIME associations and Native Wayland desktop action.
   - `icons/hicolor/`: Complete suite of scalable SVG and raster icons (`16x16` up to `512x512`).
   - `mime/ai.storyteller.photocraft.xml`: XML database definitions for `.pcraft`, `.psb`, and `.qoi` files.
3. **Configurations & Engine State**:
   - `configs/photocraft/preferences.json`: Vulkan GPU rendering backend, system titlebar toggle, and dock layout.
   - `configs/photocraft/ui.ron`: egui surface persistence, panel layout geometries, and docking tree.
   - `configs/photocraft/theme.json`: Real-time token mapping specification.
4. **Omarchy Hook**:
   - `configs/omarchy/hooks/theme-set.d/photocraft-sync.sh`: Auto-dispatched on every `omarchy theme set <name>` to repaint the GUI without restarts.
5. **Model Context Protocol (MCP) Server**:
   - `mcp/photocraft/`: JSON tool schemas (`command_run`, `doc_open`, `doc_save`, `ui_inspect`, etc.) and instructions for AI agents.
6. **Source Reproducibility**:
   - `photocraft-theme-unlock.patch`: Exact patch enabling release-mode live design tokens.
   - `build.sh`: Rebuild script from upstream Git repository.
   - `install.sh`: Instant one-line extraction and system registration.

---

## 2. Restoring on a Fresh Omarchy Setup

Restoring takes 2 seconds from the repository root:

```bash
./restore.sh
```

Or manually install PhotoCraft standalone:

```bash
apps/photocraft/install.sh
```

---

## 3. Rebuilding from Source (Optional)

If you ever wish to recompile from source using Rust:

```bash
apps/photocraft/build.sh
```
