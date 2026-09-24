from __future__ import annotations

import unittest

from omagent_core.ui_skill_bundle import UI_SKILL_BUNDLE_VERSION, impeccable_ui_bundle


class UiSkillBundleTests(unittest.TestCase):
    def test_impeccable_is_the_primary_ui_skill(self):
        bundle = impeccable_ui_bundle()
        self.assertEqual(bundle.version, UI_SKILL_BUNDLE_VERSION)
        self.assertEqual(bundle.primary_skill, "impeccable")
        self.assertEqual(bundle.reviewer_skill, "impeccable")
        self.assertIn("web-design-engineer", bundle.supporting_skills)
        self.assertIn("visual-critique", bundle.supporting_skills)
        self.assertIn("accessibility-audit", bundle.supporting_skills)
        self.assertIn("ce-test-browser", bundle.supporting_skills)

    def test_prompt_requires_rendered_critique_and_anti_slop(self):
        directive = impeccable_ui_bundle().prompt_directive()
        self.assertIn("Render the actual artifact", directive)
        self.assertIn("visual-critique", directive)
        self.assertIn("generic dashboard", directive)
        self.assertIn("provider prose cannot certify", directive)


if __name__ == "__main__":
    unittest.main()
