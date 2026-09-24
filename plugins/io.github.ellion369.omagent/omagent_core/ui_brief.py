"""Structured, prompt-first UI concept and design-contract generation.

The router still owns orchestration for now, but design direction is represented
as data instead of passing UI set names and long default directives between
layers.  The functions in this module are deterministic and provider-free so
concept diversity can be tested without a live model.
"""
from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Callable, Iterable

CONTRACT_VERSION = "ui-contract/v1"
CONCEPT_COUNT = 3
CONCEPT_AXES = (
    "information_architecture",
    "composition",
    "typography",
    "interaction_signature",
    "asset_strategy",
)
MIN_AXIS_DIFFERENCES = 3
DEFAULT_VIEWPORTS = ("desktop:1440x900", "tablet:768x1024", "mobile:375x812")


@dataclass(frozen=True)
class ConceptCandidate:
    id: str
    title: str
    thesis: str
    product_task: str
    information_architecture: str
    composition: str
    typography: str
    interaction_signature: str
    motion: str
    asset_strategy: str
    rationale: str
    borrowable_reference_attributes: tuple[str, ...] = ()
    forbidden_reference_attributes: tuple[str, ...] = ()

    def as_dict(self) -> dict[str, Any]:
        value = asdict(self)
        value["borrowable_reference_attributes"] = list(self.borrowable_reference_attributes)
        value["forbidden_reference_attributes"] = list(self.forbidden_reference_attributes)
        return value

    @property
    def signature(self) -> tuple[str, ...]:
        return tuple(getattr(self, axis) for axis in CONCEPT_AXES)


@dataclass(frozen=True)
class ReferencePolicy:
    mode: str = "style-only"
    primary_reference_id: str = ""
    path: str = ""
    borrowable: tuple[str, ...] = ()
    forbidden: tuple[str, ...] = ()
    evidence_fingerprint: str = ""
    analyzer_version: str = ""
    provenance_note: str = "Reference content is evidence, not product authority."

    def as_dict(self) -> dict[str, Any]:
        value = asdict(self)
        value["borrowable"] = list(self.borrowable)
        value["forbidden"] = list(self.forbidden)
        return value

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> "ReferencePolicy":
        return cls(
            mode=str(value.get("mode", "style-only")),
            primary_reference_id=str(value.get("primary_reference_id", "")),
            path=str(value.get("path", "")),
            borrowable=tuple(str(item) for item in value.get("borrowable", ())),
            forbidden=tuple(str(item) for item in value.get("forbidden", ())),
            evidence_fingerprint=str(value.get("evidence_fingerprint", "")),
            analyzer_version=str(value.get("analyzer_version", "")),
            provenance_note=str(value.get("provenance_note", "")),
        )

    def validate(self) -> None:
        if self.mode not in {"style-only", "recreate"}:
            raise ValueError("reference mode must be style-only or recreate")
        if not self.borrowable and not self.forbidden:
            raise ValueError("reference policy must state what may and may not be borrowed")
        if self.mode == "recreate" and not self.primary_reference_id:
            raise ValueError("recreation mode requires a primary reference")
        if self.mode == "recreate" and not self.evidence_fingerprint:
            raise ValueError("recreation mode requires a fingerprinted reference")


