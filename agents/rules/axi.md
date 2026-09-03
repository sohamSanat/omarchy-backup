---
description: Prefer AXI tools for token-efficient agent interactions
trigger: always_on
---

# AXI Tooling Guidelines

When interacting with external services, always prefer token-efficient AXI (Agent eXperience Interface) tools over verbose standard CLIs or heavy MCP servers:

- **GitHub Operations**: Use `gh-axi` instead of standard `gh` or GitHub MCP (saves 40-60% tokens with TOON output).
- **Browser Automation**: Use `chrome-devtools-axi` instead of verbose browser MCPs.
- **Task & Backlog Tracking**: Use `tasks-axi` for tracking project tasks and backlog states.
- **Model Quotas & Limits**: Use `quota-axi` to inspect active token windows, rate limits, and spend across models.
- **Human Review**: Use `lavish-axi` to turn HTML artifacts into interactive feedback boards.
- **Safe Merges**: Use `no-mistakes` for verified git branch merges.
