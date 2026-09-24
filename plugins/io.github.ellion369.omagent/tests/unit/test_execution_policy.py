from __future__ import annotations

import unittest

from omagent_core.execution_policy import ExecutionMode, assess_execution_policy


class ExecutionPolicyTests(unittest.TestCase):
    def test_small_coding_edit_uses_needle_budget(self):
        policy = assess_execution_policy("Fix a typo in the README and update the label", is_coding=True)
        self.assertEqual(policy.mode, ExecutionMode.NEEDLE)
        self.assertEqual(policy.max_agents, 1)
        self.assertEqual(policy.max_minutes, 10)
        self.assertFalse(policy.use_fleet)
        self.assertFalse(policy.require_independent_review)

    def test_security_refactor_uses_sword_budget(self):
        policy = assess_execution_policy("Refactor the authentication database migration", is_coding=True)
        self.assertEqual(policy.mode, ExecutionMode.SWORD)
        self.assertTrue(policy.use_fleet)
        self.assertTrue(policy.require_independent_review)

    def test_ui_never_collapses_to_needle(self):
        policy = assess_execution_policy("Fix a typo in the UI", is_ui=True)
        self.assertEqual(policy.mode, ExecutionMode.STANDARD)
        self.assertIn("rendered", policy.prompt_directive().lower())

    def test_prompt_contains_explicit_small_tool_rule(self):
        directive = assess_execution_policy("Add a test for the parser", is_coding=True).prompt_directive()
        self.assertIn("smallest tool", directive)
        self.assertIn("Do not spawn subagents", directive)


if __name__ == "__main__":
    unittest.main()