@dataclass
class DesignContract:
    subject: str
    request: str
    candidates: list[ConceptCandidate]
    product_family: str = ""
    selected_concept_id: str = ""
    direction: str = ""
    layout: list[str] = field(default_factory=list)
    interactions: list[str] = field(default_factory=list)
    accessibility: list[str] = field(default_factory=list)
    responsive: list[str] = field(default_factory=list)
    motion: list[str] = field(default_factory=list)
    viewports: list[str] = field(default_factory=lambda: list(DEFAULT_VIEWPORTS))
    asset_policy: list[str] = field(default_factory=list)
    reference_policy: ReferencePolicy | None = None
    assumptions: list[str] = field(default_factory=list)
    blocking_questions: list[str] = field(default_factory=list)
    version: str = CONTRACT_VERSION

    @property
    def selected_concept(self) -> ConceptCandidate | None:
        return next((candidate for candidate in self.candidates if candidate.id == self.selected_concept_id), None)

    def as_dict(self) -> dict[str, Any]:
        return {
            "version": self.version,
            "subject": self.subject,
            "request": self.request,
            "product_family": self.product_family,
            "candidates": [candidate.as_dict() for candidate in self.candidates],
            "selected_concept_id": self.selected_concept_id,
            "direction": self.direction,
            "layout": list(self.layout),
            "interactions": list(self.interactions),
            "accessibility": list(self.accessibility),
            "responsive": list(self.responsive),
            "motion": list(self.motion),
            "viewports": list(self.viewports),
            "asset_policy": list(self.asset_policy),
            "reference_policy": self.reference_policy.as_dict() if self.reference_policy else None,
            "assumptions": list(self.assumptions),
            "blocking_questions": list(self.blocking_questions),
        }

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> "DesignContract":
        candidates = [ConceptCandidate(**_candidate_kwargs(item)) for item in value.get("candidates", [])]
        reference = value.get("reference_policy")
        return cls(
            subject=str(value.get("subject", "")),
            request=str(value.get("request", "")),
            product_family=str(value.get("product_family", "")),
            candidates=candidates,
            selected_concept_id=str(value.get("selected_concept_id", "")),
            direction=str(value.get("direction", "")),
            layout=[str(item) for item in value.get("layout", [])],
            interactions=[str(item) for item in value.get("interactions", [])],
            accessibility=[str(item) for item in value.get("accessibility", [])],
            responsive=[str(item) for item in value.get("responsive", [])],
            motion=[str(item) for item in value.get("motion", [])],
            viewports=[str(item) for item in value.get("viewports", DEFAULT_VIEWPORTS)],
            asset_policy=[str(item) for item in value.get("asset_policy", [])],
            reference_policy=ReferencePolicy.from_dict(reference) if isinstance(reference, dict) else None,
            assumptions=[str(item) for item in value.get("assumptions", [])],
            blocking_questions=[str(item) for item in value.get("blocking_questions", [])],
            version=str(value.get("version", CONTRACT_VERSION)),
        )

    def validate(self) -> None:
        if self.version != CONTRACT_VERSION:
            raise ValueError(f"unsupported UI contract version: {self.version}")
        if not self.subject.strip() or not self.request.strip():
            raise ValueError("design contract requires a subject and request")
        if not self.direction.strip():
            raise ValueError("design contract requires a direction")
        if not self.layout or not self.interactions or not self.accessibility or not self.responsive or not self.viewports:
            raise ValueError("design contract requires layout, interaction, accessibility, responsive, and viewport decisions")
        if not self.candidates:
            raise ValueError("design contract requires concept candidates")
        if self.selected_concept_id and self.selected_concept is None:
            raise ValueError("selected concept is not present in the candidate set")
        if self.selected_concept_id:
            validate_concept_diversity(self.candidates)
        if self.reference_policy is not None:
            self.reference_policy.validate()


@dataclass(frozen=True)
class ConceptSynthesisResult:
    candidates: list[ConceptCandidate]
    provider_attempted: bool = False
    provider_used: bool = False
    validation: ConceptValidation | None = None
    fallback_reason: str = ""

    def as_dict(self) -> dict[str, Any]:
        return {
            "provider_attempted": self.provider_attempted,
            "provider_used": self.provider_used,
            "validation": self.validation.as_dict() if self.validation else None,
            "fallback_reason": self.fallback_reason,
        }


@dataclass(frozen=True)
class ConceptValidation:
    valid: bool
    errors: tuple[str, ...]
    differences: tuple[tuple[str, int], ...]

    def as_dict(self) -> dict[str, Any]:
        return {"valid": self.valid, "errors": list(self.errors), "differences": [list(item) for item in self.differences]}


def _candidate_kwargs(value: dict[str, Any]) -> dict[str, Any]:
    allowed = set(ConceptCandidate.__dataclass_fields__)
    result = {key: item for key, item in value.items() if key in allowed}
    for key in ("borrowable_reference_attributes", "forbidden_reference_attributes"):
        if key in result:
            result[key] = tuple(result[key])
    return result


def _normalized(value: str) -> str:
    return " ".join(value.lower().split())


def _axis_differences(left: ConceptCandidate, right: ConceptCandidate) -> int:
    return sum(_normalized(getattr(left, axis)) != _normalized(getattr(right, axis)) for axis in CONCEPT_AXES)


