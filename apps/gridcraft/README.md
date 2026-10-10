# GridCraft — Omarchy Linux Full App Build & Integration

Full application build, configuration, desktop integration, and live dynamic theming pipeline for [GridCraft](https://github.com/storytold/gridcraft) (v0.3.0) on Omarchy Linux.

---

## 1. What is Backed Up

1. **Precompiled Release Build Bundle** (`build/gridcraft-linux-x86_64.tar.xz` ~11 MB):
   - `gridcraft.real`: Optimized release GUI binary (pure Rust, egui 0.36 + wgpu).
   - `gridcraft-cli`: Headless calculation engine, file converter, formula evaluator, and stdio Model Context Protocol (MCP) server.
   - `gridcraft`: Launcher wrapper configuring loopback JSON-lines control port (`7981`), XWayland/Wayland flags, and automatic initial theme generation.
   - `omarchy-sync-gridcraft`: Python theme synthesis engine converting Omarchy's active `colors.toml` palette into `~/.config/gridcraft/theme.json` and `ui.json` for live 400ms hot-reloads.
2. **Desktop Integration & Assets**:
   - `desktop-entries/ai.storyteller.gridcraft.desktop`: Freedesktop application entry with MIME associations and Native Wayland desktop action.
   - `icons/hicolor/`: Complete suite of scalable SVG and raster icons (`16x16` up to `512x512`).
   - `mime/ai.storyteller.gridcraft.xml`: XML database definitions for spreadsheet formats (`.xlsx`, `.xlsm`, `.csv`, `.tsv`).
3. **Configurations & Engine State**:
   - `configs/gridcraft/ui.json`: egui dark mode, formula bar visibility, and ribbon tabs.
   - `configs/gridcraft/theme.json`: Real-time token mapping specification.
4. **Omarchy Hook**:
   - `configs/omarchy/hooks/theme-set.d/gridcraft-sync.sh`: Auto-dispatched on every `omarchy theme set <name>` to repaint the GUI without restarts.
5. **Model Context Protocol (MCP) Server**:
   - `mcp/gridcraft/`: JSON tool schemas (21 tools: `read_range`, `write_range`, `set_cell`, `get_cell`, `evaluate_formula`, `format_range`, `insert_chart`, `inspect_workbook`, etc.) and instructions for AI agents.
6. **System Reproducibility**:
   - `install.sh`: Instant one-line extraction and system registration.

---

## 2. Restoring on a Fresh Omarchy Setup

Restoring takes 2 seconds from the repository root:

```bash
./restore.sh
```

Or manually install GridCraft standalone:

```bash
apps/gridcraft/install.sh
```
