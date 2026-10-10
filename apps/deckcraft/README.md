# DeckCraft — Omarchy Linux Full App Build & Integration

Full application build, configuration, desktop integration, and live dynamic theming pipeline for [DeckCraft](https://github.com/storytold/deckcraft) on Omarchy Linux.

---

## 1. What is Backed Up

1. **Precompiled Release Build Bundle** (`build/deckcraft-linux-x86_64.tar.xz`):
   - `deckcraft.real`: Optimized release GUI PowerPoint-compatible presentation workstation binary with custom-engineered `LiveTokens` hot-reloader.
   - `deckcraft-cli`: Headless automation, presentation conversion/inspection engine, and stdio Model Context Protocol (MCP) server.
   - `deckcraft`: Launcher wrapper configuring loopback control ports (48295), theme file, and optional XWayland compatibility.
   - `omarchy-sync-deckcraft`: Python palette synthesis engine converting Omarchy's active `colors.toml` into `~/.config/deckcraft/theme.json` for live hot-reloads and loopback socket pinging.
2. **Desktop Integration & Assets**:
   - `desktop-entries/ai.storyteller.deckcraft.desktop`: Freedesktop application entry with MIME associations (`.pptx`, `.potx`, `.ppsx`, etc.).
   - `metainfo/ai.storyteller.deckcraft.metainfo.xml`: AppStream metadata specification (v0.3.0).
   - `mime/ai.storyteller.deckcraft.xml`: Shared MIME info definitions.
   - `icons/hicolor/`: Complete suite of scalable SVG and raster icons (`16x16` up to `512x512`).
   - `pixmaps/ai.storyteller.deckcraft.png`: High-resolution 256x256 app icon.
3. **Configurations & Engine State**:
   - `configs/deckcraft/theme.json`: Real-time token mapping specification covering slide presentation and canvas surface tokens.
   - `configs/deckcraft/prefs.json`: Presentation preferences, presenter notes, and recent decks.
   - `configs/deckcraft/ui.json`: Slide sorter and pane layout state.
4. **Omarchy Hook**:
   - `configs/omarchy/hooks/theme-set.d/deckcraft-sync.sh`: Auto-dispatched on every `omarchy theme set <name>` to repaint the GUI without restarts.
5. **Antigravity MCP Integration**:
   - `mcp/deckcraft/`: 24 Model Context Protocol tool definitions and AI agent instructions for slide deck manipulation, shape creation, text formatting, and presentation inspection.
6. **Source Reproducibility**:
   - `deckcraft-theme-unlock.patch`: Custom Git patch implementing `ACTIVE_TOKENS` and `LiveTokens` polling in DeckCraft.
   - `build.sh`: Rebuild script from upstream Git repository.
   - `install.sh`: Instant one-line extraction and system registration.

---

## 2. Restoring on a Fresh Omarchy Setup

Restoring takes seconds from the repository root:

```bash
./restore.sh
```

Or manually install DeckCraft standalone:

```bash
apps/deckcraft/install.sh
```

---

## 3. Rebuilding from Source (Optional)

If you ever wish to recompile from source using Rust:

```bash
apps/deckcraft/build.sh
```
