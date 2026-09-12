# UI/UX Agentic Architecture & Multi-Subagent Fleet Orchestration

> **Permanent System Specification & Protocol**  
> This document defines the canonical architecture for all UI/UX design, visual reference deconstruction, interactive strategic alignment (Grill-Me), multi-subagent Herdr fleet orchestration, dual-tier visual review, and worktree isolation on Omarchy Linux.

---

## 1. Architectural Overview & Workflow Lifecycle

Whenever a user initiates a UI/UX or web design request in Omagent (or CLI), the system intelligently bifurcates based on whether a visual reference image is attached, eliminating style collisions while preserving user intent:

```
                            ┌──────────────────────────────────────────────────┐
                            │               User submits Request               │
                            └────────────────────────┬─────────────────────────┘
                                                     │
                             Does request include an attached Reference Image?
                                                     │
                        ┌────────────────────────────┴────────────────────────────┐
                        ▼ YES                                                     ▼ NO
          ┌─────────────────────────────────────────┐               ┌─────────────────────────────────────────┐
          │ TRACK A: Non-Invasive Reference Fidelity│               │ TRACK B: Archetype Selection Menu       │
          │ • BYPASS Set 1/2/3 selection completely │               │ • Present UI Archetype Menu to User:    │
          │ • Automatically bind to Set 4:          │               │   1. Set 1: Full Aesthetic (Linear)     │
          │   IMPECCABLE (/home/soham/Ui-skills/    │               │   2. Set 2: SaaS / Platform (Density)   │
          │   impeccable)                           │               │   3. Set 3: Jaw-Dropping 3D (WebGL)     │
          │ • Deconstruct Reference Image (Subagent │               │ • Wait for user selection in chat       │
          │   1: colors, lighting, cadence)         │               └────────────────────┬────────────────────┘
          │ • Jump DIRECTLY to Grill-Me Alignment   │                                    │ User chooses Set
          └────────────────────┬────────────────────┘                                    ▼
                               │                                    ┌─────────────────────────────────────────┐
                               │                                    │ Background Ref Analysis (if applicable) │
                               │                                    │ Caches ref_analysis.json & starts Grill │
                               │                                    └────────────────────┬────────────────────┘
                               │                                                         │
                               └────────────────────────────┬────────────────────────────┘
                                                            ▼
          ┌───────────────────────────────────────────────────────────────────────────────────┐
          │ INTERACTIVE GRILL-ME STRATEGIC ALIGNMENT (Progressive Deep-Drilling)              │
          │ • Round 1: Reference Essence & Tonal Translation / Thematic Centerpiece           │
          │ • Round 2: Kinetic Physics & Micro-Affordances                                    │
          │ • Round 3: Header Architecture & Conversion UX (Strict Non-Wrapping Navigation)   │
          │ • Round 4: Atmospheric Depth, Shaders & Background Sound/Sensory Cues             │
          │ • Round 5: Typography Pairing, Font Hierarchy & Contrast Rhythms                  │
          │ • Rounds 6+: Theme Mode Synchronization, Squircle Radii, Negative Space           │
          │ *(User may reply with options, or type `proceed` at any time to build immediately)*│
          └─────────────────────────────────────────┬─────────────────────────────────────────┘
                                                    │ User finishes Grill-Me (or types `proceed`)
                                                    ▼
          ┌───────────────────────────────────────────────────────────────────────────────────┐
          │ MASTER SYNTHESIS & HERDR 2x2 MULTI-SUBAGENT FLEET PROVISIONING                     │
          │ • Firstmate compiles Master Strategic Design Brief & saves to session history     │
          │ • Persists visual reference intelligence to `solutions/reference_design_language.md`│
          │ • Provisions dedicated git branch & Treehouse worktree at `~/Projects/<slug>`     │
          │ • Configures 2x2 grid in Herdr terminal multiplexer for 4 specialized subagents   │
          └─────────────────────────────────────────┬─────────────────────────────────────────┘
                                                    │
                                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ HERDR MULTI-SUBAGENT SWARM (Pane 1: Lead · Pane 2: Motion · Pane 3: DOM · Pane 4: Reviewer)         │
│                                                                                                     │
│  ★ FOR REFERENCE IMAGES (SET 4 - IMPECCABLE):                                                       │
│    - Pane 1 (Lead UI Architect): `impeccable` (Non-invasive reference translation & master layout)  │
│    - Pane 2 (Motion & Craft): `animate` (Fluid spring physics & non-blocking transitions)           │
│    - Pane 3 (DOM & Reference Fidelity): `apple-design` (Rigid non-wrapping navbar & layout cadence) │
│    - Pane 4 (Adversarial Reviewer): `impeccable` (Audit reference DNA preservation & anti-copying)  │
│                                                                                                     │
│  ★ ON-DEMAND SKILL AUTONOMY: Every subagent orientation delivers access to all 33 Compound          │
│    Engineering skills (ce-work, ce-plan, ce-debug, ce-ui-optimize, ce-compound, treehouse).          │
│                                                                                                     │
│  ★ TWO-TIER ADVERSARIAL REVIEWER PROTOCOL:                                                          │
│    1. Incremental Deliverable Audits:                                                               │
│       - Vision Models (Gemini 2.5 Flash / Claude Sonnet): inspects omagent-screenshot.              │
│       - Non-Vision Models (GLM 5.3 Flash / DeepSeek v4 Flash): audits syntax, tokens, and          │
│         rigid CSS layout rules ('white-space: nowrap !important;').                                 │
│    2. Holistic Assembly Audit & Remediation Loop:                                                   │
│       - Reviewer audits fully assembled project; if anything feels clunky or defective,             │
│         Reviewer prompts the responsible subagent with actionable remediation before concluding.    │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Bifurcated UI Routing: Preventing Style Collision

### 2.1 The Style Collision Problem & Non-Invasive Solution
When a user uploads a reference image, their visual intent is already embodied in the image (e.g. a minimalist luxury lookbook, a bespoke brutalist portfolio, or an organic warm-paper editorial). Asking the user to pick between Set 1 (Linear/Swiss), Set 2 (SaaS Dashboards), or Set 3 (Awwwards 3D WebGL) forces preconceived, rigid archetypes that **collide directly** with the design philosophy of the reference image.

### 2.2 Routing Decision Logic
1. **When a Reference Image IS Attached (`image_path` provided)**:
   - **Bypass Set 1/2/3 selection completely**. Do NOT ask the user to pick an archetype.
   - **Auto-Bind to Set 4 (`impeccable`)**: The router locks `ui_set = 4`, backed by `/home/soham/Ui-skills/impeccable` (symlinked into `/home/soham/.agents/skills/impeccable`).
   - **Impeccable Non-Invasive Philosophy**:
     - *"The brief wins. Honor pinned aesthetics, eras, materials, fonts, and palettes... Refinement preserves; redesign replaces... Visual authority is evidence."*
     - Impeccable does NOT force arbitrary 3D geometry or generic dashboard tables onto the design.
     - It elevates details, alignment, typography tension, and responsiveness while honoring the soul of the reference image.
   - **Immediate Strategic Alignment**: The system deconstructs the reference image and immediately outputs the Round 1 Grill-Me strategic questions tailored to the reference and Impeccable craft.

2. **When NO Reference Image IS Attached**:
   - The router presents the standard 3-option UI Archetype Menu:
     - **Option 1: Full Aesthetic (`Set 1`)** — Linear / Stripe Press craft, Swiss typography, Braun minimalism.
     - **Option 2: SaaS / Product App (`Set 2`)** — High-density dashboards, data tables, state machines, WCAG AA.
     - **Option 3: Jaw-Dropping / 3D Showcase (`Set 3`)** — Three.js WebGL 3D worlds, shaders, GSAP + Lenis kinetic motion.
   - The user selects `1`, `2`, or `3`, and the system proceeds to Grill-Me.

---

## 3. Subagent 1: Visual Reference Image Deconstruction

When a reference image is provided, Subagent 1 performs mathematical and visual deconstruction with strict anti-copying enforcement:
1. **Geometric & Viewport Profile**: Resolution (`width x height`), aspect ratio (`16:9`, `4:3`, `1:1`, `9:16`), image format.
2. **Chromatic Hierarchy**:
   - Base canvas color (`#hex`) and light/dark theme luminance calculation.
   - Dominant tonal chords and palette summary.
   - High-contrast accent strike color (`#hex`).
