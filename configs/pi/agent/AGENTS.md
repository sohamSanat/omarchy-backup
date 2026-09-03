# Agent Guidelines & Workflow Integration

## AXI Tooling Standards
When interacting with external services or development operations, always prefer token-efficient AXI (Agent eXperience Interface) tools over verbose standard CLIs or heavy MCP servers:
- **GitHub Operations**: Use `gh-axi` instead of standard `gh` or GitHub MCP (saves 40-60% tokens with TOON output).
- **Browser Automation**: Use `chrome-devtools-axi` instead of verbose browser MCPs.
- **Task & Backlog Tracking**: Use `tasks-axi` for tracking project tasks and backlog states.
- **Model Quotas & Limits**: Use `quota-axi` to inspect active token windows, rate limits, and spend across models.
- **Human Review**: Use `lavish-axi` to turn HTML artifacts into interactive feedback boards.
- **Safe Merges & Auto-Verification**: Use `no-mistakes` for verified git branch merges.

## Omarchy Linux System Guidelines
- **Operating System**: Omarchy Linux (Arch Linux + Hyprland).
- **Critical Safety Rule**: NEVER edit or write to `/usr/share/omarchy/` (it is read-only and wiped on update).
- **User Customization**: Always write user configuration to `~/.config/` (e.g. `~/.config/hypr/`, `~/.config/omarchy/`, `~/.config/herdr/`).
- **CLI Management**: Always use the official `omarchy` CLI (`omarchy theme set`, `omarchy bar`, `omarchy plugin`, `omarchy refresh`, etc.).

## Multi-Agent Architecture & Coordination
- **Herdr Terminal Multiplexer**: Integrated via `~/.config/herdr/config.toml` (prefix: `Ctrl+Space`). Use Herdr panes, tabs, and workspaces for multitasking.
- **Firstmate Fleet Manager**: Dispatch and coordinate tasks via `firstmate` (`fm status`, `firstmate send`, `firstmate launch`).
- **Treehouse Worktree Manager**: Use `treehouse` for isolated parallel git worktrees (`treehouse get`, `treehouse return`).
- **Compound Engineering Suite**: Specialized workflows available in skills (`ce-brainstorm`, `ce-plan`, `ce-work`, `ce-code-review`, `ce-debug`, `lfg`).
