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

## 3. Prompt Primacy Architecture & Visual Reference Deconstruction

### 3.1 The Supreme Prompt Primacy Law
A common failure mode in multimodal agent design is "Reference Image Hijacking": when a user provides a master prompt specifying their desired product (e.g. *"Build an AI sports analytics platform"*) alongside a visual reference image (e.g. a luxury hair salon or fashion boutique for aesthetic mood), naive agents erroneously clone the website in the image, completely ignoring the user's prompt.

Omagent enforces **Absolute Prompt Primacy**:
1. **The User's Master Prompt is the Sole Sacred Truth**:
   - The user's prompt defines 100% of the domain entity, company name, hero headlines, features, navigation links, service cards, data models, and copy.
   - If the user asks for a crypto trading dashboard or sports platform, the generated site MUST be 100% a crypto trading dashboard or sports platform.
2. **Reference Images are Solely Aesthetic Style Donors**:
   - The reference image contributes ONLY abstract aesthetic DNA: chromatic canvas (`#hex`), accent strike color, lighting atmosphere, squircle corner radiuses, typographic pairing cadence, and frosted glass recipes.
   - **Absolute Prohibition on Cloning**: Recreating or copying the website, industry, product, or company depicted in the reference image is treated as a **CATASTROPHIC FAILURE**.
3. **Domain Sanitization & Keyword Isolation**:
   - The router sanitizes all prompt text before domain keyword matching (`detect_project_domain`), stripping image filenames, tags (`[ref: ...]`), and image directory paths. This ensures image filenames (e.g. `atelier_vane.png`) can never hijack domain detection.

### 3.2 Mathematical & Visual Deconstruction (Subagent 1)
When a reference image is attached, Subagent 1 extracts its visual design tokens without copying content:
1. **Geometric & Viewport Profile**: Resolution (`width x height`), aspect ratio (`16:9`, `4:3`, `1:1`, `9:16`), image format.
2. **Chromatic Hierarchy**:
   - Base canvas color (`#hex`) and light/dark theme luminance calculation.
   - Dominant tonal chords and palette summary.
   - High-contrast accent strike color (`#hex`).
3. **Typographic Character**: Display serif vs. grotesque sans, optical sizing, and baseline rhythm.
4. **Spatial Cadence**: Proportional negative space, asymmetric balance, grid density.
5. **Materiality & Surface Finishes**: Frosted glass (`backdrop-filter: blur(24px)`), hairline borders, caustics, noise grain.

The complete deconstruction report is saved to `solutions/reference_design_language.md` in the project root with a permanent anti-copying warning header for all fleet subagents.

---

## 4. Interactive Dynamic Grill-Me Session Engine

The Grill-Me session ensures deep alignment between user vision and autonomous build execution. It replaces legacy static 3-question templates with a **comprehensive, dynamic 6-question architecture** grounded in either the deconstructed reference image or the detected prompt domain.

### 4.1 Dual-Layer Dynamic Question Generation
To guarantee zero-latency execution while leveraging frontier intelligence:
1. **Layer 1 (Fast LLM Synthesizer)**:
   - Queries `gemini-3.5-flash` with a 3.5s strict timeout.
   - Dynamically crafts 6 deeply contextual, non-generic architectural questions grounded in the prompt, domain, and reference image analysis.
2. **Layer 2 (High-Speed Local Algorithmic Synthesizer)**:
   - Instantaneous (<5ms fallback or offline mode) algorithmic generation.
   - Dynamically builds 6 deep questions with 3 bespoke architectural options across 15+ specialized domains (`haircraft`, `fintech_crypto`, `ai_robotics`, `saas_platform`, `luxury_fashion`, `architecture_spatial`, `music_audio`, `health_biotech`, `culinary_dining`, `creative_portfolio`, `gaming_esports`, `automotive_mobility`, `ecommerce_retail`, `education_learning`, and `bespoke_default`).

### 4.2 Comprehensive 6-Question Round Structure
Every Grill-Me round features **exactly 6 substantive questions**, each with 3 distinct architectural options:

- **Round 1 · Visual Identity & Master Architecture**:
  1. *Atmospheric Environment & Chromatic Palette*: Exact `#hex` canvas, accent strikes, and color temperature (grounded in reference image or domain).
  2. *Hero Stage Composition & Centerpiece*: Strictly thematic Three.js 3D centerpiece (Set 3), SaaS telemetry workspace (Set 2), Impeccable spatial fidelity (Set 4), or Swiss editorial layout (Set 1).
  3. *Typographic Personality & Optical Hierarchy*: Display serif vs bold geometric grotesk vs Swiss neo-grotesk with monospace telemetry.
  4. *Chromatic Balance & Accent Strike Distribution*: Concentrated focal strike vs dual-tone ambient gradient vs architectural monochrome metallic.
  5. *Component Surface Architecture & Corner Geometry*: Apple-grade squircles (`16-20px`) vs Bauhaus sharp (`6-8px`) vs stadium capsules (`9999px`).
  6. *Primary Conversion Funnel & Interactive Signature*: Multi-step stepper modal vs direct in-page sandbox/lookbook vs VIP concierge sliding drawer.