3. **Typographic Character**: Display serif vs. grotesque sans, optical sizing, and baseline rhythm.
4. **Spatial Cadence**: Proportional negative space, asymmetric balance, grid density.
5. **Materiality & Surface Finishes**: Frosted glass (`backdrop-filter: blur(24px)`), hairline borders, caustics, noise grain.
6. **Strict Anti-Copying Mandate**:
   - All artwork, SVGs, 3D meshes, copy, and layout structures must be 100% original bespoke adaptations.
   - Zero literal copying or pasting of reference design assets.

The complete deconstruction report is saved to `solutions/reference_design_language.md` in the project root so all fleet subagents can inspect it at any time.

---

## 4. Interactive Grill-Me Session Engine

The Grill-Me session ensures alignment between user goals and autonomous build execution:
- **Round 1**: Visual Reference Adaptation & Brand Essence (tailored to Impeccable or chosen UI Set).
- **Round 2**: Kinetic Physics & Micro-Affordances.
- **Round 3**: Header Architecture & Navigation UX (enforcing zero line-wrapping header laws).
- **Round 4**: Atmospheric Depth & Background Craft.
- **Round 5**: Typography Pairing, Font Hierarchy & Contrast Scales.
- **Deep Rounds 6+**: Theme Mode Synchronization, Component Curvature, Spacing Multipliers.
- **User Control**: The user can reply with choices (e.g. `1, 1, 1`), request adjustments, or type `proceed` at any time to immediately conclude questioning and launch the autonomous build.

