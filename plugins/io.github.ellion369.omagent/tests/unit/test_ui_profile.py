from __future__ import annotations

import unittest

from omagent_core.quality.ui_profile import build_adaptive_brief, default_render_targets, validate_design_contract
from omagent_core.reference_analysis import inspect_reference


class UiProfileTests(unittest.TestCase):
    def test_detailed_ui_request_proceeds_without_fixed_interview(self):
        brief = build_adaptive_brief("Build a responsive analytics dashboard for support teams with keyboard navigation and clear empty states")
        self.assertEqual(brief.blocking_questions, [])
        self.assertIn("analytics", brief.subject)
        brief.validate()

    def test_short_or_reference_ambiguous_request_asks_only_blocking_question(self):
        brief = build_adaptive_brief("Build a reference-inspired page")
        self.assertTrue(brief.blocking_questions)
        self.assertEqual(len(brief.blocking_questions), 1)

    def test_reference_subject_does_not_replace_requested_product(self):
        brief = build_adaptive_brief("Build a music player with a reference image", reference_subject="financial dashboard")
        self.assertIn("music player", brief.subject)
        self.assertNotIn("financial dashboard", brief.subject)

    def test_render_targets_and_contract_validation_are_explicit(self):
        targets = default_render_targets()
        self.assertEqual([(item.name, item.width, item.height) for item in targets], [("desktop", 1440, 900), ("tablet", 768, 1024), ("mobile", 375, 812)])
        errors = validate_design_contract({"subject": "x", "direction": "y", "layout": ["a"], "interactions": ["b"], "accessibility": ["c"]})
        self.assertTrue(any("viewports" in error for error in errors))

    def test_reference_metadata_is_optional_and_never_claims_semantics(self):
        evidence = inspect_reference(__file__, subject="requested product")
        self.assertEqual(evidence.subject, "requested product")
        self.assertIn("subject", evidence.as_dict())


if __name__ == "__main__":
    unittest.main()
