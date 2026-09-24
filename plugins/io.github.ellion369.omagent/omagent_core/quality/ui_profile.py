"""UI design-contract and rendered-verification rules."""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any

from omagent_core.ui_brief import (
    ConceptCandidate,
    DEFAULT_VIEWPORTS as CANONICAL_VIEWPORTS,
    DesignContract,
    build_design_contract,
    generate_concept_candidates,
    validate_concept_diversity,
)

DEFAULT_VIEWPORTS = tuple(
    (name, int(size.split("x")[0]), int(size.split("x")[1]))
    for name, size in (item.split(":", 1) for item in CANONICAL_VIEWPORTS)
)


@dataclass
class DesignBrief:
    subject: str
    direction: str
    request: str = ""
    layout: list[str] = field(default_factory=list)
    interactions: list[str] = field(default_factory=list)
    accessibility: list[str] = field(default_factory=list)
    responsive: list[str] = field(default_factory=list)
    motion: list[str] = field(default_factory=list)
    assumptions: list[str] = field(default_factory=list)
    blocking_questions: list[str] = field(default_factory=list)
    candidates: list[ConceptCandidate] = field(default_factory=list)

    def validate(self) -> None:
        if not self.subject.strip() or not self.direction.strip():
            raise ValueError("design brief requires a subject and direction")
        if not self.layout or not self.interactions or not self.accessibility:
            raise ValueError("design brief requires layout, interaction, and accessibility decisions")

    def as_contract(self, *, selected_concept_id: str = "", reference: dict[str, Any] | None = None) -> DesignContract:
        contract = build_design_contract(
            self.request if hasattr(self, "request") else self.subject,
            subject=self.subject,
            selected_concept_id=selected_concept_id,
            reference=reference,
            blocking_questions=self.blocking_questions,
            assumptions=self.assumptions,
        )
        contract.layout = list(self.layout)
        contract.interactions = list(self.interactions)
        contract.accessibility = list(self.accessibility)
        if self.responsive:
            contract.responsive = list(self.responsive)
        if self.motion:
            contract.motion = list(self.motion)
        return contract


@dataclass(frozen=True)
class RenderTarget:
    name: str
    width: int
    height: int


def build_adaptive_brief(prompt: str, *, reference_subject: str | None = None) -> DesignBrief:
    text = " ".join(prompt.strip().split())
    if not text:
        raise ValueError("UI prompt must not be empty")
    subject = _extract_subject(text, reference_subject)
    candidates = generate_concept_candidates(subject, text)
    brief = DesignBrief(
        subject=subject,
        request=text,
        direction=candidates[0].thesis,
        layout=["task hierarchy follows a selected concept", "responsive content flow preserves the primary action"],
        interactions=["keyboard and pointer paths", "loading, empty, error, and success states"],
        accessibility=["visible focus", "semantic labels", "contrast and target-size checks", "reduced-motion behavior"],
        responsive=["desktop task hierarchy", "tablet reflow", "mobile primary-action reachability"],
        motion=["short, meaningful state transitions"],
        candidates=candidates,
    )
    if len(text) < 24:
        brief.blocking_questions.append("What is the primary user action and what should the first viewport prioritize?")
    if "reference" in text.lower() and not reference_subject:
        brief.blocking_questions.append("Which abstract visual attribute should guide the design, and what product content must remain independent?")
    return brief


def validate_design_contract(contract: dict[str, Any]) -> list[str]:
    required = ("subject", "direction", "layout", "interactions", "accessibility", "viewports")
    errors = [f"missing {key}" for key in required if not contract.get(key)]
    viewports = contract.get("viewports", [])
    if not isinstance(viewports, list) or not viewports:
        errors.append("viewports must be a non-empty list")
    return errors


def validate_ui_contract(value: dict[str, Any]) -> list[str]:
    try:
        contract = DesignContract.from_dict(value)
        contract.validate()
    except (TypeError, ValueError) as exc:
        return [str(exc)]
    if not value.get("reference_policy"):
        return []
    policy = value["reference_policy"]
    if not isinstance(policy, dict):
        return ["reference_policy must be an object"]
    if not policy.get("borrowable") or not policy.get("forbidden"):
        return ["reference_policy must separate borrowable and forbidden attributes"]
    return []


def default_render_targets() -> tuple[RenderTarget, ...]:
    return tuple(RenderTarget(name, width, height) for name, width, height in DEFAULT_VIEWPORTS)


def _extract_subject(text: str, reference_subject: str | None) -> str:
    # A reference subject is evidence, never a replacement for the requested product.
    if reference_subject and reference_subject.lower() in text.lower():
        return reference_subject.strip()
    match = re.search(r"(?:build|create|design|make)\s+(?:an?\s+)?(.+?)(?:\.|,| for | with | that | which |$)", text, re.IGNORECASE)
    return (match.group(1) if match else text).strip()[:160]


def _extract_direction(text: str) -> str:
    lowered = text.lower()
    for terms, direction in (
        (("dashboard", "analytics", "metrics"), "data-dense operational"),
        (("store", "commerce", "shop", "product"), "clear conversion-focused"),
        (("social", "community", "feed"), "content-first social"),
        (("game", "play", "quest"), "expressive interactive"),
    ):
        if any(term in lowered for term in terms):
            return direction
    return "task-led product workspace"
