# EffectCraft — Omarchy Linux Full App Build & Integration

Full application build, configuration, desktop integration, and live dynamic theming pipeline for [EffectCraft](https://github.com/storytold/effectcraft) on Omarchy Linux.

---

## 1. What is Backed Up

1. **Precompiled Release Build Bundle** (`build/effectcraft-linux-x86_64.tar.xz`):
   - `effectcraft.real`: Optimized release GUI motion graphics compositor binary with custom-engineered `LiveTokens` hot-reloader.
   - `effectcraft-cli`: Headless automation, rendering engine, and stdio Model Context Protocol (MCP) server.
   - `effectcraft`: Launcher wrapper configuring loopback control ports, theme file, and optional XWayland compatibility.
   - `omarchy-sync-effectcraft`: Python palette synthesis engine converting Omarchy's active `colors.toml` into `~/.config/effectcraft/theme.json` for live 400ms hot-reloads and updating `~/.config/effectcraft/prefs.json`.
2. **Desktop Integration & Assets**:
   - `desktop-entries/ai.storyteller.effectcraft.desktop`: Freedesktop application entry.
   - `icons/hicolor/`: Complete suite of scalable SVG and raster icons (`16x16` up to `512x512`).
   - `pixmaps/ai.storyteller.effectcraft.png`: High-resolution 256x256 app icon.
3. **Configurations & Engine State**:
   - `configs/effectcraft/theme.json`: Real-time token mapping specification covering motion graphics and timeline surface tokens.
   - `configs/effectcraft/prefs.json`: Composition preferences, grid guides, and theme state.
4. **Omarchy Hook**:
   - `configs/omarchy/hooks/theme-set.d/effectcraft-sync.sh`: Auto-dispatched on every `omarchy theme set <name>` to repaint the GUI without restarts.
5. **Antigravity MCP Integration**:
   - `mcp/effectcraft/`: 22 Model Context Protocol tool definitions and AI agent instructions for deep composition inspection, keyframe automation, layer manipulation, and frame rendering.
6. **Source Reproducibility**:
   - `effectcraft-theme-unlock.patch`: Custom Git patch implementing `LiveTokens` file-watching and dynamic override polling in EffectCraft.
   - `build.sh`: Rebuild script from upstream Git repository.
   - `install.sh`: Instant one-line extraction and system registration.

---

## 2. Restoring on a Fresh Omarchy Setup

To install EffectCraft standalone:

```bash
apps/effectcraft/install.sh
```

---

## 3. Rebuilding from Source (Optional)

If you ever wish to recompile from source using Rust:

```bash
apps/effectcraft/build.sh
```
