# WordCraft — Omarchy Linux Full App Build & Integration

Full application build, configuration, desktop integration, and live dynamic theming pipeline for [WordCraft](https://github.com/storytold/wordcraft) on Omarchy Linux.

---

## 1. What is Backed Up

1. **Precompiled Release Build Bundle** (`build/wordcraft-linux-x86_64.tar.xz`):
   - `wordcraft.real`: Optimized release GUI WordCraft desktop binary with custom-engineered `LiveTokens` hot-reloader.
   - `wordcraft-cli`: Headless automation, document conversion/inspection engine, and stdio Model Context Protocol (MCP) server.
   - `wordcraft`: Launcher wrapper configuring loopback control ports (7981), theme file, Vulkan GPU, and optional XWayland compatibility.
   - `omarchy-sync-wordcraft`: Python palette synthesis engine converting Omarchy's active `colors.toml` into `~/.config/wordcraft/theme.json` for live hot-reloads and loopback socket pinging.
2. **Desktop Integration & Assets**:
   - `desktop-entries/ai.storyteller.wordcraft.desktop`: Freedesktop application entry with MIME associations (`.docx`, `.odt`, `.rtf`, etc.).
   - `metainfo/ai.storyteller.wordcraft.metainfo.xml`: AppStream metadata specification (v0.3.0).
   - `mime/ai.storyteller.wordcraft.xml`: Shared MIME info definitions.
   - `icons/hicolor/`: Complete suite of scalable SVG and raster icons (`16x16` up to `512x512`).
   - `pixmaps/ai.storyteller.wordcraft.png`: High-resolution 256x256 app icon.
3. **Configurations & Engine State**:
   - `configs/wordcraft/theme.json`: Real-time token mapping specification covering 32 design tokens.
   - `configs/wordcraft/ui.json`: UI state, ribbon preferences, and viewing configuration.
4. **Omarchy Hook**:
   - `configs/omarchy/hooks/theme-set.d/wordcraft-sync.sh`: Auto-dispatched on every `omarchy theme set <name>` to repaint the GUI without restarts.
5. **Antigravity MCP Integration**:
   - `mcp/wordcraft/`: 16 Model Context Protocol tool definitions and AI agent instructions for deep document inspection, manipulation, commands, and live UI control.
6. **Source Reproducibility**:
   - `wordcraft-theme-unlock.patch`: Custom Git patch implementing `ACTIVE_TOKENS` and `LiveTokens` polling in WordCraft.
   - `build.sh`: Rebuild script from upstream Git repository.
   - `install.sh`: Instant one-line extraction and system registration.

---

## 2. Restoring on a Fresh Omarchy Setup

Restoring takes seconds from the repository root:

```bash
./restore.sh
```

Or manually install WordCraft standalone:

```bash
apps/wordcraft/install.sh
```

---

## 3. Rebuilding from Source (Optional)

If you ever wish to recompile from source using Rust:

```bash
apps/wordcraft/build.sh
```
