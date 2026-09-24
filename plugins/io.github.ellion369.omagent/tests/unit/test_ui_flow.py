from __future__ import annotations

import unittest

from omagent_core.ui_flow import UiFlowAction, parse_concept_selection


class UiFlowTests(unittest.TestCase):
    def setUp(self):
        self.candidates = [
            {"id": "workflow", "title": "Flow"},
            {"id": "atlas", "title": "Atlas"},
            {"id": "signal", "title": "Signal"},
        ]

    def test_selection_supports_number_id_and_title(self):
        self.assertEqual(parse_concept_selection("2", self.candidates).concept_id, "atlas")
        self.assertEqual(parse_concept_selection("signal", self.candidates).concept_id, "signal")
        self.assertEqual(parse_concept_selection("Atlas", self.candidates).concept_id, "atlas")

    def test_follow_up_is_same_run_and_new_task_is_explicit(self):
        self.assertEqual(parse_concept_selection("continue", self.candidates).action, UiFlowAction.CONTINUE_SAME_RUN)
        self.assertEqual(parse_concept_selection("new task", self.candidates).action, UiFlowAction.START_NEW_TASK)

    def test_proceed_does_not_implicitly_select(self):
        decision = parse_concept_selection("proceed", self.candidates)
        self.assertEqual(decision.action, UiFlowAction.CONTINUE_SAME_RUN)
        self.assertEqual(decision.concept_id, "")


if __name__ == "__main__":
    unittest.main()