def validate_concept_diversity(candidates: Iterable[ConceptCandidate], *, minimum_differences: int = MIN_AXIS_DIFFERENCES) -> ConceptValidation:
    values = list(candidates)
    errors: list[str] = []
    if len(values) < CONCEPT_COUNT:
        errors.append(f"at least {CONCEPT_COUNT} concepts are required")
    if len({candidate.signature for candidate in values}) != len(values):
        errors.append("concept signatures must be unique")
    differences: list[tuple[str, int]] = []
    for index, left in enumerate(values):
        for right in values[index + 1 :]:
            count = _axis_differences(left, right)
            differences.append((f"{left.id}:{right.id}", count))
            if count < minimum_differences:
                errors.append(f"{left.id} and {right.id} differ on only {count} structural axes")
    return ConceptValidation(not errors, tuple(errors), tuple(differences))


def synthesize_concept_candidates(
    subject: str,
    prompt: str,
    *,
    reference: dict[str, Any] | None = None,
    synthesizer: Callable[[str, str, dict[str, Any] | None], Iterable[ConceptCandidate | dict[str, Any]]] | None = None,
) -> ConceptSynthesisResult:
    """Use a provider synthesizer only when it returns a valid structured set."""
    fallback = generate_concept_candidates(subject, prompt, reference=reference)
    if synthesizer is None:
        return ConceptSynthesisResult(fallback, validation=validate_concept_diversity(fallback))
    try:
        raw = list(synthesizer(subject, prompt, reference))
        candidates = [item if isinstance(item, ConceptCandidate) else ConceptCandidate(**_candidate_kwargs(item)) for item in raw]
        validation = validate_concept_diversity(candidates)
    except (TypeError, ValueError, KeyError) as exc:
        return ConceptSynthesisResult(fallback, provider_attempted=True, validation=validate_concept_diversity(fallback), fallback_reason=redact_synthesis_error(exc))
    if not validation.valid:
        return ConceptSynthesisResult(fallback, provider_attempted=True, validation=validation, fallback_reason="provider candidates failed structural diversity validation")
    return ConceptSynthesisResult(candidates, provider_attempted=True, provider_used=True, validation=validation)


def redact_synthesis_error(error: Exception) -> str:
    return f"{type(error).__name__}: {str(error)[:160]}"


def _domain_profile(subject: str, prompt: str) -> dict[str, str]:
    text = f"{subject} {prompt}".lower()
    if any(term in text for term in ("support", "ticket", "ops", "operations", "admin", "crm")):
        return {
            "task": "incident-to-resolution workspace",
            "object": "incident",
            "collection": "case queue",
            "evidence": "timeline and ownership trail",
            "learning": "resolution pattern library",
            "surface": "live operational state",
        }
    if any(term in text for term in ("shop", "store", "commerce", "checkout", "product")):
        return {
            "task": "discovery-to-purchase path",
            "object": "offer",
            "collection": "catalog shelf",
            "evidence": "comparison and delivery details",
            "learning": "saved decision guide",
            "surface": "current cart and recommendation state",
        }
    if any(term in text for term in ("portfolio", "studio", "brand", "showcase")):
        return {
            "task": "point-of-view showcase",
            "object": "project",
            "collection": "project index",
            "evidence": "process and outcome notes",
            "learning": "practice narrative",
            "surface": "selected work and intent",
        }
    if any(term in text for term in ("lesson", "course", "learn", "education", "training")):
        return {
            "task": "guided mastery path",
            "object": "lesson",
            "collection": "learning map",
            "evidence": "practice feedback and progress",
            "learning": "concept review trail",
            "surface": "current learner state",
        }
    return {
        "task": "task-led product workspace",
        "object": "task",
        "collection": "work index",
        "evidence": "decision history and status detail",
        "learning": "pattern library",
        "surface": "current work state",
    }


def _domain_direction(subject: str, prompt: str) -> str:
    return _domain_profile(subject, prompt)["task"]


def _borrowable(reference: dict[str, Any] | None) -> tuple[str, ...]:
    if not reference:
        return ()
    return tuple(str(item) for item in reference.get("borrowable", ()) if str(item).strip())