- **Round 2 · Kinetic Motion, Scroll Dynamics & Micro-Affordances**:
  1. *Scroll Physics & Lenis Choreography*: Inertia lerp vs pinned stage chapters with 3D camera scrub vs fluid parallax curtains.
  2. *Micro-Affordances & Tactile Hover Physics*: Emil Kowalski-grade magnetic cursor snapping (40px radius) vs 3D card tilt vs spring elevation lift.
  3. *Background Atmosphere & Shader Depth*: Analog film grain with breathing radial aura vs Bayer-ordered dithering waves vs deep void with light orbs.
  4. *Mobile Viewport Ergonomics & Touch Gestures*: Bottom-anchored thumb island vs horizontal snap-scroll tracks vs full-screen directory drawer.
  5. *Sensory Polish & Sound / Haptic Cues*: Visual-only haptic ripple vs acoustic synthesizer micro-clicks vs WCAG AAA focus rings.
  6. *Performance Budgeting & 120fps Frame Delivery*: GPU compositing transform pipelines vs adaptive WebGL DPR scaling vs IntersectionObserver lazy compilation.

- **Round 3 · Header Architecture, Storytelling & Deep Mechanics**:
  1. *Header & Navigation Architecture*: Floating frosted glass pill vs full-width architectural masthead vs minimalist monogram trigger (zero line-wrapping enforced).
  2. *Form Validation & Submission Delight*: Real-time inline validation vs celebratory spring morph vs VIP concierge confirmation card.
  3. *Typographic Scale, Leading & Negative Tracking*: Fluid clamp scaling (-0.035em) vs generous editorial leading (1.75) vs compact high-density scannability.
  4. *Section Sequencing & Narrative Flow*: Cinematic pinned chapters vs asymmetric fluid cascade vs dual-track split-screen.
  5. *Omarchy Dark / Light Theme Adaptability*: Smooth CSS variable cross-fade with strict slate/charcoal contrast guardrails vs pure monolith dark mode.
  6. *Micro-Delight, Brand Easter Eggs & Zero-State Grace*: 3D cursor velocity inertia vs keyboard Konami surprises vs offline-ready progressive caching.

- **Round 4+ · Progressive Fine-Grained Drilling**:
  Cycles of 6 deep questions covering shader specularity, normal maps, spring physics coefficients, glassmorphism filters, keyboard shortcuts, and state machines.

### 4.3 Universal Answer Parsing & User Autonomy
- **Flexible Answer Formats**: Parses `1, 2, 1, 3, 2, 1`, `q1: 1, q2: 2...`, `1: 1, 2: 2...`, `a: 1, b: 2...`, `first: 1, second: 2...`, and mixed strings (`1, 2, 1, 3, 2, 1 and proceed`).
- **Strategic Design Checkpoint**: Once all 6 questions in a round are answered, Firstmate displays the Strategic Design Checkpoint summarizing all locked choices and cleanly asking:
  1. *Proceed to Design & Build* (Stop grilling — commence build)
  2. *Continue Grilling* (Advance to Round 2 / next dimensions)
- **Instant Build Command**: Typing `proceed` or `build` at any time immediately concludes questioning and launches autonomous execution.
- **Creative Freedom Mode**: Typing `skip` or refusing further questions locks any answered decisions and grants specialized subagents full creative leadership.

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

### 5.3 Firstmate Mission Tasking Protocol (`002_task.msg`)
In addition to general orientation, every subagent receives an actionable mission assignment (`002_task.msg`) delivered to their inbox (`~/.local/state/omagent/firstmate/<task_id>.inbox/`), explicitly tailored to `{user_subject}` and the locked Design Specification Contract:
1. **Motion & 3D Specialist (Pane 2)**:
   - Implements hardware-accelerated spring physics (`:active scale(0.96)`, `:hover translateY(-2px)`).
   - Constructs Lenis smooth scroll orchestration and custom WebGL/Three.js centerpieces bespoke to `{user_subject}` (strictly banning generic torus knots or pretzels).
   - Manages ambient background shaders, noise grain, or glass reflections.
2. **DOM Components & Rigid Header Engineer (Pane 3)**:
   - Implements the pristine single-line navbar with frosted glass (`backdrop-filter: blur(24px)`).
   - Enforces `white-space: nowrap !important;` on all navigation items with zero wrapping permitted.
   - Builds the primary interactive conversion mechanism (e.g. Progressive Multi-Step Stepper Modal `#conversion-modal`, interactive sandbox grid, or concierge sliding drawer) with keyboard Enter support and real input validation.
   - Injects mandatory design tokens into `:root` in `styles.css`.