---

## 5. Herdr Multi-Subagent Fleet (2x2 Swarm Orchestration)

When building commences, Firstmate provisions a specialized multi-agent crew across 4 Herdr panes:

```
+------------------------------------+------------------------------------+
| Pane 1 (Top-Left):                 | Pane 2 (Top-Right):                |
| 🏛️ Lead UI Architect & Scaffolder  | 🎨 Motion & Craft Specialist       |
| Role: lead-architect               | Role: motion-and-craft-specialist  |
| Skill: impeccable (Set 4)          | Skill: animate                     |
+------------------------------------+------------------------------------+
| Pane 3 (Bottom-Left):              | Pane 4 (Bottom-Right):             |
| 📐 Reference Fidelity Engineer     | 🛡️ Adversarial Reviewer & Auditor  |
| Role: reference-fidelity-engineer  | Role: visual-reference-reviewer    |
| Skill: apple-design                | Skill: impeccable                  |
+------------------------------------+------------------------------------+
```

### 5.1 Fleet Roles by Active UI Set
| Pane | Set 4 (Impeccable / Ref Image) | Set 1 (Full Aesthetic) | Set 2 (SaaS / Platform) | Set 3 (Jaw-Dropping 3D) |
|---|---|---|---|---|
| **Pane 1 (Lead)** | Lead UI Architect (`impeccable`) | Lead UI Architect (`web-design-engineer`) | Lead UI Architect (`ui-design`) | Lead UI Architect (`build-awwwards-quality-sites`) |
| **Pane 2 (Motion)** | Motion & Craft (`animate`) | Motion Specialist (`animate`) | Interaction UX (`interaction-design`) | 3D & Shaders (`build-threejs-scroll-worlds`) |
| **Pane 3 (DOM)** | Reference Fidelity (`apple-design`) | Swiss Typography (`visual-hierarchy`) | Design Systems (`design-systems`) | Rigid Header (`layout-grid`) |
| **Pane 4 (Review)** | Impeccable Reviewer (`impeccable`) | Craft Reviewer (`review-animations`) | Density Reviewer (`accessibility-audit`) | Anti-Slop Reviewer (`no-ai-design-slop`) |

### 5.2 Autonomous Compound Engineering Skill Access
Every subagent receives an orientation message (`001_orientation.msg`) granting full on-demand authority to use any of the 33 Compound Engineering skills:
- **Scoping & Plans**: `ce-plan`, `ce-brainstorm`, `ce-strategy`
- **Implementation**: `ce-work`, `ce-prototype`
- **Diagnosis & Tests**: `ce-debug`, `ce-test-browser`, `diagnose-crash`
- **Review & Merges**: `ce-code-review`, `no-mistakes`, `no-ai-design-slop`
- **Optimization**: `ce-optimize`, `ce-ui-optimize`
- **Simplification**: `ce-simplify-code`
- **Compounding**: `ce-compound` -> saved to `solutions/<problem-slug>.md`
- **Safe Commits**: `ce-commit`, `ce-commit-push-pr`

