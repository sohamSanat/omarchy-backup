"""Independent reviewer receipt contract and file boundary.

A reviewer may write this receipt from its own provider session. The quality
engine accepts it only when the reviewer identity is explicit, independent,
and backed by evidence; the implementer's completion text is not a receipt.
"""
from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

from .contracts import ReviewFinding


@dataclass(frozen=True)
class ReviewReceipt:
    reviewer_id: str
    provider: str
    provider_session_id: str
    independent: bool
    evidence: list[str]
    findings: list[ReviewFinding]
    run_id: str = ""
    workspace: str = ""
    evidence_generation: str = ""
    artifact_revision: str = ""
    review_scope: str = ""
    selected_concept_id: str = ""
    render_manifest_digest: str = ""
    interaction_report_digest: str = ""
    accessibility_report_digest: str = ""

    def validate(self) -> None:
        if not self.reviewer_id.strip():
            raise ValueError("review receipt requires reviewer_id")
        if not self.provider.strip() or not self.provider_session_id.strip():
            raise ValueError("review receipt requires provider identity")
        if not self.run_id.strip() or not self.workspace.strip():
            raise ValueError("review receipt requires run and workspace binding")
        if not self.evidence_generation.strip() or not self.artifact_revision.strip():
            raise ValueError("review receipt requires evidence and artifact binding")
        if not self.independent:
            raise ValueError("review receipt must be independent")
        if not self.evidence:
            raise ValueError("review receipt requires evidence")
        for finding in self.findings:
            finding.validate()

    def as_dict(self) -> dict[str, Any]:
        return {
            "reviewer_id": self.reviewer_id,
            "provider": self.provider,
            "provider_session_id": self.provider_session_id,
            "run_id": self.run_id,
            "workspace": self.workspace,
            "evidence_generation": self.evidence_generation,
            "artifact_revision": self.artifact_revision,
            "review_scope": self.review_scope,
            "selected_concept_id": self.selected_concept_id,
            "render_manifest_digest": self.render_manifest_digest,
            "interaction_report_digest": self.interaction_report_digest,
            "accessibility_report_digest": self.accessibility_report_digest,
            "independent": self.independent,
            "evidence": list(self.evidence),
            "findings": [asdict(item) for item in self.findings],
        }

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> "ReviewReceipt":
        if not isinstance(value, dict):
            raise ValueError("review receipt must be an object")
        identity_fields = (
            "reviewer_id", "provider", "provider_session_id", "run_id",
            "workspace", "evidence_generation", "artifact_revision",
        )
        for name in identity_fields:
            if not isinstance(value.get(name), str) or not value[name].strip():
                raise ValueError(f"review receipt {name} must be a non-empty string")
        if value.get("independent") is not True:
            raise ValueError("review receipt independent must be true")
        evidence = value.get("evidence")
        if not isinstance(evidence, list) or not evidence or any(not isinstance(item, str) or not item.strip() for item in evidence):
            raise ValueError("review receipt evidence must be a non-empty list of strings")
        findings_value = value.get("findings")
        if not isinstance(findings_value, list) or any(not isinstance(item, dict) for item in findings_value):
            raise ValueError("review receipt findings must be a list of objects")
        findings = [ReviewFinding(**item) for item in findings_value]
        optional_fields = {
            name: str(value.get(name, ""))
            for name in (
                "review_scope", "selected_concept_id", "render_manifest_digest",
                "interaction_report_digest", "accessibility_report_digest",
            )
        }
        receipt = cls(
            reviewer_id=value["reviewer_id"],
            provider=value["provider"],
            provider_session_id=value["provider_session_id"],
            independent=True,
            evidence=evidence,
            findings=findings,
            run_id=value["run_id"],
            workspace=value["workspace"],
            evidence_generation=value["evidence_generation"],
            artifact_revision=value["artifact_revision"],
            **optional_fields,
        )
        receipt.validate()
        return receipt


def write_review_receipt(path: Path | str, receipt: ReviewReceipt) -> None:
    receipt.validate()
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_suffix(target.suffix + ".tmp")
    temporary.write_text(json.dumps(receipt.as_dict(), indent=2) + "\n", encoding="utf-8")
    temporary.replace(target)


def load_review_receipt(path: Path | str) -> ReviewReceipt | None:
    source = Path(path)
    if not source.is_file():
        return None
    try:
        return ReviewReceipt.from_dict(json.loads(source.read_text(encoding="utf-8")))
    except (OSError, ValueError, TypeError):
        return None
