# UI Sets & Mandatory Post-UI Animation Protocol

When designing, scaffolding, or implementing any user interface, frontend, webpage, or web/mobile application on this system, you and all subagents MUST strictly adhere to this two-phase protocol and honor the chosen UI Skill Set.

---

## Supreme Precedence Hierarchy: UI Skills Override Compound Engineering for All UI Tasks

Whenever ANY kind of user interface, frontend, webpage, app, dashboard, landing page, or visual component is being designed, scaffolded, styled, or animated:

1. **Supreme Authority of UI Set & Animation Skills**:
   The active UI Set (Set 1: Full Aesthetic, Set 2: SaaS / Product App, or Set 3: Jaw-Dropping / 3D Showcase) and its associated `Animations-skills` **COMPLETELY OVERRIDE** all generic Compound Engineering skills in the UI domain. No generic styling, generic CSS templates, or non-UI-set aesthetics may be applied.

2. **Strict Division of Responsibility**:
   - **UI Set Skills & Animation Skills (100% Control over Aesthetics & Motion)**:
     - **Visual Style & Identity**: Governed by the active set's lead skill (`web-design-engineer`, `ui-design`, or `build-awwwards-quality-sites`).
     - **Typography, Hierarchy & Palette**: Swiss typography, Stripe/Linear recipes, tokenized scales, WCAG AA contrast compliance, and Omarchy theme adaptation.
     - **Layout Architecture**: High-density tables, asymmetry, cards, responsive grids.
     - **3D & Shaders (Set 3)**: Three.js WebGL scenes, GLSL shaders, camera journeys, and Lenis virtual smooth scroll.
     - **Motion Physics & Micro-Interactions**: Governed by `Animations-skills` (`animate`, `apple-design`, `gsap`, `review-animations`). GPU-accelerated transforms (`transform`, `opacity`), snappy `:active:scale(0.96)` press compression, spring physics, and sub-300ms responsive transitions.
   - **Compound Engineering Skills (100% Control over the Engineering Harness)**:
     - **Upstream Scoping & Planning**: Formulating clean implementation plans via `ce-plan` or `ce-brainstorm` before touching code.
     - **Git Isolation**: Managing isolated branches and worktrees with `treehouse` and `ce-worktree`.
     - **Visual & Browser Verification**: Running headless browser tests and DOM inspection with `ce-test-browser` and `omagent-screenshot`.
     - **Code Simplification**: Deduplicating and cleaning up code after settle via `ce-simplify-code` while strictly preserving UI appearance.
     - **Institutional Learning**: Saving non-obvious engineering solutions and token conventions to `solutions/<problem-slug>.md` via `ce-compound`.
     - **Safe Git Shipping**: Creating value-communicating commits and verified merges via `ce-commit`, `ce-commit-push-pr`, and `no-mistakes`.

3. **Adversarial Reviewer Delegation**:
   During UI tasks, the Firstmate adversarial reviewer in Herdr is delegated to the specialized UI/motion reviewer rather than a generic reviewer:
   - **Set 1**: `review-animations` + `apple-design` (Motion and craft review).
   - **Set 2**: `visual-critique` + `accessibility-audit` (Design systems and WCAG review).
   - **Set 3**: `no-ai-design-slop` + `audit-ai-design-slop` (Anti-slop and kinetic review).
   - **Set 4**: `impeccable` + `review-animations` (Visual reference fidelity and craft review).

---

## The 4 UI Skill Sets

The user has 4 specialized UI skill sets configured at `/home/soham/Ui-skills/`:

### 1. Set 1: Full Aesthetic (Brand & Editorial Craft)
- **Primary Source**: `/home/soham/Ui-skills/Set1/`
- **Lead Skill**: `web-design-engineer` (`/home/soham/Ui-skills/Set1/garden-skills/skills/web-design-engineer`)
- **Style Recipes**: Linear, Stripe Press, Braun minimalism, Swiss typography (`/references/style-recipes/`).
- **Motion Philosophy**: Emil Kowalski animation craft (`/home/soham/Ui-skills/Set1/Animations-skills/skills/`).
- **Best For**: Iconic brand identities, luxury products, boutique landing pages, editorial craft.

### 2. Set 2: SaaS / Product App (High-Density Platform & Design Systems)
- **Primary Source**: `/home/soham/Ui-skills/Set2/`
- **Lead Skill**: `ui-design` (`/home/soham/Ui-skills/Set2/designer-skills/ui-design/skills/visual-hierarchy`)
- **Auxiliary Systems Skills**: `design-systems`, `interaction-design`, `form-design`, `loading-states`, `state-machine-ux`, `accessibility-audit`, `visual-critique`.
- **Motion Philosophy**: Functional state transitions, skeleton pulses, trigger-anchored dropdowns (`/home/soham/Ui-skills/Set2/Animations-skills/skills/`).
- **Best For**: Web & mobile SaaS applications, operational dashboards, analytics platforms, multi-step workflows.

