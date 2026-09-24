from __future__ import annotations

import json
import unittest
from pathlib import Path

from tests.support.isolated_env import isolated_process_env, run_router


PLUGIN = Path(__file__).resolve().parents[2]


class CurrentBehaviorTests(unittest.TestCase):
    def test_router_declares_dry_run_but_does_not_use_it(self):
        source = (PLUGIN / "omagent-route").read_text(encoding="utf-8")
        self.assertIn("DRY_RUN = os.environ.get", source)
        self.assertNotIn("if DRY_RUN:", source)

    def test_qml_sends_explicit_agentic_harness_and_model(self):
        source = (PLUGIN / "Omagent.qml").read_text(encoding="utf-8")
        self.assertIn('property bool autoMode: true', source)
        self.assertIn('property bool autoProvider: true', source)
        self.assertIn('if (!root.autoProvider && root.activeHarness)', source)
        self.assertIn('argv.push("--harness", root.activeHarness)', source)
        self.assertIn('argv.push("--model", root.activeModel)', source)
        self.assertIn('argv.push("--track", root.agenticTrack)', source)

    def test_gemini_key_is_sent_as_a_header_not_a_url_parameter(self):
        source = (PLUGIN / "omagent-route").read_text(encoding="utf-8")
        self.assertNotIn("?key={api_key}", source)
        self.assertNotIn("key={api_key}", source)
        self.assertIn('"x-goog-api-key": api_key', source)

    def test_current_router_keeps_dangerous_provider_flags(self):
        source = (PLUGIN / "omagent-route").read_text(encoding="utf-8")
        self.assertIn("--dangerously-skip-permissions", source)
        self.assertIn("--auto-approve true", source)
        self.assertIn("opencode run --auto", source)

    def test_current_router_list_sessions_is_json_in_isolated_home(self):
        with isolated_process_env() as (env, _root):
            result = run_router(["--list-sessions"], env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIsInstance(json.loads(result.stdout), list)

    def test_router_harness_list_uses_the_shared_catalog(self):
        from omagent_core.catalog import load_harness_catalog

        with isolated_process_env() as (env, _root):
            result = run_router(["--list-harnesses"], env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), load_harness_catalog())


if __name__ == "__main__":
    unittest.main()