3. **Adversarial Reviewer & Gatekeeper (Pane 4)**:
   - Executes the 5-Point Verification Checklist:
     1. *Prompt Primacy Check*: Verifies 100% bespoke copy, features, and brand identity for `{user_subject}`. Zero tolerance for reference cloning.
     2. *CSS Tokens & Contrast*: Audits `:root` variables and WCAG AA contrast (enforcing high-contrast dark slate/charcoal on light backgrounds).
     3. *Header Non-Wrapping*: Checks `white-space: nowrap !important;` and verifies zero wrapping.
     4. *Conversion Component*: Verifies interactive modal/drawer DOM presence and event listeners.
     5. *Visual QA & Remediation Loop*: Inspects rendered screenshots and issues remediation commands to subagents if defects exist before certifying done.

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
- **Autonomous AGY Wrapper**: `/home/soham/.local/bin/agy` (wraps real ELF at `/home/soham/.local/bin/agy-real`)
- **Antigravity CLI Settings**: `~/.gemini/antigravity-cli/settings.json`

---

## 9. Universal Antigravity Folder-Trust & Autonomous AGY Subagent Architecture

### 9.1 The Problem: Folder Trust Prompt Bricking Autonomous Subagents
When `omagent-route` provisions Herdr workspaces and Firstmate launches 4 parallel subagents (e.g. Lead UI Architect, Motion Specialist, DOM & Header Engineer, Adversarial Reviewer), subagents utilizing the `agy` (Antigravity CLI) harness would encounter an interactive TUI prompt:
```text
Do you trust the contents of this project?
Antigravity CLI requires permission to read, edit, and execute files here.
> Yes, I trust this folder
  No, exit
```
Because subagents run autonomously in background Herdr panes without human terminal intervention:
1. The process blocked indefinitely on terminal `stdin`.
2. Herdr timed out waiting for interactive readiness (`timeout: 15000` ms).
3. The entire multi-subagent autonomous orchestration bricked.

### 9.2 Root Cause Analysis
- Antigravity's internal Go struct method `IsTrustedWorkspace(path)` matches against entries in `~/.gemini/antigravity-cli/settings.json["trustedWorkspaces"]` using **exact path equality**, not recursive prefix matching.
- Pre-registering `/home/soham` or `/home/soham/Projects` did not satisfy checks for dynamically generated project paths (e.g. `/home/soham/Projects/luxury-store-1`, `/home/soham/Projects/coding-tasks/algo-x`, or `.worktrees/coding-<slug>`).

### 9.3 Three-Tier Zero-Prompt Autonomous Resolution
To guarantee that interactive folder-trust prompts NEVER halt or brick autonomous agent execution:

1. **Autonomous Invocation Wrapper (`/home/soham/.local/bin/agy`)**:
   - The native 213MB ELF binary is renamed to `/home/soham/.local/bin/agy-real`.
   - A lightweight (<0.2ms) wrapper script sits at `/home/soham/.local/bin/agy` (and symlinked from `antigravity`).
   - On every execution, it extracts `$PWD`, `os.path.realpath($PWD)`, and any `--add-dir` / `--project` / `--workspace` arguments.
   - It atomically injects them into `~/.gemini/antigravity-cli/settings.json["trustedWorkspaces"]`, while ensuring `"allowNonWorkspaceAccess": true` and `"toolPermission": "always-proceed"`.
   - It then `exec`s `agy-real "$@"`, guaranteeing that `agy-real` always encounters a pre-trusted directory upon initialization.

2. **Self-Healing Router Engine (`ensure_antigravity_trusts_workspace`)**:
   - Built directly into `/home/soham/.config/omarchy/plugins/io.github.ellion369.omagent/omagent-route` and `/home/soham/.local/bin/firstmate-subagent`.
   - **Self-Healing Detection**: If an internal CLI update (`agy update`) overwrites `/home/soham/.local/bin/agy` with a raw ELF binary (`\x7fELF`), `ensure_antigravity_trusts_workspace` detects the binary header, automatically rotates it to `agy-real`, and reinstalls the wrapper script.
   - **Pre-Flight Registration**: Automatically invoked during `resolve_project_cwd()`, `resolve_coding_worktree()`, Herdr workspace creation, and pane subagent launches so paths are registered before terminal execution starts.

3. **Explicit Dangerously-Skip-Permissions Flag**:
   - All autonomous subagent launches via Herdr (`herdr agent start <name> --kind agy --pane <pane> --timeout 15000 -- --dangerously-skip-permissions`) pass `--dangerously-skip-permissions`.
   - This bypasses all interactive tool confirmation dialogs and permission requests.