### 3. Set 3: Jaw-Dropping / 3D Showcase (Awwwards & Kinetic Experience)
- **Primary Source**: `/home/soham/Ui-skills/set3/`
- **Lead Skill**: `build-awwwards-quality-sites` (`/home/soham/Ui-skills/set3/Skills/agent-skills/web-design/build-awwwards-quality-sites`)
- **Auxiliary Kinetic Skills**: `build-threejs-scroll-worlds`, `cinematic-gsap-lenis-motion-system`, `gsap-animation`, `add-shader-cursor-trail`, `cobejs`, `dither-background`, `threejs-landscape`, `no-ai-design-slop`.
- **Motion Philosophy**: Three.js WebGL 3D worlds, shaders, Lenis virtual smooth scroll, GSAP kinetic choreographies, plus tactile DOM animation standards (`/home/soham/Ui-skills/set3/Animations-skills/skills/`).
- **Best For**: Awwwards-level interactive showcases, 3D product launches, creative agency portfolios, immersive storytelling.

### 4. Set 4: Impeccable Visual Reference Alignment (Non-Invasive Reference Fidelity & Craft)
- **Primary Source**: `/home/soham/Ui-skills/impeccable/` (symlinked at `/home/soham/.agents/skills/impeccable`)
- **Lead Skill**: `impeccable`
- **Auxiliary Craft Skills**: `animate`, `apple-design`, `review-animations`, `no-ai-design-slop`.
- **Core Philosophy**: Non-invasive fidelity ("The brief wins. Honor pinned aesthetics, eras, materials, fonts, and palettes... Refinement preserves; redesign replaces... Visual authority is evidence.").
- **Trigger**: Automatically bound whenever a reference image is attached (bypassing Set 1, 2, or 3 selection to prevent archetype collision).
- **Best For**: UI projects guided by visual reference images, bespoke luxury brands, out-of-distribution craft, zero style collisions.

---

## Non-Negotiable Header & Navigation Architecture Standards (All Sets)

The header is the highest-visibility interface element on any website. Agents frequently fail by leaving sloppy navigation defects. You and all subagents MUST enforce these strict standards on every header without exception:

1. **Strict Non-Wrapping Rule (`white-space: nowrap !important`)**:
   - Navigation links must **NEVER** wrap onto multiple lines (e.g. `THE` on one line and `MASTERS` below it).
   - Always apply `white-space: nowrap !important;` to `.nav-links li` and `.nav-link`.
   - Use sensible, responsive flex gaps (`gap: clamp(1.2rem, 2vw, 2.4rem);`) and test viewports from 1024px to 1440px.

2. **Flawless Center Baseline Alignment**:
   - All elements inside the header (brand mark, nav links, status pills, CTA button, hamburger toggle) must share a strict vertical center baseline (`display: flex; align-items: center;`).

3. **Absolute Ban on Operational Clutter in Primary Nav**:
   - **NEVER** jam opening hours, contact phone numbers, or raw telemetry badges into the primary desktop navigation bar.
   - Keep the navigation clean and editorial. Operational details belong in the footer, info drawer, or booking modal.

4. **Frosted Glass Backdrop Protection (Zero Background Bleed)**:
   - When using 3D WebGL scenes, particle canvases, or dark backgrounds, the header **MUST** have a dedicated frosted glass backdrop:
     `background: rgba(10, 11, 14, 0.78); backdrop-filter: blur(24px) saturate(180%); border-bottom: 1px solid rgba(200, 169, 126, 0.14);`
   - **NEVER** use a gradient that fades to transparent at the bottom of the header. Background 3D meshes or scrolling text must **NEVER** collide with or bleed behind nav items during scroll.
   - Provide a `.scrolled` state that tightens height and solidifies background on scroll.

5. **Theme-Cohesive Luxury CTA (No Default Slabs)**:
   - The primary navigation CTA button must be an architectural button designed with the project's accent palette (e.g. champagne gold gradient pill with subtle ambient glow and hover lift).
   - **NEVER** use an unstyled, stark white, or default boxy slab that looks like a placeholder button.

---

## Strict Thematic 3D & WebGL Laws (Set 3 — Absolute Ban on Generic Primitives)

1. **Zero-Tolerance Ban on Generic Three.js Primitives**:
   - **NEVER** use generic Three.js primitive shapes (`TorusKnotGeometry`, floating metallic pretzels, generic cubes, bouncing spheres, standard tutorial blobs). This is lazy AI slop and will be rejected immediately.

