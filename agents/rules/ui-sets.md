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

---

## The 3 UI Skill Sets

The user has 3 specialized UI skill sets configured at `/home/soham/Ui-skills/`:

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

---

## Mandatory Two-Phase Execution Workflow

Whenever building any UI (whether from Set 1, Set 2, or Set 3), you and all subagents MUST execute in two strict sequential phases:

```
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
