"""Deterministic acceptance-gate definitions for each quality profile."""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class ProfileSpec:
    name: str
    required_checks: tuple[str, ...]
    evidence_kinds: tuple[str, ...]


PROFILES: dict[str, ProfileSpec] = {
    "direct": ProfileSpec("direct", ("instruction_coverage", "context_use", "clarity", "uncertainty"), ("context", "answer")),
    "web": ProfileSpec("web", ("retrieval_honesty", "source_quality", "grounding", "injection_resistance", "failure_behavior"), ("retrieval", "citation", "answer")),
    "coding": ProfileSpec("coding", ("task_contract", "implementation", "verification", "review"), ("plan", "command", "diff", "review")),
    "ui": ProfileSpec("ui", ("subject_fidelity", "design_contract", "reference_boundary", "reference_fidelity", "concept_novelty", "rendered_evidence", "interaction_quality", "accessibility", "visual_review"), ("contract", "reference", "render", "visual", "check", "review")),
}


def get_profile(name: str) -> ProfileSpec:
    try:
        return PROFILES[name]
    except KeyError as exc:
        raise ValueError(f"unknown quality profile: {name}") from exc
