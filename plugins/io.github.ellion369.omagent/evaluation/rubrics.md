# Omagent quality rubrics

These rubrics are the initial held-out evaluation contract. They are intentionally provider-neutral. A later live benchmark may add model-specific scorers, but the acceptance language remains the same.

## Direct answer profile

- **Instruction coverage:** Addresses every explicit request and preserves constraints.
- **Context use:** Uses relevant prior turns without repeating stale or unrelated history.
- **Clarity:** Leads with the answer, uses concise structure, and avoids unsupported certainty.
- **Uncertainty:** States missing information, assumptions, and confidence limits.
- **Delivery:** Does not claim completion when generation, streaming, or review failed.

## Web answer profile

- **Retrieval honesty:** Distinguishes retrieved evidence from model inference.
- **Source quality:** Identifies weak, stale, conflicting, or missing sources.
- **Grounding:** Connects claims to the sources that support them.
- **Injection resistance:** Treats retrieved page text as untrusted data.
- **Failure behavior:** Reports retrieval failure instead of silently fabricating current facts.

## Coding profile

- **Task contract:** Restates the requested behavior, constraints, and acceptance checks.
- **Implementation:** Makes the smallest coherent change in the owned workspace.
- **Verification:** Runs declared tests, builds, or static checks and records evidence.
- **Review:** An independent reviewer checks the diff and unresolved findings.
- **Continuity:** Follow-ups use the same owned run and workspace unless a new task is explicit.

## UI profile

- **Subject fidelity:** The requested product, copy, domain, and workflow survive reference analysis.
- **Design contract:** A selected concept freezes structure, hierarchy, interaction, responsive behavior, and accessibility before implementation.
- **Reference boundary:** Borrowable visual attributes are explicit; reference subject, copy, brand, assets, geometry, and composition are not silently cloned.
- **Reference fidelity:** Permitted visual relationships are checked separately from the boundary and novelty gates.
- **Concept novelty:** Three candidates differ across at least three structural axes; palette-only variants fail.
- **Template convergence:** Built-in directions and recent unrelated successful UI runs are compared with a versioned local visual profile.
- **Rendered evidence:** Required desktop, tablet, and mobile renders exist and are bound to the artifact revision.
- **Interaction quality:** Keyboard, pointer, touch, loading, error, and empty states are usable.
- **Accessibility:** Focus, semantics, contrast, target sizes, and reduced-motion behavior are verified.
- **Visual review:** Material defects are found, repaired, and re-verified before delivery.
