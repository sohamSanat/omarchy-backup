from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from omagent_core.browser_adapter import FakeBrowserAdapter, UnavailableBrowserAdapter
from omagent_core.ui_evidence import InteractionState, LocalTarget, UiEvidenceResult


class UiEvidenceTests(unittest.TestCase):
    def test_fake_adapter_is_complete_but_not_live_eligible(self):
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory)
            target = LocalTarget("http://127.0.0.1:4173", "127.0.0.1", 4173, "run-1", "vite", True)
            result = FakeBrowserAdapter().capture(
                run_id="run-1",
                workspace=str(workspace),
                target=target,
                contract_digest="contract-1",
                viewports=["desktop:1440x900", "mobile:375x812"],
                states=[InteractionState("initial", (), (), ("renders",), ("desktop:1440x900", "mobile:375x812"))],
                artifact_revision="git-1",
                evidence_generation="evidence-1",
            )
        self.assertEqual(len(result.manifest.renders), 2)
        self.assertEqual(result.manifest.mode, "test_fake")
        self.assertFalse(result.live_eligible)
        result.validate()

    def test_unavailable_live_adapter_is_not_complete(self):
        result = UnavailableBrowserAdapter().capture(
            run_id="run-1",
            workspace="/tmp/workspace",
            target=LocalTarget("http://127.0.0.1:4173", "127.0.0.1", 4173, "run-1"),
            contract_digest="contract-1",
            viewports=["desktop:1440x900"],
            states=[],
            artifact_revision="git-1",
            evidence_generation="evidence-1",
        )
        self.assertFalse(result.live_eligible)
        self.assertIn("browser capability unavailable", result.errors)


if __name__ == "__main__":
    unittest.main()
