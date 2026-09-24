from __future__ import annotations

import unittest

from omagent_core.ui_brief import build_design_contract
from omagent_core.ui_context import UiRunContext, context_from_contract, normalize_viewports


class UiContextTests(unittest.TestCase):
    def test_context_round_trip_preserves_reference_and_selected_concept(self):
        contract = build_design_contract(
            "Build a music player with a reference image",
            subject="music player",
            selected_concept_id="atlas",
            reference={
                "mode": "style-only",
                "image_id": "reference.png",
                "borrowable": ["palette relationships"],
                "forbidden": ["subject", "assets"],
            },
        )
        context = context_from_contract(
            contract,
            run_id="run-1",
            workspace="/tmp/workspace",
            artifact_revision="git-abc",
            reference_evidence={
                "image_id": "reference.png",
                "evidence_fingerprint": "abc",
                "forbidden": ["subject", "assets"],
            },
        )
        restored = UiRunContext.from_dict(context.as_dict())
        self.assertEqual(restored.selected_concept_id, "atlas")
        self.assertEqual(restored.reference_evidence["image_id"], "reference.png")
        self.assertEqual(restored.artifact_revision, "git-abc")
        self.assertEqual(restored.digest(), context.digest())

    def test_viewport_normalization_is_single_authority(self):
        self.assertEqual(
            normalize_viewports([{"name": "Desktop", "width": 1440, "height": 900}, "tablet:768x1024"]),
            ["desktop:1440x900", "tablet:768x1024"],
        )
        with self.assertRaises(ValueError):
            normalize_viewports(["desktop:bad"])

    def test_context_rejects_unknown_selected_concept(self):
        context = UiRunContext(
            request="Build a page",
            subject="page",
            candidate_ids=["one"],
            selected_concept_id="missing",
            evidence_generation="evidence-1",
        )
        with self.assertRaises(ValueError):
            context.validate()


if __name__ == "__main__":
    unittest.main()