---

## 6. Two-Tier Reviewer Protocol & Defect Remediation Loop

The Reviewer subagent in Pane 4 enforces a two-tier verification process tailored to model capabilities:

### 6.1 Dual-Model Inspection Logic
- **Vision-Capable Models** (Gemini 2.5 Flash, Claude 3.7 Sonnet):
  - Captures rendered screens using `omagent-screenshot <url_or_path> preview.png`.
  - Visually inspects typography, whitespace breathing room, non-wrapping headers, contrast compliance, and element alignment.
- **Non-Vision / Free Flash Models** (GLM 5.3 Flash, DeepSeek v4 Flash):
  - Directly audits source code:
    - **Rigid Layout Rules**: Enforces `white-space: nowrap !important;` on `.nav-links li` and `.nav-link`.
    - **Header Alignment**: Enforces `display: flex; align-items: center;` centered baselines.
    - **Frosted Backdrop**: Enforces `backdrop-filter: blur(24px);` with non-transparent solid background on scroll.
    - **Syntax & Tokens**: Validates syntax, design token consistency, and anti-copying adherence.

### 6.2 Incremental Deliverable Audits & Remediation Loop
- As each subagent completes an individual component, the Reviewer verifies the deliverable immediately.
- Once all subagents finish, the Reviewer conducts a comprehensive holistic audit of the assembled page.
- If defects or lack of craft are detected, Reviewer sends actionable remediation prompts via Firstmate:
  ```bash
  firstmate send <task_id> 'Fix defect: ...'
  ```
- Subagent repairs the defect; Reviewer re-audits before declaring done.

---

## 7. Strict Non-Negotiable Frontend Quality Standards

Every UI created on this system must strictly satisfy:
1. **Single-Line Non-Wrapping Navigation**:
   - `white-space: nowrap !important;` on all navigation items.
   - Flawless vertical center alignment (`display: flex; align-items: center;`).
   - Frosted glass backdrop (`backdrop-filter: blur(24px)`).
2. **Thematic 3D / Centerpiece Law (Set 3)**:
   - ZERO generic primitives (banned: floating torus knots, metallic pretzels, generic cubes/spheres).
   - Must visually narrate the exact subject domain of the client.
3. **Reference Image Fidelity (Set 4)**:
   - Preserve tonal chords, contrast ratios, and layout geometry non-invasively.
4. **Anti-Copying Mandate**:
   - Abstract principles and aesthetic chords; zero literal plagiarism of geometry, SVGs, or copy.
5. **Mandatory Post-UI Animation Pass**:
   - Only animate `transform` and `opacity`.
   - Organic easing curves (`cubic-bezier(0.16, 1, 0.3, 1)`), sub-300ms durations.
   - Tactile press feedback (`:active:scale(0.96)`).

---

## 8. File & State Registry

- **Main Router Engine**: `/home/soham/.config/omarchy/plugins/io.github.ellion369.omagent/omagent-route`
- **Omagent UI Overlay**: `/home/soham/.config/omarchy/plugins/io.github.ellion369.omagent/Omagent.qml`
- **Session State Storage**: `/home/soham/.local/state/omagent/sessions/`
  - `<session_id>.ui_pending.json`: Pending UI set choice
  - `<session_id>.ref_analysis.json`: Cached background reference deconstruction
  - `<session_id>.grill_me.json`: Active Grill-Me session state and locked decisions
  - `<session_id>.uiset.json`: Persistent locked UI set
  - `<session_id>.fleet.json`: Herdr pane IDs and Firstmate task IDs
- **UI Skills Libraries**:
  - `/home/soham/Ui-skills/Set1` (Linear / Stripe Press craft)
  - `/home/soham/Ui-skills/Set2` (SaaS / Platform design systems)
  - `/home/soham/Ui-skills/set3` (Awwwards 3D WebGL & kinetic motion)
  - `/home/soham/Ui-skills/impeccable` (Non-invasive reference alignment & craft)
- **Compound Engineering Skills**: `/home/soham/.agents/skills/`
