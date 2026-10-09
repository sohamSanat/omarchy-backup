# FilmCraft — Omarchy Linux Full App Build & Integration

Full application build, configuration, desktop integration, and live dynamic theming pipeline for [FilmCraft](https://github.com/storytold/filmcraft) on Omarchy Linux.

---

## 1. What is Backed Up

1. **Precompiled Release Build Bundle** (`build/filmcraft-linux-x86_64.tar.xz`):
   - `filmcraft.real`: Optimized release GUI video editor binary with custom-engineered `LiveTokens` hot-reloader.
   - `filmcraft-cli`: Headless automation, video rendering engine, and stdio Model Context Protocol (MCP) server.
   - `filmcraft`: Launcher wrapper configuring loopback control ports, theme file, and optional XWayland compatibility.
   - `omarchy-sync-filmcraft`: Python palette synthesis engine converting Omarchy's active `colors.toml` into `~/.config/filmcraft/theme.json` for live 400ms hot-reloads and updating `~/.local/share/filmcraft/preferences.json`.
2. **Desktop Integration & Assets**:
   - `desktop-entries/ai.storyteller.filmcraft.desktop`: Freedesktop application entry with MIME associations (`video/*;application/x-filmcraft;`).
   - `metainfo/ai.storyteller.filmcraft.metainfo.xml`: AppStream metadata specification.
   - `icons/hicolor/`: Complete suite of scalable SVG and raster icons (`16x16` up to `512x512`).
   - `pixmaps/ai.storyteller.filmcraft.png`: High-resolution 256x256 app icon.
3. **Configurations & Engine State**:
   - `configs/filmcraft/theme.json`: Real-time token mapping specification covering 37 video editor surface tokens.
   - `configs/filmcraft/preferences.json`: Video editing preferences and color profiles.
4. **Omarchy Hook**:
   - `configs/omarchy/hooks/theme-set.d/filmcraft-sync.sh`: Auto-dispatched on every `omarchy theme set <name>` to repaint the GUI without restarts.
5. **Antigravity MCP Integration**:
   - `mcp/filmcraft/`: 20 Model Context Protocol tool definitions and AI agent instructions for deep video inspection, UI control, timeline manipulation, and rendering.
6. **Source Reproducibility**:
   - `filmcraft-theme-unlock.patch`: Custom Git patch implementing `apply_tokens` and `LiveTokens` polling in FilmCraft.
   - `build.sh`: Rebuild script from upstream Git repository.
   - `install.sh`: Instant one-line extraction and system registration.

---

## 2. Restoring on a Fresh Omarchy Setup

Restoring takes seconds from the repository root:

```bash
./restore.sh
```

Or manually install FilmCraft standalone:

```bash
apps/filmcraft/install.sh
```

---

## 3. Rebuilding from Source (Optional)

If you ever wish to recompile from source using Rust:

```bash
apps/filmcraft/build.sh
```