def _forbidden(reference: dict[str, Any] | None, mode: str = "style-only") -> tuple[str, ...]:
    if not reference:
        return ()
    values = {str(item).lower() for item in reference.get("forbidden", ()) if str(item).strip()}
    values.update({"reference subject", "reference copy", "reference assets", "reference brand"})
    if mode != "recreate":
        values.update({"reference geometry", "reference composition"})
    else:
        values.discard("geometry")
        values.discard("composition")
        values.discard("reference geometry")
        values.discard("reference composition")
    return tuple(sorted(values))


def generate_concept_candidates(
    subject: str,
    prompt: str,
    *,
    reference: dict[str, Any] | None = None,
) -> list[ConceptCandidate]:
    """Create three product-grounded directions with different structures.

    The candidates deliberately use different information architecture,
    composition, type, interaction, and asset strategies.  They are a
    deterministic starting point; a provider may elaborate them, but it must
    preserve their structural signatures and the product subject.
    """
    profile = _domain_profile(subject, prompt)
    task = profile["task"]
    safe_subject = subject.strip() or "the requested product"
    borrowable = _borrowable(reference)
    forbidden = _forbidden(reference)
    return [
        ConceptCandidate(
            id="workflow",
            title="Operational spine",
            thesis=f"Make the primary {profile['object']} and next action visible before adding secondary discovery.",
            product_task=task,
            information_architecture=f"{profile['collection']} with a persistent context rail and progressively revealed {profile['evidence']}",
            composition=f"split workspace: {profile['object']} summary and next action beside a dense {task} surface",
            typography="humanist sans for scanning with a compact monospace metadata layer",
            interaction_signature="keyboard-first command actions with inline validation and optimistic feedback",
            motion="short state transitions only; preserve spatial continuity when data changes",
            asset_strategy=f"functional diagrams, status marks, and data-shaped marks for {profile['evidence']} instead of decorative hero media",
            rationale=f"Optimizes {safe_subject} for repeated use and clear next actions.",
            borrowable_reference_attributes=borrowable,
            forbidden_reference_attributes=forbidden,
        ),
        ConceptCandidate(
            id="atlas",
            title="Narrative atlas",
            thesis=f"Turn {safe_subject} and its {profile['object']}s into a sequence of understandable chapters instead of a generic landing page.",
            product_task=task,
            information_architecture=f"chaptered {profile['collection']} with a persistent index and contextual back-navigation",
            composition=f"staggered editorial blocks with an alternating wide/narrow rhythm around {profile['evidence']}",
            typography="expressive display face paired with a highly legible reading sans",
            interaction_signature="scroll-led disclosure with direct in-context actions and explicit section progress",
            motion="restrained reveal and depth transitions tied to meaningful content changes",
            asset_strategy=f"original product diagrams, annotated examples, and small narrative illustrations for the {profile['learning']}",
            rationale="Prioritizes comprehension, memory, and a distinct point of view for the product.",
            borrowable_reference_attributes=borrowable,
            forbidden_reference_attributes=forbidden,
        ),
        ConceptCandidate(
            id="signal",
            title="Signal board",
            thesis=f"Make {safe_subject} feel responsive by foregrounding {profile['surface']}, comparison, and direct manipulation.",
            product_task=task,
            information_architecture=f"comparison board with switchable lenses and an always-visible {profile['object']} inspector",
            composition=f"modular matrix with a dominant {profile['surface']} region and nested panels",
            typography="neutral grotesk with strong numeric hierarchy and compact labels",
            interaction_signature="pointer-led filtering, inline editing, and reversible actions with visible state",
            motion="fast but calm feedback loops with no continuous motion that competes with reading",
            asset_strategy=f"data geometry, compact charts, and stateful controls for {profile['evidence']} rather than a generic hero image",
            rationale="Suitability is judged by how quickly the user can compare, decide, and correct state.",
            borrowable_reference_attributes=borrowable,
            forbidden_reference_attributes=forbidden,
        ),
    ]