2. **The 3D Scene MUST Narrate the Real Subject and Tone**:
   - The 3D centerpiece or background atmosphere must be **custom-crafted to represent the specific industry, brand, and theme of the website**:
     - **Haircraft / Salon / Esthetics / Fashion**: Procedural flowing sculptural silk ribbons, hair strand fiber waves, anisotropic hair sheen (`sheen: 1.0`), precision scissor shear arcs.
     - **Architecture / Interior Design**: Volumetric structural wireframes, spatial CAD facades, isometric blueprint grids.
     - **Horology / Luxury Craft**: Precision mechanical gear trains, tourbillon escapements, faceted sapphire crystal caustics.
     - **Biotech / Health / Medicine**: Organic protein helices, molecular membrane fluid simulations, cellular lipid bilayers.
     - **Fintech / Data Platforms**: Dynamic vector flow fields, kinetic topographical value planes, crystalline cryptographic nodes.
     - **Audio / Sound Engineering**: Frequency waveform ribbons, acoustic resonance membranes, fluid sound wave ripples.

3. **Typographic Safe Zones (Never Obscure Headings)**:
   - 3D elements must live in the background or as a dedicated off-center stage centerpiece (e.g. anchored to the right side `x: 2.4` to balance left-aligned hero copy).
   - Use depth-of-field, camera angles, and atmospheric fog (`THREE.FogExp2`) so 3D elements **NEVER collide with, cross over, or sit directly behind primary headlines or body copy**. Contrast must remain 100% crisp.

---

## Mandatory Visual QA & Reverification Gate (Before Completion)

Agents MUST NOT declare a UI task complete without running visual reverification:
1. Capture screenshots using `omagent-screenshot <url> preview.png` (desktop: 1440x900, mobile: 375x812).
2. Inspect the rendered image against this Reverification Checklist:
   - [ ] **Navbar Reverification**: Are all nav links strictly single-line (`white-space: nowrap`)? Is vertical baseline centered? Does the CTA button match the theme's luxury tokens?
   - [ ] **3D Relevance Reverification**: Does the 3D element directly tell the story of the client's business, or is it a generic Three.js preset?
   - [ ] **Text Legibility Reverification**: Is the headline 100% readable with zero 3D collision? Does the header stay legible when scrolling over background elements?
   - [ ] **Mobile Reverification**: Does the mobile viewport display an elegant, unclipped header with a functioning menu toggle?

---

## Visual Reference Attachment & Subagent 1 Design Language Deconstruction Protocol

When the user attaches a reference image in Omagent (via the Agentic tab attachment button or `Ctrl+I`), this image represents the user's rough visual idea. The system and all subagents MUST follow this strict deconstruction and anti-copying pipeline:

### 1. Pre-Design Reference Ingestion & Subagent 1 Assignment
- Before any design or coding begins, the attached image is fed directly to Firstmate.
- Firstmate immediately provisions **Subagent 1: Visual Reference Analyst** (`ref_analyst`).
- Subagent 1's sole mission is to deeply inspect and deconstruct the visual design language of the input image:
  - **Color Harmony & Palette**: Background canvas luminance, dominant chords, and accent strike color (computed via exact pixel histogram and luminance metrics).
  - **Emotional Atmosphere**: Lighting temperature, luxury vs. technical tension, mood, and visual weight.
  - **Typographic Character**: Serif vs. grotesque sans, micro-labels, telemetry styling, and typographic scale.
  - **Spatial Cadence**: Asymmetric balance, negative space ratios, card density, and grid margins.
  - **Materiality & Surfaces**: Frosted glass, chromatic dispersion, noise grain, border glows, or procedural depth.

### 2. Hardcoded Anti-Copying Mandate (Strictly Enforced Across All Subagents)
- **Zero Literal Plagiarism**: Neither Subagent 1, the lead architect, nor any downstream subagent may ever copy-paste the whole design language, assets, 3D meshes, copy, or verbatim structure from the reference image.
- **Abstract Core Essence Only**: Subagents must abstract the underlying aesthetic principles—lighting temperature, palette harmony, and spatial cadence—while engineering a completely original, bespoke digital experience tailored specifically to the user's domain.
- **Checking Subagent Mandate**: The Adversarial Reviewer (`rev_*`) is hardcoded to audit the final build specifically against the reference image. If the implementation merely copied or cloned the reference layout, the reviewer MUST reject it and demand an original adaptation.

### 3. Conveyance to Firstmate & Knowledge Synthesis
- When Subagent 1 finishes its analysis, it conveys its complete structured report card back to Firstmate.
- Firstmate integrates all 3 pillars of knowledge:
  1. **Guiding Skill Engine**: The selected UI Set (Set 1, 2, or 3) and its animation rules.
  2. **Visual Reference Intelligence**: Subagent 1's deconstructed color chords, lighting, and spatial rhythms.
  3. **User Intent & Domain**: The user's prompt, industry domain, and functional requirements.
