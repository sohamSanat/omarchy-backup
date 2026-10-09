# PdfCraft — Omarchy Linux Full App Build & Integration

Full application build, configuration, desktop integration, and live dynamic theming pipeline for [PdfCraft](https://github.com/storytold/pdfcraft) on Omarchy Linux.

---

## 1. What is Backed Up

1. **Precompiled Release Build Bundle** (`build/pdfcraft-linux-x86_64.tar.xz`):
   - `pdfcraft.real`: Optimized release GUI PDF workbench binary with custom-engineered `LiveTokens` hot-reloader.
   - `pdfcraft-cli`: Headless automation, PDF manipulation engine, and stdio Model Context Protocol (MCP) server.
   - `pdfcraft`: Launcher wrapper configuring loopback control ports, theme file, and optional XWayland compatibility.
   - `omarchy-sync-pdfcraft`: Python palette synthesis engine converting Omarchy's active `colors.toml` into `~/.config/pdfcraft/theme.json` for live 400ms hot-reloads and loopback socket pinging.
2. **Desktop Integration & Assets**:
   - `desktop-entries/ai.storyteller.pdfcraft.desktop`: Freedesktop application entry with MIME associations (`application/pdf;`).
   - `metainfo/ai.storyteller.pdfcraft.metainfo.xml`: AppStream metadata specification (v0.4.0).
   - `mime/ai.storyteller.pdfcraft.xml`: Shared MIME info definitions.
   - `icons/hicolor/`: Complete suite of scalable SVG and raster icons (`16x16` up to `512x512`).
   - `pixmaps/ai.storyteller.pdfcraft.png`: High-resolution 256x256 app icon.
3. **Configurations & Engine State**:
   - `configs/pdfcraft/theme.json`: Real-time token mapping specification covering 21 surface tokens.
   - `configs/pdfcraft/app.ron`: UI state, layout preferences, and viewing configuration.
4. **Omarchy Hook**:
   - `configs/omarchy/hooks/theme-set.d/pdfcraft-sync.sh`: Auto-dispatched on every `omarchy theme set <name>` to repaint the GUI without restarts.
5. **Antigravity MCP Integration**:
   - `mcp/pdfcraft/`: 132 Model Context Protocol tool definitions and AI agent instructions for deep document inspection, form manipulation, annotations, comments, bookmarks, watermarking, redaction, OCR, and digital signatures.
6. **Source Reproducibility**:
   - `pdfcraft-theme-unlock.patch`: Custom Git patch implementing `apply_tokens` and `LiveTokens` polling in PdfCraft.
   - `build.sh`: Rebuild script from upstream Git repository.
   - `install.sh`: Instant one-line extraction and system registration.

---

## 2. Restoring on a Fresh Omarchy Setup

Restoring takes seconds from the repository root:

```bash
./restore.sh
```

Or manually install PdfCraft standalone:

```bash
apps/pdfcraft/install.sh
```

---

## 3. Rebuilding from Source (Optional)

If you ever wish to recompile from source using Rust:

```bash
apps/pdfcraft/build.sh
```
