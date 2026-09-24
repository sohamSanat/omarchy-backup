from __future__ import annotations

import contextlib
import importlib.machinery
import importlib.util
import io
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from omagent_core.controller import RunController


MODULE_PATH = Path(__file__).resolve().parents[2] / "omagent-route"


def load_router():
    loader = importlib.machinery.SourceFileLoader("omagent_route_ui_test", str(MODULE_PATH))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class UiRouteTests(unittest.TestCase):
    def test_normal_coding_follow_up_is_not_a_new_task(self):
        router = load_router()
        self.assertFalse(router.is_new_project_directive("fix the API error"))
        self.assertTrue(router.is_new_project_directive("build the UI"))

    def test_ui_route_starts_concept_flow_without_fixed_set_menu(self):
        router = load_router()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            router.STATE_DIR = root / "state"
            router.SESSION_DIR = router.STATE_DIR / "sessions"
            router.SESSION_DIR.mkdir(parents=True)
            router.CURRENT_RUN_ID = ""
            with contextlib.redirect_stdout(io.StringIO()):
                result = router.route_ui_creation_request(
                    "ui-test-session",
                    "Build a responsive product interface with a clear primary action.",
                    {},
                )
            self.assertEqual(result, 0)
            state = router.get_pending_grill_me("ui-test-session")
            self.assertIsNotNone(state)
            assert state is not None
            self.assertEqual(state["flow"], "ui_concepts/v1")
            self.assertEqual(state["status"], "awaiting_concept")
            self.assertEqual(len(state["contract"]["candidates"]), 3)
            self.assertNotIn("ui_set", state)

    def test_concept_parser_accepts_ids_and_numbers_only(self):
        router = load_router()
        options = [{"id": "workflow"}, {"id": "atlas"}, {"id": "signal"}]
        self.assertEqual(router._parse_concept_selection("2", options), "atlas")
        self.assertEqual(router._parse_concept_selection("signal", options), "signal")
        self.assertEqual(router._parse_concept_selection("proceed", options), "")

    def test_ui_quality_requires_rendered_and_interaction_evidence(self):
        router = load_router()
        contract = router.build_design_contract(
            "Build a product interface",
            selected_concept_id="workflow",
        ).as_dict()
        checks = router._ui_quality_checks(contract, ["ui_interaction: passed", "ui_accessibility: passed"])
        by_name = {item.name: item for item in checks}
        self.assertTrue(by_name["subject_fidelity"].passed)
        self.assertFalse(by_name["rendered_evidence"].passed)
        self.assertFalse(by_name["interaction_quality"].passed)
        self.assertFalse(by_name["accessibility"].passed)
        self.assertIn("concept_novelty", by_name)

    def test_ui_quality_terminalizes_without_rendered_evidence(self):
        router = load_router()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            router.STATE_DIR = root / "state"
            router.SESSION_DIR = router.STATE_DIR / "sessions"
            router.CONTROLLER_DB_PATH = router.STATE_DIR / "controller.sqlite"
            router._SESSION_STORE = None
            router._SESSION_STORE_PATH = None
            run = RunController(router._get_session_store()).start("quality-session", "Build a product interface")
            contract = router.build_design_contract("Build a product interface", selected_concept_id="workflow").as_dict()
            with contextlib.redirect_stdout(io.StringIO()):
                state = router.record_lane_quality(
                    "ui",
                    "Build a product interface",
                    "provider response",
                    evidence=["ui_interaction: passed", "ui_accessibility: passed"],
                    run_id=run.run_id,
                    ui_contract=contract,
                )
            self.assertEqual(state, "incomplete")
            self.assertEqual(router._get_session_store().state(run.run_id), "incomplete")
            router._get_session_store().close()
            router._SESSION_STORE = None
            router._SESSION_STORE_PATH = None

    def test_explicit_delegated_selection_is_recorded(self):
        router = load_router()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            router.STATE_DIR = root / "state"
            router.SESSION_DIR = router.STATE_DIR / "sessions"
            router.SESSION_DIR.mkdir(parents=True)
            with contextlib.redirect_stdout(io.StringIO()):
                router.route_ui_creation_request("delegated-session", "Build a product interface", {})
                state = router.get_pending_grill_me("delegated-session")
                assert state is not None
                with patch.object(router, "run_lane_coding", return_value=0) as run_lane:
                    router.handle_pending_ui_flow("delegated-session", "you decide", state, {})
            self.assertTrue(run_lane.called)
            self.assertEqual(router.get_pending_grill_me("delegated-session"), None)

    def test_concept_selection_keeps_the_same_pending_run(self):
        router = load_router()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            router.STATE_DIR = root / "state"
            router.SESSION_DIR = router.STATE_DIR / "sessions"
            router.SESSION_DIR.mkdir(parents=True)
            router.CURRENT_RUN_ID = ""
            with contextlib.redirect_stdout(io.StringIO()):
                router.route_ui_creation_request(
                    "ui-test-session",
                    "Build a responsive product interface with a clear primary action.",
                    {},
                )
                state = router.get_pending_grill_me("ui-test-session")
                assert state is not None
                with patch.object(router, "run_lane_coding", return_value=0) as run_lane:
                    result = router.handle_pending_ui_flow("ui-test-session", "2", state, {})
            self.assertEqual(result, 0)
            run_lane.assert_called_once()
            self.assertEqual(router.get_pending_grill_me("ui-test-session"), None)
            self.assertEqual(run_lane.call_args.kwargs["ui_contract"]["selected_concept_id"], "atlas")


if __name__ == "__main__":
    unittest.main()