- Firstmate persists this intelligence to `solutions/reference_design_language.md` in the workspace, ensuring every active crewmate in Herdr has continuous access to the reference principles.

### 4. Reference-Aware Dynamic Grill-Me Integration
- Firstmate launches the interactive Grill-Me session, dynamically weaving Subagent 1's findings into Round 1:
  - Presents questions addressing the exact extracted palette, lighting balance, and translation directives.
  - Allows the user to choose how the reference's atmospheric essence will be adapted (e.g., atmospheric translation vs. high-contrast energy vs. materiality only).
- When grilling completes or creative freedom is granted, Firstmate launches the specialized parallel fleet armed with this unified brief.

---

## Mandatory Pre-Design Grill-Me Protocol (Interactive Alignment Before Code)

Before writing any UI code, launching subagents, or establishing component scaffolding, the system MUST conduct an interactive **Grill-Me session** directly with the user in the Omagent chat interface:

1. **Interactive Chat Experience**:
   - The user interacts directly in the Omagent UI chat box to make key architectural, aesthetic, kinetic, and conversion choices.
   - Slash command support: Triggerable via `/grill <prompt>` or `/grill-me <prompt>`, or automatically initiated whenever a UI creation request is received.

2. **Domain-Specific & Theme-Grounded (Zero Generic Placeholders)**:
   - Grill-Me questions MUST NOT be generic. They are dynamically generated to match the exact industry, domain, and concept of the project (e.g. Haircraft Atelier, Fintech/Crypto, AI/Robotics, B2B SaaS, Luxury Fashion, Architecture, Music/Sound, Health/Biotech, Gastronomy, Portfolio).
   - Set-Aware Dilemmas:
     - **Set 3**: Focuses on bespoke 3D Three.js centerpiece scenes (enforcing the strict ban on generic primitives).
     - **Set 1**: Focuses on high-aesthetic typographic tension, Swiss grid hierarchy, and editorial layout tone.
     - **Set 2**: Focuses on workspace telemetry density, filter architectures, and multi-step operational flows.

3. **Strictly 3 Curated Options per Question**:
   - Every question presented to the user MUST provide **EXACTLY 3 curated, evocative options** (Options 1, 2, and 3), each outlining the visual impact, interaction nuance, and technical implementation.

4. **Limitless Progressive Grilling Loop (As Many & As Detailed As Desired)**:
   - The user can continue grilling for as many rounds as they want to sculpt and refine every aesthetic, physical, and architectural nuance:
     - **Round 1**: Visual Identity, Brand DNA & Thematic Centerpiece (Three.js 3D WebGL / Editorial Grid / Workspace Topology)
     - **Round 2**: Kinetic Motion Choreography, Lenis Scroll Physics & Micro-Affordances
     - **Round 3**: Header / Navbar Architecture, Zero-Wrapping Layout & Navigation Ergonomics
     - **Round 4**: Atmospheric Background Depth, Shaders, Grain / Dither & Tactile Sensory Feedback
     - **Round 5**: Typography Hierarchy, Font Pairing, Leading/Tracking Rhythms & Contrast Scales
     - **Round 6**: Section Sequencing, Storytelling Flow & Pinned Narrative Beats
     - **Round 7**: Conversion Funnel Architecture, Modals, Micro-Copy & Form Friction Elimination
     - **Round 8**: Mobile Ergonomics, Touch Gestures, Bottom Sheets & Gyroscope Sensory Parallax
     - **Round 9**: Media Presentation, Visual Framing, Video Textures & Bespoke Cursor Dynamics
     - **Round 10**: 120fps Hardware Budgeting, Shaders/Canvas Fallbacks & Latency Masking
     - **Round 11**: Extreme Viewports: Ultra-Wide (21:9) to Compact (320px) Adaptability
     - **Round 12**: Micro-Delight, Brand Easter Eggs, Sound Cues, Zero-State & Error State Polish
     - **Round 13+ (Dynamic Deep Synthesis)**: Infinite parameter tuning cycling through material roughness/specular equations, spring stiffness/damping coefficients, backdrop blur saturation, keyboard focus trapping, mobile haptic timing, optimistic UI state machines, and micro-spacing curvature.
   - Natural language continuation triggers: The user can reply with `continue`, `more questions`, `drill deeper`, `dig deeper`, `ask more`, or `2` to keep grilling indefinitely.
   - At the end of every round, the Strategic Checkpoint clearly prompts the user whether to **Proceed to Build** or **Continue Grilling**.

