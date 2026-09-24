from __future__ import annotations

import unittest

from omagent_core.quality import CheckResult, QualityEngine, ReviewFinding, ReviewReceipt, TaskContract


class QualityEngineTests(unittest.TestCase):
    def checks(self, *, failed: str | None = None) -> list[CheckResult]:
        names = ("task_contract", "implementation", "verification", "review")
        return [CheckResult(name, passed=(name != failed), evidence=[f"{name} evidence"]) for name in names]

    def make_engine(self, *, deliverable: bool = True, limit: int = 2) -> QualityEngine:
        return QualityEngine(
            TaskContract(
                request="Build the requested thing",
                profile="coding",
                acceptance_criteria=["focused verification passes"],
            ),
            deliverable=deliverable,
            repair_limit=limit,
        )

    def test_review_receipt_round_trips_findings_and_identity(self):
        from omagent_core.quality.review import load_review_receipt, write_review_receipt
        import tempfile
        from pathlib import Path

        receipt = ReviewReceipt(
            reviewer_id="reviewer-1",
            provider="opencode",
            provider_session_id="provider-session-1",
            independent=True,
            evidence=["review receipt"],
            findings=[ReviewFinding("needs a regression test", True, ["reviewer inspected diff"])],
            run_id="run-1",
            workspace="/tmp/work",
            evidence_generation="evidence-run-1",
            artifact_revision="revision-1",
        )
        with tempfile.TemporaryDirectory(prefix="omagent-review-") as directory:
            path = Path(directory) / "receipt.json"
            write_review_receipt(path, receipt)
            loaded = load_review_receipt(path)
        self.assertEqual(loaded.reviewer_id, "reviewer-1")
        self.assertEqual(loaded.findings[0].title, "needs a regression test")

    def test_malformed_review_receipt_is_rejected(self):
        from omagent_core.quality.review import ReviewReceipt

        for value in (
            {"reviewer_id": "r", "provider": "p", "provider_session_id": "s", "independent": "true", "evidence": ["e"]},
            {"reviewer_id": "r", "provider": "p", "provider_session_id": "s", "independent": True, "evidence": "e"},
            {"reviewer_id": "r", "provider": "p", "provider_session_id": "s", "independent": True, "evidence": ["e"], "findings": {}},
            {"reviewer_id": "r", "provider": "p", "provider_session_id": "s", "independent": True, "evidence": ["e"], "findings": [{"title": 1, "blocking": True, "evidence": ["e"], "resolved": False}]},
            {"reviewer_id": "r", "provider": "p", "provider_session_id": "s", "independent": True, "evidence": ["e"], "findings": [{"title": "x", "blocking": True, "evidence": ["e"], "resolved": "false"}]},
        ):
            with self.assertRaises(ValueError):
                ReviewReceipt.from_dict(value)

    def test_ui_receipt_must_scope_current_visual_evidence(self):
        ui_checks = [
            CheckResult(name, True, [f"{name} evidence"])
            for name in (
                "subject_fidelity", "design_contract", "reference_boundary",
                "reference_fidelity", "concept_novelty", "rendered_evidence",
                "interaction_quality", "accessibility", "visual_review",
            )
        ]
        engine = QualityEngine(TaskContract(request="Build a UI", profile="ui", acceptance_criteria=["UI evidence passes"]))
        engine.begin_execution()
        self.assertTrue(engine.verify(ui_checks))
        generic = ReviewReceipt(
            reviewer_id="reviewer-1", provider="opencode", provider_session_id="session-1",
            independent=True, evidence=["generic"], findings=[], run_id="run-1",
            workspace="/tmp/work", evidence_generation="evidence-1", artifact_revision="revision-1",
        )
        self.assertFalse(engine.review_receipt(generic))
        self.assertEqual(engine.report().state, "blocked")

    def test_completed_requires_verification_and_independent_review(self):
        engine = self.make_engine()
        engine.begin_execution()
        self.assertTrue(engine.verify(self.checks()))
        self.assertTrue(engine.review([], reviewer_id="reviewer-1", provider="opencode", provider_session_id="session-1", receipt_evidence=["review receipt"]))
        self.assertTrue(engine.deliver())
        report = engine.report()
        self.assertEqual(report.state, "completed")
        self.assertEqual(report.unresolved, [])

    def test_failed_gate_enters_bounded_repair_then_incomplete(self):
        engine = self.make_engine(limit=1)
        engine.begin_execution()
        self.assertFalse(engine.verify(self.checks(failed="verification")))
        self.assertTrue(engine.repair())
        self.assertFalse(engine.verify(self.checks(failed="verification")))
        self.assertFalse(engine.repair())
        self.assertEqual(engine.report().state, "incomplete")
        self.assertEqual(engine.report().repair_attempts, 1)

    def test_bounded_repair_runner_reverifies_fresh_evidence(self):
        engine = self.make_engine(limit=1)
        engine.begin_execution()
        calls = []

        def repair(attempt, failed):
            calls.append((attempt, failed))
            return self.checks(), None

        verified, receipt = engine.verify_with_repair(self.checks(failed="verification"), repair)
        self.assertTrue(verified)
        self.assertIsNone(receipt)
        self.assertEqual(calls, [(1, ["verification"])])
        self.assertEqual(engine.report().repair_attempts, 1)

    def test_reviewer_unavailability_is_blocked_not_self_certified(self):
        engine = self.make_engine()
        engine.begin_execution()
        engine.verify(self.checks())
        self.assertFalse(engine.review([], available=False))
        self.assertEqual(engine.report().state, "blocked")
        self.assertFalse(engine.deliver())

    def test_empty_review_without_receipt_cannot_complete(self):
        engine = self.make_engine()
        engine.begin_execution()
        engine.verify(self.checks())
        self.assertFalse(engine.review([]))
        self.assertEqual(engine.report().state, "blocked")

    def test_blocking_review_finding_requires_repair_and_reverification(self):
        engine = self.make_engine()
        engine.begin_execution()
        engine.verify(self.checks())
        self.assertFalse(engine.review([ReviewFinding("missing regression test", True, ["reviewer inspected diff"])], reviewer_id="reviewer-1", provider="opencode", provider_session_id="session-1", receipt_evidence=["review receipt"]))
        self.assertTrue(engine.repair())
        self.assertTrue(engine.verify(self.checks()))
        self.assertTrue(engine.review([ReviewFinding("missing regression test", True, ["repair added and verified the regression test"], resolved=True)], reviewer_id="reviewer-1", provider="opencode", provider_session_id="session-1", receipt_evidence=["review receipt"]))
        self.assertTrue(engine.deliver())


if __name__ == "__main__":
    unittest.main()