def build_design_contract(
    prompt: str,
    *,
    subject: str = "",
    selected_concept_id: str = "",
    reference: dict[str, Any] | None = None,
    product_family: str = "",
    blocking_questions: list[str] | None = None,
    assumptions: list[str] | None = None,
    concept_synthesizer: Callable[[str, str, dict[str, Any] | None], Iterable[ConceptCandidate | dict[str, Any]]] | None = None,
) -> DesignContract:
    text = " ".join(prompt.strip().split())
    if not text:
        raise ValueError("UI prompt must not be empty")
    product_subject = subject.strip() or text[:160]
    synthesis = synthesize_concept_candidates(
        product_subject,
        text,
        reference=reference,
        synthesizer=concept_synthesizer,
    )
    candidates = synthesis.candidates
    selected_id = selected_concept_id or (candidates[0].id if len(candidates) == 1 else "")
    selected = next((candidate for candidate in candidates if candidate.id == selected_id), None)
    direction = selected.thesis if selected else _domain_direction(product_subject, text)
    policy = None
    if reference:
        mode = str(reference.get("mode", "style-only"))
        borrowable = list(_borrowable(reference))
        if mode == "recreate":
            borrowable.extend(("authorized geometry", "authorized composition"))
        policy = ReferencePolicy(
            mode=mode,
            primary_reference_id=str(reference.get("primary_reference_id", reference.get("image_id", ""))),
            path=str(reference.get("path", "")),
            borrowable=tuple(dict.fromkeys(borrowable)),
            forbidden=_forbidden(reference, mode),
            evidence_fingerprint=str(reference.get("evidence_fingerprint", "")),
            analyzer_version=str(reference.get("analyzer_version", "")),
        )
    return DesignContract(
        subject=product_subject,
        request=text,
        product_family=product_family.strip(),
        candidates=candidates,
        selected_concept_id=selected_id,
        direction=direction,
        layout=["task hierarchy follows the selected concept", "content remains usable without decorative chrome", "responsive reflow preserves the primary action"],
        interactions=["keyboard and pointer paths are explicit", "loading, empty, error, and success states are designed", "all destructive or state-changing actions are reversible or confirmable"],
        accessibility=["visible focus", "semantic labels and headings", "contrast and target-size checks", "reduced-motion behavior"],
        responsive=["desktop uses the selected information hierarchy", "tablet reflows without hiding primary tasks", "mobile keeps the primary action reachable without horizontal scrolling"],
        motion=[selected.motion if selected else "short, meaningful transitions only"],
        asset_policy=["original product-specific assets", "no third-party brand assets or copied content"],
        reference_policy=policy,
        assumptions=list(assumptions or []),
        blocking_questions=list(blocking_questions or []),
    )


def render_concept_cards(contract: DesignContract) -> str:
    lines = ["### Choose a design direction", "", f"Product subject: **{contract.subject}**", ""]
    for index, candidate in enumerate(contract.candidates, 1):
        lines.extend([
            f"**{index}. {candidate.title}** (`{candidate.id}`)",
            f"- Thesis: {candidate.thesis}",
            f"- Structure: {candidate.information_architecture}",
            f"- Composition: {candidate.composition}",
            f"- Type: {candidate.typography}",
            f"- Interaction: {candidate.interaction_signature}",
            f"- Assets: {candidate.asset_strategy}",
            "",
        ])
    lines.append("Reply with a concept number or id. You can also say `proceed` only after a direction is selected.")
    return "\n".join(lines)


def selected_concept_prompt(contract: DesignContract) -> str:
    concept = contract.selected_concept
    if concept is None:
        raise ValueError("a selected concept is required before implementation")
    lines = [
        "IMPLEMENT THE FROZEN UI CONCEPT",
        f"Product subject: {contract.subject}",
        f"Concept: {concept.id} — {concept.title}",
        f"Thesis: {concept.thesis}",
        f"Information architecture: {concept.information_architecture}",
        f"Composition: {concept.composition}",
        f"Typography: {concept.typography}",
        f"Interaction signature: {concept.interaction_signature}",
        f"Motion: {concept.motion}",
        f"Asset strategy: {concept.asset_strategy}",
        f"Verification viewports: {', '.join(contract.viewports)}",
        "Preserve the selected structural direction. Do not substitute a fixed UI set or another concept.",
    ]
    if contract.reference_policy is not None:
        policy = contract.reference_policy
        lines.extend([
            f"Reference mode: {policy.mode}",
            "May borrow: " + ", ".join(policy.borrowable) if policy.borrowable else "May borrow: no inferred attributes",
            "Must not borrow: " + ", ".join(policy.forbidden) if policy.forbidden else "Must not borrow: reference subject/content/assets",
        ])
    return "\n".join(lines)