5. **Amplified Understanding in the Master Design Brief**:
   - When the user chooses to proceed (or types `proceed`/`build`), all decisions across all completed rounds are synthesized into an exhaustive `[GRILL-ME STRATEGIC DESIGN BRIEF — USER ALIGNED SPECIFICATIONS]`.
   - The brief categorizes every locked directive, giving Firstmate, Compound Engineering, and all UI subagents an amplified, unambiguous understanding of the user's vision before a single line of code is written.

6. **Skip & Refusal Protocol (Zero Questioning After Skip + Full Creative Freedom)**:
   - If the user skips or refuses ANY question at any point during grilling (e.g. typing `skip`, `pass`, `refuse`, `i refuse`, `no`, `nah`, `you decide`, `creative freedom`, `do what you want`, `on your own accord`, `stop grilling`, `just build`, etc.):
     - **Cease Grilling Immediately**: From that point on, do **NOT** grill or question the user any further. Never ask for confirmation, clarification, or additional input.
     - **Full Creative Freedom Granted**: The agent and its specialized subagent fleet are empowered with complete creative freedom to make all remaining architectural, aesthetic, kinetic, and layout decisions on their own accord.
     - **Respect Prior Locked Choices**: Any decisions locked before the skip are strictly honored. All remaining elements are designed with bold, high-conviction mastery fitting the active UI Set.
     - **Immediate Build Transition**: The design brief is compiled with the explicit `★ MANDATORY CREATIVE FREEDOM MANDATE`, and the system immediately transitions into the autonomous build phase.

---

## Mandatory Multi-Subagent Fleet Protocol (Herdr 2x2 Swarm Orchestration)

The user has explicitly mandated using **as many specialized subagents as needed**: *"the more subagents you have working on a project, the better the project is going to turn out."*

When executing any UI or web engineering project, the system and all lead agents MUST assemble and orchestrate a specialized **4-to-5 subagent fleet** operating concurrently across Herdr panes:

```
+------------------------------------+------------------------------------+
| Pane 1 (Top-Left):                 | Pane 2 (Top-Right):                |
| 🏛️ Lead UI Architect & Scaffolding | 🎨 Motion, 3D WebGL & Shaders      |
| Role: lead-architect               | Role: motion-and-3d-specialist     |
| Skill: build-awwwards / ui-design  | Skill: build-threejs-scroll-worlds |
+------------------------------------+------------------------------------+
| Pane 3 (Bottom-Left):              | Pane 4 (Bottom-Right):             |
| 📐 DOM Components & Rigid Header   | 🛡️ Adversarial Anti-Slop Reviewer  |
| Role: dom-and-header-engineer      | Role: anti-slop-reviewer           |
| Skill: layout-grid / design-tokens | Skill: no-ai-design-slop           |
+------------------------------------+------------------------------------+
```

### 1. The Core 4 Specialized Subagent Roles:
1. **🏛️ Lead UI Architect & Systems Scaffolder** (`lead_...` in Pane 1):
   - Oversees project directory structure, HTML/DOM skeleton, global CSS variables, and coordinates work across crewmates.
   - Primary Skill: `build-awwwards-quality-sites` (Set 3), `ui-design` (Set 2), or `web-design-engineer` (Set 1).
2. **🎨 Motion, 3D WebGL & Interactive Dev** (`mot_...` in Pane 2):
   - Focuses exclusively on real-time Canvas/WebGL rendering, custom GLSL shaders, procedural math meshes (silk ribbons, caustics, CAD wireframes), GSAP ScrollTrigger choreographies, and Lenis smooth scroll.
   - Primary Skill: `build-threejs-scroll-worlds` (Set 3), `gsap-animation` (Set 2), or `animate` (Set 1).
3. **📐 DOM Components, Header & Responsive Layout Engineer** (`dom_...` in Pane 3):
   - Focuses exclusively on rigid single-line non-wrapping header architecture (`white-space: nowrap !important;`), frosted glass backdrops, typographic hierarchy, cards, booking modals, and responsive mobile drawers.
   - Primary Skill: `layout-grid` (Set 3), `design-systems` (Set 2), or `visual-hierarchy` (Set 1).
4. **🛡️ Adversarial Quality Reviewer & Anti-Slop Auditor** (`rev_...` in Pane 4):
   - Concurrently inspects code for AI clichés (banning generic cubes/toruses, bad gradients, cheesy cards, centered text spam), verifies navbar compliance, contrast ratios, and responsive breakpoints.
   - Primary Skill: `no-ai-design-slop` (Set 3), `accessibility-audit` (Set 2), or `review-animations` (Set 1).
5. **🧪 Visual QA & Browser Verification Tester** (On-Demand / Sibling):
   - Runs dev servers, executes headless browser tests with `ce-test-browser`, captures desktop (1440x900) and mobile (375x812) screenshots with `omagent-screenshot`, and visually validates rendering.

