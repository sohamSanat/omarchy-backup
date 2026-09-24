"""Authoritative run-scoped context for the agentic UI-making loop."""
from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass, field
from typing import Any

from .ui_brief import DEFAULT_VIEWPORTS, DesignContract

UI_CONTEXT_VERSION = "ui-context/v1"
_SAFE_VIEWPORT = re.compile(r"^[a-z0-9-]+:\d+x\d+$")


def normalize_viewports(values: Any) -> list[str]:
    """Normalize one viewport authority for contracts, captures, and QA."""
    if values is None:
        values = DEFAULT_VIEWPORTS
    if isinstance(values, (str, bytes)):
        values = [values]
    result: list[str] = []
    for value in values:
        if isinstance(value, dict):
            name = str(value.get("name", "")).strip().lower()
            width = int(value.get("width", 0))
            height = int(value.get("height", 0))
            value = f"{name}:{width}x{height}"
        else:
            value = str(value).strip().lower().replace(" ", "")
        if not value:
            continue
        if not _SAFE_VIEWPORT.fullmatch(value):
            raise ValueError(f"invalid viewport: {value}")
        if value not in result:
            result.append(value)
    if not result:
        raise ValueError("at least one viewport is required")
    return result


@dataclass
class UiRunContext:
    request: str
    subject: str
    candidate_ids: list[str] = field(default_factory=list)
    selected_concept_id: str = ""
    reference_evidence: dict[str, Any] = field(default_factory=dict)
    viewports: list[str] = field(default_factory=lambda: list(DEFAULT_VIEWPORTS))
    workspace: str = ""
    artifact_revision: str = ""
    evidence_generation: str = ""
    render_manifest: dict[str, Any] = field(default_factory=dict)
    interaction_report: dict[str, Any] = field(default_factory=dict)
    accessibility_report: dict[str, Any] = field(default_factory=dict)
    review_state: dict[str, Any] = field(default_factory=dict)
    repair_history: list[dict[str, Any]] = field(default_factory=list)
    state: str = "planned"
    skill_bundle: dict[str, Any] = field(default_factory=dict)
    version: str = UI_CONTEXT_VERSION

    def validate(self) -> None:
        if self.version != UI_CONTEXT_VERSION:
            raise ValueError(f"unsupported UI context version: {self.version}")
        if not self.request.strip() or not self.subject.strip():
            raise ValueError("UI context requires a request and subject")
        self.viewports = normalize_viewports(self.viewports)
        if not self.candidate_ids:
            raise ValueError("UI context requires at least one concept candidate")
        if len(set(self.candidate_ids)) != len(self.candidate_ids):
            raise ValueError("UI context concept ids must be unique")
        if self.selected_concept_id and self.selected_concept_id not in self.candidate_ids:
            raise ValueError("selected concept is not part of the UI context")
        if not self.evidence_generation:
            raise ValueError("UI context requires an evidence generation")

    def as_dict(self) -> dict[str, Any]:
        return {
            "version": self.version,
            "request": self.request,
            "subject": self.subject,
            "candidate_ids": list(self.candidate_ids),
            "selected_concept_id": self.selected_concept_id,
            "reference_evidence": dict(self.reference_evidence),
            "viewports": list(self.viewports),
            "workspace": self.workspace,
            "artifact_revision": self.artifact_revision,
            "evidence_generation": self.evidence_generation,
            "render_manifest": dict(self.render_manifest),
            "interaction_report": dict(self.interaction_report),
            "accessibility_report": dict(self.accessibility_report),
            "review_state": dict(self.review_state),
            "repair_history": list(self.repair_history),
            "state": self.state,
            "skill_bundle": dict(self.skill_bundle),
        }

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> "UiRunContext":
        if not isinstance(value, dict):
            raise ValueError("UI context must be an object")
        return cls(
            request=str(value.get("request", "")),
            subject=str(value.get("subject", "")),
            candidate_ids=[str(item) for item in value.get("candidate_ids", [])],
            selected_concept_id=str(value.get("selected_concept_id", "")),
            reference_evidence=dict(value.get("reference_evidence", {})),
            viewports=normalize_viewports(value.get("viewports", DEFAULT_VIEWPORTS)),
            workspace=str(value.get("workspace", "")),
            artifact_revision=str(value.get("artifact_revision", "")),
            evidence_generation=str(value.get("evidence_generation", "")),
            render_manifest=dict(value.get("render_manifest", {})),
            interaction_report=dict(value.get("interaction_report", {})),
            accessibility_report=dict(value.get("accessibility_report", {})),
            review_state=dict(value.get("review_state", {})),
            repair_history=list(value.get("repair_history", [])),
            state=str(value.get("state", "planned")),
            skill_bundle=dict(value.get("skill_bundle", {})),
            version=str(value.get("version", UI_CONTEXT_VERSION)),
        )

    def digest(self) -> str:
        payload = json.dumps(self.as_dict(), sort_keys=True, separators=(",", ":"))
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def context_from_contract(
    contract: DesignContract,
    *,
    run_id: str = "",
    workspace: str = "",
    artifact_revision: str = "",
    evidence_generation: str = "",
    state: str = "planned",
    reference_evidence: dict[str, Any] | None = None,
) -> UiRunContext:
    context = UiRunContext(
        request=contract.request,
        subject=contract.subject,
        candidate_ids=[candidate.id for candidate in contract.candidates],
        selected_concept_id=contract.selected_concept_id,
        reference_evidence=dict(reference_evidence or (contract.reference_policy.as_dict() if contract.reference_policy else {})),
        viewports=normalize_viewports(contract.viewports),
        workspace=workspace,
        artifact_revision=artifact_revision,
        evidence_generation=(evidence_generation or f"evidence-{run_id}") if run_id else (evidence_generation or "evidence-unbound"),
        state=state,
    )
    context.validate()
    return context
