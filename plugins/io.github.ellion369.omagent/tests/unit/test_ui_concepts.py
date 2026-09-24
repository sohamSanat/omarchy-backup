from __future__ import annotations

import unittest

from omagent_core.ui_brief import (
    build_design_contract,
    generate_concept_candidates,
    validate_concept_diversity,
)


class UiConceptTests(unittest.TestCase):
    def test_non_trivial_brief_has_three_structurally_distinct_concepts(self):
        candidates = generate_concept_candidates(
            "support operations console",
            "Build a support operations console for agents to triage, assign, and resolve incidents.",
        )
        self.assertEqual(len(candidates), 3)
        result = validate_concept_diversity(candidates)
        self.assertTrue(result.valid, result.errors)
        self.assertGreaterEqual(min(result.differences, key=lambda item: item[1])[1], 3)

    def test_concept_axes_follow_product_domain(self):
        support = generate_concept_candidates("support console", "triage incidents")
        learning = generate_concept_candidates("learning platform", "guide lessons")
        self.assertNotEqual(support[0].information_architecture, learning[0].information_architecture)
        self.assertIn("incident", support[0].product_task)
        self.assertIn("lesson", learning[0].thesis)

    def test_provider_synthesis_is_used_only_when_structurally_valid(self):
        baseline = generate_concept_candidates("music player", "Build a music player")
        result = build_design_contract(
            "Build a music player",
            subject="music player",
            concept_synthesizer=lambda subject, prompt, reference: [
                {**candidate.as_dict(), "thesis": f"provider-specific {index}"}
                for index, candidate in enumerate(baseline)
            ],
        )
        self.assertEqual(result.candidates[0].thesis, "provider-specific 0")
        fallback = build_design_contract(
            "Build a music player",
            subject="music player",
            concept_synthesizer=lambda subject, prompt, reference: [baseline[0].as_dict()],
        )
        self.assertEqual(len(fallback.candidates), 3)

    def test_palette_only_changes_do_not_pass_diversity(self):
        candidates = generate_concept_candidates("a product", "Build a product")
        duplicate = candidates[0].__class__(**{**candidates[0].__dict__, "id": "palette", "title": "Palette"})
        result = validate_concept_diversity([candidates[0], duplicate, candidates[1]])
        self.assertFalse(result.valid)

    def test_reference_policy_is_separate_from_product_subject(self):
        contract = build_design_contract(
            "Build a music player using the attached reference image",
            subject="music player",
            selected_concept_id="workflow",
            reference={
                "mode": "style-only",
                "image_id": "salon.png",
                "borrowable": ["palette relationships"],
                "forbidden": ["subject", "copy", "assets", "composition"],
            },
        )
        self.assertEqual(contract.subject, "music player")
        self.assertEqual(contract.reference_policy.primary_reference_id, "salon.png")
        self.assertIn("subject", contract.reference_policy.forbidden)
        self.assertEqual(contract.viewports, ["desktop:1440x900", "tablet:768x1024", "mobile:375x812"])
        contract.validate()

    def test_recreation_mode_allows_structure_but_not_reference_content(self):
        contract = build_design_contract(
            "Recreate the visual structure of the attached reference for a music player",
            subject="music player",
            selected_concept_id="workflow",
            reference={
                "mode": "recreate",
                "image_id": "reference.png",
                "evidence_fingerprint": "abc123",
                "borrowable": ["palette relationships"],
                "forbidden": ["subject", "copy", "assets", "composition"],
            },
        )
        assert contract.reference_policy is not None
        self.assertIn("authorized composition", contract.reference_policy.borrowable)
        self.assertNotIn("reference composition", contract.reference_policy.forbidden)
        self.assertIn("reference subject", contract.reference_policy.forbidden)
        contract.validate()


if __name__ == "__main__":
    unittest.main()