### 2. Mandatory Parallel Delegation Mandate:
- The Lead Architect MUST **NOT** work as a lone coder.
- The Lead Architect must aggressively delegate and coordinate with its specialized subagents via Firstmate:
  - Delegate 3D scene & motion: `firstmate send task_<sid>_mot 'Build bespoke 3D WebGL canvas scene...'`
  - Delegate header & layout: `firstmate send task_<sid>_dom 'Construct frosted glass navbar with white-space: nowrap links...'`
  - Prompt adversarial review before done: `firstmate subagent prompt rev_<sid> 'Audit implementation...' --wait`
- Additional subagents can be spawned on demand anytime via `firstmate subagent spawn <name> --role <role> --skill <skill> --task '<task>' [--wait]`.

### 3. On-Demand Subagent Compound Engineering Skills Access Protocol:
Every subagent in the fleet (Motion, DOM/Header, Reviewer, QA, and ad-hoc crewmates) has full, unrestricted access to the complete suite of 33 Compound Engineering skills (`ce-*`).
- **No Single-Skill Confinement**: While subagents boot with a designated primary role (e.g. `layout-grid` or `build-threejs-scroll-worlds`), they are NEVER confined to that single skill. Subagents are expected to dynamically inspect and adopt Compound Engineering capabilities throughout the task lifecycle.
- **Direct Subagent Access Channels**:
  1. **Filesystem Inspection**: Every subagent can directly inspect `/home/soham/.agents/skills/<skill>/SKILL.md` using standard read tools or `cat`.
  2. **Firstmate CLI Reader**: Subagents can run `firstmate skill-read <skill>` inside their Herdr terminal to display full instructions on demand.
  3. **CE Skills Discovery**: Subagents can run `firstmate skills --ce` (or `firstmate skills [query]`) to browse available Compound Engineering tooling.
  4. **Boot Orientation**: Every provisioned subagent automatically receives `001_orientation.msg` in their Firstmate inbox with a full sitemap of CE skills.
- **Dynamic Cross-Functional Adoption Scenarios**:
  - **DOM & Header Engineers**: Adopt `ce-ui-optimize` for hardware-accelerated 60/120fps micro-interactions, `ce-simplify-code` for post-implementation cleanup, and `ce-prototype` for rapid layout probes.
  - **Motion & 3D Specialists**: Adopt `ce-debug` for performance jank and WebGL memory leak diagnosis, and `ce-test-browser` for headless render checks.
  - **Adversarial Reviewers**: Adopt `ce-code-review` for deep multi-pass logic auditing, `ce-test-browser` for viewport regression testing, and `ce-compound` to persist institutional learnings to `solutions/<problem-slug>.md`.
  - **Lead UI Architect**: Issues direct commands instructing subagents to adopt specific CE skills as work phases transition.

---

## Mandatory Two-Phase Execution Workflow

Whenever building any UI (whether from Set 1, Set 2, or Set 3), you and all subagents MUST execute in two strict sequential phases:

```
[ Phase 0: Interactive Grill-Me Session (User Alignment & Locked Decisions) ]
   ↓ (User approves decisions or chooses 'Proceed to Design')
[ Phase 1: Core UI Architecture & Construction ]
   ↓ (All subagents build layout, components, styling, state, content)
[ UI Complete & Settled ]
   ↓
[ Phase 2: Dedicated Animation Polish Pass ]
   1. find-animation-opportunities (Sweep UI for high-impact motion moments)
   2. animate & motion systems (Implement GPU-accelerated micro-interactions)
   3. review-animations (Strict audit against 10 Non-Negotiable Standards)
```

### Phase 1: Core UI Architecture & Construction
1. Select and isolate the chosen UI Set (Set 1, 2, or 3). Do NOT mix styles from other sets or introduce generic templates.
2. Build all core UI elements, layouts, components, responsive typography, data tables, state flows, and theme adaptations.
3. Coordinate all parallel subagents (e.g. via Firstmate/Herdr) to complete the full UI structure and functionality.
4. Verify that the layout, structure, and contrast are rock solid before touching the animation layer.

### Phase 2: Dedicated Animation Polish Pass ("THEN Launch This Animation Skill")
**DO NOT stop once the basic UI is created.** Once Phase 1 is complete and all subagents have finished their UI tasks, you MUST immediately launch the animation workflow using the skills in `Animations-skills`:

#### Step 1: Discover High-Leverage Opportunities (`find-animation-opportunities`)
- Sweep the rendered UI for high-conviction motion moments:
  - **Feedback gaps**: Buttons, cards, and interactive controls with no `:active` press state.
  - **Teleporting state**: Popovers, modals, dropdowns, or tabs that pop in without an entrance bridge.
  - **Spatial story**: Menus and popovers scaling from their trigger (`transform-origin: var(--transform-origin)`).
  - **Delight budget**: First-time completion, empty states, or success moments.
