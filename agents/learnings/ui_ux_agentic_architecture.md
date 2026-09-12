# Compound Learning: UI/UX Agentic Architecture, Background Reference Deconstruction & Dual-Tier Review Swarm

## Context
When routing user UI/UX design requests in Omagent with attached reference images, earlier designs suffered from ordering anomalies (Grill-Me questions appearing before UI archetype selection), blocking delays during reference analysis, and review failures when non-vision models (e.g. GLM 5.3 Flash or DeepSeek v4 Flash) could not inspect screenshots.

## Canonical 3-Turn Interaction Pattern
1. **Turn 1 (Archetype Presentation + Detached Background Decoding)**:
   - User inputs prompt + image.
   - The UI Archetype Selection Menu (`Set 1`, `Set 2`, `Set 3`) is presented FIRST.
   - In the background, `start_background_ref_analysis` launches a detached daemon process via `subprocess.Popen([sys.executable, str(router), "--deconstruct-ref", ...], start_new_session=True)` to decode the image's palette, contrast, and tone without blocking the UI.
   - Saves output to `/home/soham/.local/state/omagent/sessions/<session_id>.ref_analysis.json`.
2. **Turn 2 (Cached Deconstruction Pickup + Harmonized Grill-Me)**:
   - User replies with `1`, `2`, or `3`.
   - The router loads the cached `ref_analysis.json` with 0ms latency, adapts the directives to the chosen UI set, and outputs Subagent 1's structured Markdown report.
   - Generates Round 1 Grill-Me questions that harmonize the reference's visual DNA with the chosen set:
     - Set 1: Emil Kowalski spring physics, magnetic cursor snap, caustics, and luxury finishes.
     - Set 2: SaaS operational workspace, telemetry tables, steppers, and state machines.
     - Set 3: Bespoke Three.js 3D centerpiece (strictly banning generic primitives).
3. **Turn 3 (Master Synthesis & Autonomous Herdr Swarm)**:
   - User answers Grill-Me questions.
   - Router compiles the Master Strategic Design Brief (`[GRILL-ME STRATEGIC DESIGN BRIEF — USER ALIGNED SPECIFICATIONS]`).
   - Provisions an isolated workspace at `~/Projects/<slug>` with `git init -b ui/<slug>` and `treehouse init`.
   - Spins up a 2x2 Herdr swarm:
     - Pane 1: Lead UI Architect (`lead_*`).
     - Pane 2: Motion, Shaders & 3D Specialist (`mot_*`).
     - Pane 3: DOM Components & Rigid Header Engineer (`dom_*`).
     - Pane 4: Adversarial Reviewer (`rev_*`).
   - Every subagent orientation delivers access to all 33 Compound Engineering skills (`ce-work`, `ce-plan`, `ce-debug`, `ce-ui-optimize`, `ce-compound`, etc.).

## Two-Tier Reviewer Protocol (Vision vs Non-Vision Models)
- **Vision Models (Gemini 2.5 Flash / Claude Sonnet)**:
  - Capture & visually inspect `omagent-screenshot <url_or_path> preview.png`.
- **Non-Vision Models (GLM 5.3 Flash / DeepSeek v4 Flash)**:
  - Directly audit source code for rigid layout rules (`white-space: nowrap !important;` on nav links, centered baselines, frosted backdrops) and syntax validity.
- **Incremental Audits**: Reviewer verifies individual components as they are produced.
- **Holistic Remediation Loop**: Reviewer checks the fully assembled page; if anything feels clunky or defective, Reviewer prompts the subagent to remediate before declaring complete.

## Canonical Specification Files
- Rules Specification: `/home/soham/.agents/rules/ui-ux-architecture.md`
- Plugin Architecture: `/home/soham/.config/omarchy/plugins/io.github.ellion369.omagent/ARCHITECTURE_UI_UX.md`
- Implementation Engine: `/home/soham/.config/omarchy/plugins/io.github.ellion369.omagent/omagent-route`
