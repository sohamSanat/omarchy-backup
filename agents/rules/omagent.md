# Omagent & Jarvis System Profile

You are operating on **Omarchy Linux** as part of the **Omagent / Jarvis** intelligent agent ecosystem.

## Environment & Tooling Stack
- **Desktop Host**: Omarchy Linux, integrated with Quickshell desktop overlays and mobile companion interfaces.
- **Terminal Multiplexer (Herdr)**: Background agent workspaces and persistent terminal panes are managed via `herdr` (`/usr/bin/herdr`).
- **Fleet Supervision (Firstmate)**: Multi-agent coordination and parallel crew orchestration are supervised via `firstmate` (`/home/soham/.local/bin/firstmate`).
- **Worktree Isolation (Treehouse)**: Isolated Git feature branches and worktrees are managed via `treehouse` (`/home/soham/.local/bin/treehouse`). Use `treehouse status` and `treehouse get <branch>` to prevent dirty-state collisions during multi-agent workflows.
- **Autonomous Coding Harness (Antigravity CLI / agy)**: Running on Gemini 3.8 Flash High backed by Google AI Pro subscription (`agy`).
- **Compound Engineering Skills**: 33 specialized methodologies located in `~/.agents/skills/` (including `ce-work`, `ce-plan`, `ce-debug`, `ce-code-review`, `ce-simplify-code`, `ce-compound`, `lfg`, `ce-commit-push-pr`, `ce-brainstorm`, `diagnose-crash`, `axi`, `treehouse`, `firstmate`, `herdr`, etc.). Follow their phased checklists for all engineering tasks.
- **Agent eXperience Interface (AXI)**: Standard token-efficient CLIs:
  - `gh-axi`: GitHub operations with TOON output (saves 40-60% tokens).
  - `chrome-devtools-axi`: Fast browser automation and inspection.
  - `tasks-axi`: Project task and backlog tracking.
  - `quota-axi`: Token window and rate limit inspector.
  - `lavish-axi`: Rich interactive HTML review boards for user feedback.
  - `no-mistakes`: Verified safe git merges.
- **Omarchy Theming & Text Contrast**: Respect `$OMARCHY_THEME_MODE` at all times. On light backgrounds, never use white, light gray, or washed-out text; use high-contrast dark text and deep saturated accents.
- **UI Sets & Supreme Precedence Over Compound Engineering**: Follow `/home/soham/.agents/rules/ui-sets.md` whenever building frontend/UI. Strictly enforce the user-selected UI Set (Set 1: Full Aesthetic, Set 2: SaaS / Systems, Set 3: 3D / Kinetic). Whenever any kind of UI is being made, the skills of the UI Set and their associated Animation Skills **COMPLETELY OVERRIDE** Compound Engineering skills in all visual, design, layout, typographic, component, and animation decisions. Compound Engineering skills act strictly as the software engineering harness (worktrees, planning, browser QA, code simplification, and compounding learnings). Always execute the two-phase protocol: first construct the complete UI with all subagents, THEN launch the dedicated animation workflow (`find-animation-opportunities` -> `animate` / `apple-design` / `gsap` -> `review-animations`).

