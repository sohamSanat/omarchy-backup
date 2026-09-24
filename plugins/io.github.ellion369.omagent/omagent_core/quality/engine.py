"""Evidence-first quality lifecycle with bounded repair.

The engine is deliberately independent of a provider or UI. It accepts a
quality profile, records deterministic evidence, requests an independent
review, and refuses to claim completion when a blocking gate is unresolved.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from enum import StrEnum
from typing import Any, Callable, Protocol

from .contracts import CheckResult, ReviewFinding, TaskContract
from .profiles import get_profile
from .review import ReviewReceipt


class QualityState(StrEnum):
    PLANNED = "planned"
    EXECUTING = "executing"
    VERIFYING = "verifying"
    REVIEWING = "reviewing"
    REPAIRING = "repairing"
    COMPLETED = "completed"
    BLOCKED = "blocked"
    INCOMPLETE = "incomplete"
    FAILED = "failed"


class QualityError(RuntimeError):
    """Raised when a quality operation is invoked out of order."""


class EvidenceSink(Protocol):
    def record_evidence(self, evidence: dict[str, Any]) -> None: ...


RepairRunner = Callable[
    [int, list[str]],
    tuple[list[CheckResult], ReviewReceipt | None] | None,
]


@dataclass
class QualityReport:
    profile: str
    state: str
    contract: dict[str, Any]
    checks: list[dict[str, Any]] = field(default_factory=list)
    review: list[dict[str, Any]] = field(default_factory=list)
    repair_attempts: int = 0
    repair_limit: int = 2
    unresolved: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)


class QualityEngine:
    def __init__(
        self,
        contract: TaskContract,
        *,
        sink: EvidenceSink | None = None,
        repair_limit: int = 2,
        deliverable: bool = True,
        require_review: bool = True,
    ) -> None:
        contract.validate()
        self.profile = get_profile(contract.profile)
        if repair_limit < 0:
            raise ValueError("repair_limit must not be negative")
        self.contract = contract
        self.sink = sink
        self.repair_limit = repair_limit
        self.deliverable = deliverable
        self.require_review = require_review
        self.state = QualityState.PLANNED
        self.checks: dict[str, CheckResult] = {}
        self.review_findings: list[ReviewFinding] = []
        self.repair_attempts = 0
        self.notes: list[str] = []
        self._review_complete = False
        self._record("quality_started", {"profile": contract.profile, "request": contract.request})

    def _record(self, kind: str, data: dict[str, Any]) -> None:
        evidence = {"kind": kind, "profile": self.contract.profile, **data}
        if self.sink is not None:
            self.sink.record_evidence(evidence)

    def _unresolved_review_findings(self) -> list[str]:
        return [item.title for item in self.review_findings if item.blocking and not item.resolved]

    def begin_execution(self) -> None:
        if self.state is not QualityState.PLANNED:
            raise QualityError(f"cannot execute from {self.state}")
        self.state = QualityState.EXECUTING
        self._record("execution_started", {})

    def verify(self, results: list[CheckResult]) -> bool:
        if self.state not in {QualityState.EXECUTING, QualityState.REPAIRING}:
            raise QualityError(f"cannot verify from {self.state}")
        if not results:
            raise QualityError("verification requires at least one deterministic check")
        result_names = {result.name for result in results}
        missing = set(self.profile.required_checks) - result_names
        if missing:
            raise QualityError("missing profile checks: " + ", ".join(sorted(missing)))
        self.state = QualityState.VERIFYING
        for result in results:
            result.validate()
            self.checks[result.name] = result
            self._record("check", {"name": result.name, "passed": result.passed, "evidence": result.evidence, "blocking": result.blocking})
        failed = [item.name for item in results if not item.passed and item.blocking]
        if failed:
            self.notes.append("blocking checks failed: " + ", ".join(sorted(failed)))
            return False
        return True

    def terminalize_repair_failure(self, reason: str) -> bool:
        if self.state is not QualityState.REPAIRING:
            raise QualityError(f"cannot terminalize repair from {self.state}")
        self.state = QualityState.INCOMPLETE if self.deliverable else QualityState.FAILED
        self.notes.append(f"repair could not be verified: {reason}")
        self._record("repair_terminalized", {"state": self.state.value, "reason": reason})
        return False

    def verify_with_repair(
        self,
        results: list[CheckResult],
        repair_runner: RepairRunner | None = None,
    ) -> tuple[bool, ReviewReceipt | None]:
        """Verify, run bounded same-context repairs, and verify again.

        The runner is supplied by the owning orchestration layer. Returning
        ``None`` means the repair could not produce a fresh deterministic
        result and the run must not be reported as complete.
        """
        verified = self.verify(results)
        latest_receipt: ReviewReceipt | None = None
        while not verified:
            failed = [item.name for item in self.checks.values() if item.blocking and not item.passed]
            if repair_runner is None:
                self.terminalize_failed_verification()
                return False, latest_receipt
            if not self.repair():
                return False, latest_receipt
            outcome = repair_runner(self.repair_attempts, failed)
            if outcome is None:
                self.terminalize_repair_failure("repair runner returned no evidence")
                return False, latest_receipt
            repaired_results, latest_receipt = outcome
            verified = self.verify(repaired_results)
            if not verified and self.repair_attempts >= self.repair_limit:
                self.terminalize_failed_verification()
        return verified, latest_receipt

    @staticmethod
    def _ui_review_scope_complete(receipt: ReviewReceipt) -> bool:
        return bool(
            receipt.review_scope.strip() == "ui"
            and receipt.selected_concept_id.strip()
            and receipt.render_manifest_digest.strip()
            and receipt.interaction_report_digest.strip()
            and receipt.accessibility_report_digest.strip()
        )

    def review_receipt(self, receipt: ReviewReceipt) -> bool:
        receipt.validate()
        if self.contract.profile == "ui" and not self._ui_review_scope_complete(receipt):
            self.state = QualityState.BLOCKED
            self.notes.append("UI review receipt is missing current render, interaction, accessibility, or concept scope")
            self._record("review", {"available": True, "reviewer_id": receipt.reviewer_id, "provider": receipt.provider, "provider_session_id": receipt.provider_session_id, "independent": receipt.independent, "passed": False, "ui_scope_complete": False})
            return False
        return self.review(
            receipt.findings,
            reviewer_id=receipt.reviewer_id,
            provider=receipt.provider,
            provider_session_id=receipt.provider_session_id,
            independent=receipt.independent,
            receipt_evidence=receipt.evidence,
        )

    def review(
        self,
        findings: list[ReviewFinding],
        *,
        available: bool = True,
        reviewer_id: str = "",
        provider: str = "",
        provider_session_id: str = "",
        independent: bool = True,
        receipt_evidence: list[str] | None = None,
    ) -> bool:
        if self.state is not QualityState.VERIFYING:
            raise QualityError(f"cannot review from {self.state}")
        if not available or not reviewer_id or not provider or not provider_session_id or not independent or not receipt_evidence:
            self.state = QualityState.BLOCKED
            self.notes.append("independent reviewer receipt unavailable")
            self._record("review", {"available": available, "reviewer_id": reviewer_id, "provider": provider, "provider_session_id": provider_session_id, "independent": independent, "passed": False})
            return False
        self.state = QualityState.REVIEWING
        for finding in findings:
            finding.validate()
            self.review_findings = [item for item in self.review_findings if item.title != finding.title]
            self.review_findings.append(finding)
            self._record("review_finding", {"title": finding.title, "blocking": finding.blocking, "resolved": finding.resolved, "evidence": finding.evidence})
        unresolved = self._unresolved_review_findings()
        self._record("review", {"available": True, "reviewer_id": reviewer_id, "provider": provider, "provider_session_id": provider_session_id, "independent": independent, "evidence": receipt_evidence, "passed": not unresolved})
        self._review_complete = not unresolved
        if unresolved:
            self.notes.append("blocking review findings: " + ", ".join(unresolved))
        return self._review_complete

    def terminalize_failed_verification(self) -> bool:
        if self.state is not QualityState.VERIFYING:
            raise QualityError(f"cannot terminalize verification from {self.state}")
        failed = [item.name for item in self.checks.values() if item.blocking and not item.passed]
        if not failed:
            raise QualityError("verification has no failed blocking checks")
        self.state = QualityState.INCOMPLETE if self.deliverable else QualityState.FAILED
        self.notes.append("failed verification gates: " + ", ".join(sorted(failed)))
        self._record("verification_terminalized", {"state": self.state.value, "failed": failed})
        return False

    def terminalize_unresolved_review(self) -> bool:
        """Close a review that has blocking findings but no repair execution."""
        if self.state is not QualityState.REVIEWING:
            raise QualityError(f"cannot terminalize review from {self.state}")
        unresolved = self._unresolved_review_findings()
        if not unresolved:
            return self.deliver()
        self.state = QualityState.INCOMPLETE if self.deliverable else QualityState.FAILED
        self.notes.append("unresolved independent review findings: " + ", ".join(unresolved))
        self._record("review_terminalized", {"state": self.state.value, "unresolved": unresolved})
        return False

    def repair(self) -> bool:
        if self.state not in {QualityState.VERIFYING, QualityState.REVIEWING}:
            raise QualityError(f"cannot repair from {self.state}")
        if self.repair_attempts >= self.repair_limit:
            self.state = QualityState.INCOMPLETE if self.deliverable else QualityState.FAILED
            self.notes.append("repair limit exhausted")
            self._record("repair_limit", {"state": self.state.value, "attempts": self.repair_attempts})
            return False
        self.repair_attempts += 1
        self.state = QualityState.REPAIRING
        self._record("repair_started", {"attempt": self.repair_attempts})
        return True

    def deliver(self) -> bool:
        if self.require_review and (self.state is not QualityState.REVIEWING or not self._review_complete):
            self.notes.append("delivery requires a completed independent review")
            return False
        if not self.require_review and self.state not in {QualityState.VERIFYING, QualityState.REVIEWING}:
            self.notes.append("delivery requires completed deterministic checks")
            return False
        failed = [item.name for item in self.checks.values() if item.blocking and not item.passed]
        unresolved = self._unresolved_review_findings()
        if failed or unresolved:
            self.notes.append("delivery blocked by unresolved quality gates")
            return False
        self.state = QualityState.COMPLETED
        self._record("quality_completed", {"checks": len(self.checks), "review_findings": len(self.review_findings)})
        return True

    def report(self) -> QualityReport:
        unresolved = [item.name for item in self.checks.values() if item.blocking and not item.passed]
        unresolved.extend(self._unresolved_review_findings())
        return QualityReport(
            profile=self.contract.profile,
            state=self.state.value,
            contract={
                "request": self.contract.request,
                "profile": self.contract.profile,
                "acceptance_criteria": list(self.contract.acceptance_criteria),
                "constraints": list(self.contract.constraints),
                "assumptions": list(self.contract.assumptions),
            },
            checks=[{"name": item.name, "passed": item.passed, "evidence": list(item.evidence), "blocking": item.blocking} for item in self.checks.values()],
            review=[{"title": item.title, "blocking": item.blocking, "resolved": item.resolved, "evidence": list(item.evidence)} for item in self.review_findings],
            repair_attempts=self.repair_attempts,
            repair_limit=self.repair_limit,
            unresolved=unresolved,
            notes=list(self.notes),
        )
