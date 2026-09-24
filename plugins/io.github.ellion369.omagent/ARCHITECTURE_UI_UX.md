# UI/UX Agentic Architecture & Multi-Subagent Fleet Orchestration

> **Current system specification.** UI direction is prompt-first and concept-led. The router no longer treats a fixed UI set, a reference-image archetype, or a fixed six-question Grill-Me round as the design contract.

## 1. Workflow lifecycle

```text
UI request
   |
   v
Run-owned reference evidence (when an image is supplied)
   |
   v
Three structurally distinct product-grounded concepts
   |
   v
Same-run concept selection
   |
   v
Bounded contract-coverage alignment
   |
   v
Frozen design contract
   |
   v
Herdr/Firstmate implementation fleet
   |
   v
Responsive renders + interaction/accessibility evidence
   |
   v
Reference boundary, fidelity, novelty, and independent review
   |
   +--> completed
   +--> bounded same-run repair
   +--> incomplete / blocked
```

Every new concept-first UI run uses the Impeccable-led UI/UX skill bundle. `impeccable` is the primary design director; `web-design-engineer`, `ui-design`, `visual-critique`, `design-systems`, `color-system`, `layout-grid`, `interaction-design`, `state-machine-ux`, `form-design`, `loading-states`, `accessibility-audit`, `animate`, `review-animations`, `apple-design`, `find-animation-opportunities`, `ce-ui-optimize`, and `ce-test-browser` are supporting skills. The bundle is recorded in the run-scoped context and injected into the implementation, component, motion, and reviewer missions.

Agentic coding uses an adaptive execution policy. `needle` is a single-provider, single-agent path with an eight-tool-call and ten-minute budget for narrow local edits. `standard` is the focused implementation path. `sword` is the full multi-agent, review, and verification path for architecture, security, migration, reliability, and release-scale work. UI work always receives at least the standard rendered-design policy.

SQLite remains authoritative. The legacy session JSON and Grill-Me sidecar are compatibility projections only. The run-scoped `UiRunContext` carries the request, candidates, selected direction, reference policy, viewports, evidence generation, artifact revision, typed render evidence, reports, and repair history. QML projects that context and sends same-run intent; it does not own completion state.

## 2. Prompt primacy and reference policy

The user request is the sole authority for:

- product subject, domain, company or product name;
- copy, features, navigation, data model, and brand;
- required workflows and accessibility expectations.

A reference image is evidence about visual relationships, not a hidden product brief. Every reference has a content fingerprint, analyzer version, and primary-reference identity. Analysis records separate:

- `borrowable`: palette relationships, tonal direction, type personality, spacing rhythm, or other explicitly allowed abstract attributes;
- `forbidden`: reference subject, copy, brand, assets, geometry, composition, and other content that must not be cloned.

Visible text, OCR, filenames, and image paths are untrusted data. The default mode is `style-only`. Exact recreation is an explicit `recreate` mode with the same content and provenance restrictions. A changed image or analyzer version invalidates old evidence.

## 3. Concept contract

A non-trivial UI request produces three `ConceptCandidate` records. Each candidate states:

- the product task it serves;
- information architecture;
- composition;
- typography;
- interaction signature;
- motion policy; and
- asset or motif strategy.

Candidates pass only when their structural signatures are unique and each pair differs on at least three independent axes. Color changes alone are not diversity. The selected concept is frozen before implementation. Specialists may refine craft within the selected direction but must not introduce a competing direction or a global UI preset.

The structured contract also contains responsive behavior, accessibility requirements, interaction states, asset policy, assumptions, and verification viewports. The contract is the input to implementation and quality review.

## 4. Adaptive alignment

Alignment asks only for unresolved high-impact contract fields. It does not generate a fixed number of questions. A sufficiently specified brief proceeds to implementation after concept selection. A short or genuinely ambiguous brief receives one blocking question. Non-blocking gaps become recorded assumptions.

The user may select a concept with `1`, `2`, `3`, or a concept id. Invalid or incomplete selections keep the same run in `awaiting_user`; they never create a replacement run. `proceed` is valid only after a concept is selected. `you decide` is an explicit delegation to the first validated candidate. `skip` records assumptions only when the product subject and contract coverage are already sufficient. The QML chooser presents the same three candidates as accessible controls and submits the selected concept as a same-run intent.

## 5. UI quality evidence

The UI profile requires separate checks for:

- subject fidelity;
- frozen design contract;
- reference boundary;
- reference fidelity when a reference exists;
- concept novelty and template convergence;
- desktop, tablet, and mobile rendered evidence;
- interaction quality;
- accessibility; and
- independent visual review.

`omagent_core/visual_qa.py` uses deterministic local image fingerprints for near-duplicate detection and records the comparison population, viewport, profile version, and metric values. A raw image hash is not a semantic understanding of a screenshot. `omagent_core/ui_evidence.py` defines the typed render manifest, interaction report, accessibility report, and evidence digest. Provider text markers are not evidence. Reference boundary checks and independent visual review remain separate. Missing Pillow, missing browser/accessibility capability, missing renders, stale evidence, or unavailable review blocks completion rather than passing by default. The deterministic fake adapter supports tests only and is never live-completion eligible.

The default repair limit is two complete same-run repair and re-verification attempts. A repair must produce fresh evidence. Exhausted repairs end as `incomplete`; unavailable required input may end as `blocked`.

## 6. Herdr and Firstmate boundaries

Herdr and Firstmate remain execution backends, not sources of product authority. The controller reserves and records workspace, tab, pane, agent, and task identities before external side effects. A provider session must be explicit before telemetry or review identity is accepted. Cleanup removes only resources recorded in the run manifest.

The implementation crew receives the frozen contract and reference policy. The visual reviewer receives the same run, workspace, evidence generation, and artifact revision binding. Reviewer receipts are imported through the controller-owned receipt channel and are not accepted from the implementer session.

## 7. Compatibility and migration

The old `UI_SKILL_SETS`, fixed Set 1/2/3 selection, automatic Set 4 binding, fixed six-question rounds, and long global visual defaults remain only in legacy compatibility code until their callers are removed. They are not the live UI contract. New UI runs use `ui_concepts/v1`; legacy pending sessions are handled by the compatibility handler and do not gain a new concept contract.

## 8. Validation

Deterministic validation is network-free and provider-free:

```sh
python3 -m unittest discover -s tests -p 'test_*.py'
python3 -m compileall -q omagent_core evaluation tests
qmllint Omagent.qml
```

Live provider, Herdr, Firstmate, and visual benchmark checks are separate manual smoke tests. They do not replace deterministic evidence.
