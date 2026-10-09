# VectorCraft — Omarchy Linux Full App Build & Integration

Full application build, configuration, desktop integration, and live dynamic theming pipeline for [VectorCraft](https://github.com/storytold/vectorcraft) on Omarchy Linux.

---

## 1. What is Backed Up

1. **Precompiled Release Build Bundle** (`build/vectorcraft-linux-x86_64.tar.xz`):
   - `vectorcraft.real`: Optimized release GUI binary with custom-engineered `LiveTokens` hot-reloader.
   - `vectorcraft-cli`: Headless automation, format converter, and stdio Model Context Protocol (MCP) server.
   - `vectorcraft`: Launcher wrapper configuring loopback control ports, theme file, and optional XWayland compatibility.
   - `omarchy-sync-vectorcraft`: Python palette synthesis engine converting Omarchy's active `colors.toml` into `~/.config/vectorcraft/theme.json` for live 400ms hot-reloads.
2. **Desktop Integration & Assets**:
   - `desktop-entries/ai.storyteller.vectorcraft.desktop`: Freedesktop application entry with MIME associations (`image/svg+xml;application/pdf;`).
   - `icons/hicolor/`: Complete suite of scalable SVG and raster icons (`16x16` up to `512x512`).
   - `pixmaps/ai.storyteller.vectorcraft.png`: High-resolution 256x256 app icon.
3. **Configurations & Engine State**:
   - `configs/vectorcraft/theme.json`: Real-time token mapping specification.
   - `configs/vectorcraft/ui.json`: User interface state and brightness preferences.
4. **Omarchy Hook**:
   - `configs/omarchy/hooks/theme-set.d/vectorcraft-sync.sh`: Auto-dispatched on every `omarchy theme set <name>` to repaint the GUI without restarts.
5. **Source Reproducibility**:
   - `vectorcraft-theme-unlock.patch`: Custom Git patch implementing `apply_tokens` and `LiveTokens` polling in VectorCraft.
   - `build.sh`: Rebuild script from upstream Git repository.
   - `install.sh`: Instant one-line extraction and system registration.

---

## 2. Restoring on a Fresh Omarchy Setup

Restoring takes 2 seconds from the repository root:

```bash
./restore.sh
```

Or manually install VectorCraft standalone:

```bash
apps/vectorcraft/install.sh
```

---

## 3. Rebuilding from Source (Optional)

If you ever wish to recompile from source using Rust:

```bash
apps/vectorcraft/build.sh
```