- **Reject High-Frequency / Keyboard Actions**: Never animate actions repeated 100+ times/day (command palettes, keyboard shortcuts). Restraint is craft.

#### Step 2: Implement Premium Motion (`animate`, `apple-design`, `gsap`)
- **GPU-Only Properties**: Animate ONLY `transform` and `opacity`. NEVER animate `height`, `width`, `margin`, `padding`, `top`, or `left`.
- **Never `scale(0)`**: All scale entrances must start from `scale(0.95)` to `scale(0.98)` with `opacity: 0`. Nothing in reality appears from zero.
- **Organic Easing & Durations**:
  - UI animations MUST stay under `300ms` (typically `150ms–250ms`).
  - Use custom curves: `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)` or iOS drawer curve `cubic-bezier(0.32, 0.72, 0, 1)`.
  - **NEVER use `ease-in` on UI** (it delays response when the user is watching).
- **Tactile Micro-Interactions**:
  - Buttons and cards must have instant `:active` press compression (`transform: scale(0.96–0.98)` with `100ms–160ms ease-out`).
  - Subtle `:hover` lift (`transform: translateY(-1.5px)`).
- **Interruptibility & Springs**: Use interruptible transitions or Apple-style springs (`{ type: "spring", duration: 0.5, bounce: 0.2 }`) for gestures, sheets, and draggable elements.
- **Set 3 Integration**: In Set 3, combine Lenis smooth scrolling with GSAP timelines, split-text word reveals, and magnetic cursors for the living centerpiece.

#### Step 3: Strict Motion Review (`review-animations` / `improve-animations`)
- Run `review-animations` against the 10 Non-Negotiable Standards:
  1. Justified motion (Feedback, Spatial consistency, State indication, Jarring prevention).
  2. Frequency-appropriate (no keyboard-shortcut animations).
  3. Responsive easing (`ease-out` / strong cubic-bezier, never `ease-in`).
  4. Sub-300ms UI duration.
  5. Origin & physical correctness (no `scale(0)`, trigger-anchored origins).
  6. Interruptibility (transitions/springs, not restarting keyframes).
  7. GPU-only properties (no layout triggers).
  8. Accessibility: `@media (prefers-reduced-motion: reduce)` gentler variants, and `@media (hover: hover) and (pointer: fine)` hover gating.
  9. Asymmetric timing (deliberate press vs. snappy release).
  10. Visual and emotional cohesion.

---

## Compound Engineering Synergy Across UI Projects

Every UI project in Lane 3 must compound its quality by weaving the core Compound Engineering skills into the lifecycle:

1. **Pre-Build Planning (`ce-plan` / `ce-brainstorm`)**:
   - Scope component architecture, asset needs (SVGs/logos), and state machines before coding.
   - Read prior captured learnings in `solutions/` and `.agents/learnings/`.
   - Protect branches via isolated worktrees (`treehouse` / `ce-worktree`).

2. **Visual & Browser QA (`ce-test-browser` + `omagent-screenshot`)**:
   - Capture desktop (1440x900) and mobile (375x812) screenshots.
   - Run automated browser testing for interactive forms and data tables.

3. **Adversarial Sibling Review (`ce-code-review`)**:
   - Prompt the sibling subagent in Herdr for adversarial code and accessibility review before concluding.

4. **Code Simplification Pass (`ce-simplify-code`)**:
   - Clean up settled code, deduplicate styles and components, and remove dead code while preserving exact behavior.

5. **Durable Knowledge Compounding (`ce-compound`)**:
   - Record novel solved problems, design tokens, and non-obvious fixes into `solutions/<problem-slug>.md` so subsequent turns and projects automatically inherit the learnings.

6. **Clean Git Shipping (`ce-commit` / `ce-commit-push-pr`)**:
   - Create value-communicating commits and verified PRs with `no-mistakes`.

---

## Strict Isolation: UI Development vs Normal Coding Tasks

When a user asks for a software development task that is NOT a frontend/UI project—such as a Python script, a Java program, a C# script, a CLI tool, a backend service, an algorithm, a database migration, or an automated script—the system and all agents MUST strictly isolate this work from the UI pipeline:

### 1. Absolute Rule: Never Confuse Normal Coding Tasks with UI Development
- Normal coding tasks must **NEVER** be treated as UI design:
  - **Zero UI Archetype Prompts**: Do NOT prompt the user with UI Skill Sets (Set 1, 2, 3).
  - **Zero Grill-Me UI Questions**: Do NOT ask Grill-Me questions about 3D centerpieces, scroll kinetic physics, or header wrapping.
  - **Zero UI Skills Injection**: Do NOT inject or load UI skills (Set 1, 2, 3, 3D Three.js WebGL, shaders, canvas, navbar white-space rules, or Swiss typography).

