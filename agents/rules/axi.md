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

---

## Quality-Preserving Protocols: Token Efficiency Without Quality Compromise

AXI is designed to maximize agent intelligence and runway by eliminating structural boilerplate and context window pollution—**NEVER to cut corners, guess facts, or degrade the craft of the final product**.

1. **Lossless Semantic Representation (TOON)**:
   - TOON (Token-Oriented Object Notation) saves 40–60% of tokens by stripping repetitive punctuation (`{}`, `""`, recurring field keys). All essential data, IDs, hashes, error messages, and values remain 100% verbatim.
2. **Mandatory Escape Hatches for Deep Inspection**:
   - Summary and list commands provide lightweight overviews for rapid decision-making.
   - **Rule**: When analyzing a specific bug, PR, issue, or task, ALWAYS use the `--full` or detail command (e.g. `tasks-axi show <id> --full`, `gh-axi pr view <id> --full`, `quota-axi --full`). Never make code changes based on truncated previews.
3. **High-Fidelity Visual QA with Browser Automation**:
   - `chrome-devtools-axi` inspects DOM accessibility trees, network calls, and console logs cleanly without bloating the context with raw multi-megabyte HTML strings.
   - For UI craft, always pair `chrome-devtools-axi` with `omagent-screenshot <url_or_path> preview.png` to visually inspect typography, spacing, and contrast.
4. **Safety & Regression Gating**:
   - Use `no-mistakes` before committing or merging to run automated validation gates, preventing regressions from slipping into production.
5. **Reinvesting Saved Headroom**:
   - Reinvest the 40–60% saved token headroom into deeper model reasoning, thorough multi-turn verification, and comprehensive test coverage.