### 2. Dedicated Coding Worktree Protocol (Zero UI Tree Pollution)
- All normal coding tasks execute in a dedicated, isolated custom worktree completely decoupled from UI / app development trees:
  - **Dedicated Path**: If within an existing git repo, creates an isolated git worktree branch `coding/<slug>` under `.worktrees/coding-<slug>`. Otherwise, creates a clean project directory under `~/Projects/coding-tasks/<slug>`.
  - **Git & Worktree Isolation**: Initializes an isolated git branch `coding/<slug>` with standard language `.gitignore` (`__pycache__/`, `*.pyc`, `.venv/`, `bin/`, `obj/`, `*.class`, `node_modules/`, `*.log`).
  - **Zero Pollution**: Web assets, UI build files, HTML templates, and UI worktrees are NEVER touched or polluted.

### 3. Multi-Harness & Multi-Model Flexibility
- The normal coding task pipeline fully supports all user-selected harnesses:
  - `agy` (Antigravity CLI with direct tool use and Python SDK integration)
  - `opencode` (OpenCode runtime with multi-model failover)
  - `cline` (Autonomous task runner with compaction)
- Fully supports any chosen model (Claude 3.7 Sonnet, GPT-4o, DeepSeek, Gemini 2.5/3.5, etc.) as configured by the user.

### 4. Specialized Software Engineering Multi-Subagent Fleet (Herdr 2x2 Swarm)
Rather than UI designers and 3D animators, normal coding tasks provision a specialized software engineering fleet in Herdr:
- **Pane 1 (Top-Left): 🏛️ Lead Software Engineer** (`lead_*` · Role: `lead-engineer` · Skill: `ce-work` / `ce-plan`):
  Master system architect and implementation coordinator.
- **Pane 2 (Top-Right): ⚙️ Core Logic & Systems Specialist** (`mot_*` · Role: `core-logic-specialist` · Skill: `ce-work`):
  Implements business logic, algorithms, state machines, data structures, and APIs.
- **Pane 3 (Bottom-Left): 🧪 Test Suite & QA Specialist** (`dom_*` · Role: `test-and-qa-engineer` · Skill: `ce-debug`):
  Writes and executes comprehensive automated unit tests (`pytest`, `unittest`, `junit`, etc.), test harnesses, and edge-case coverage.
- **Pane 4 (Bottom-Right): 🛡️ Adversarial Code Reviewer** (`rev_*` · Role: `adversarial-code-reviewer` · Skill: `ce-code-review`):
  Performs adversarial code review for bugs, regressions, performance, concurrency, resource leaks, and language idioms.

### 5. Unrestricted Access to the Full 33 Compound Engineering Skills Suite
Every subagent in the coding fleet has full, unrestricted on-demand access to all 33 Compound Engineering skills:
- Upstream planning & blueprints: `ce-plan`, `ce-brainstorm`, `ce-strategy`
- Implementation & prototyping: `ce-work`, `ce-prototype`
- Root-cause diagnosis & crash triage: `ce-debug`, `diagnose-crash`
- Automated verification: `ce-debug`, `ce-test-browser`
- Adversarial review: `ce-code-review`, `no-mistakes`
- Performance optimization: `ce-optimize`
- Code simplification: `ce-simplify-code`
- Durable knowledge compounding: `ce-compound`
- Verified commits & PRs: `ce-commit`, `ce-commit-push-pr`

### 6. Mandatory 6-Phase Software Engineering Lifecycle
1. **Phase 1: Architecture & Data Modeling (`ce-plan` / `ce-brainstorm`)**: Scoping data models, classes, interfaces, and execution flow.
2. **Phase 2: Systematic Implementation (`ce-work`)**: Developing modular, clean, PEP 8/language-idiomatic code in the dedicated coding worktree.
3. **Phase 3: Automated Testing & Syntax Verification (`ce-debug` + test suites)**: Writing unit tests and executing code validation (`python3 -m py_compile`, `pytest`, `javac`, `dotnet test`).
4. **Phase 4: Adversarial Peer Review (`ce-code-review`)**: Sibling code review in Herdr for concurrency, edge cases, and security.
5. **Phase 5: Performance Optimization & Simplification (`ce-optimize` + `ce-simplify-code`)**: Algorithmic optimization, profiling, and DRY code simplification.
6. **Phase 6: Durable Learning & Safe Commit (`ce-compound` + `ce-commit`)**: Persisting novel engineering solutions to `solutions/<problem-slug>.md` and safe git commit.
