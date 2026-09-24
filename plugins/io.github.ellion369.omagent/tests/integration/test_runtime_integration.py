from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from omagent_core.orchestration.firstmate import FirstmateAdapter, FirstmateError
from omagent_core.orchestration.herdr import HerdrAdapter, HerdrError
from omagent_core.quality import CheckResult, QualityEngine, TaskContract


class FakeHerdr:
    def __init__(self, *, incomplete_split: bool = False) -> None:
        self.calls: list[list[str]] = []
        self.incomplete_split = incomplete_split

    def __call__(self, command, **_kwargs):
        command = list(command)
        self.calls.append(command)
        if command[1:3] == ["workspace", "create"]:
            payload = {"result": {"workspace": {"workspace_id": "ws-1"}, "tab": {"tab_id": "tab-1"}, "root_pane": {"pane_id": "pane-root"}}}
        elif command[1:3] == ["pane", "split"]:
            if self.incomplete_split:
                payload = {"result": {"pane": {}}}
            else:
                pane = {"right": "pane-motion", "down": "pane-dom"}[command[5]]
                payload = {"result": {"pane": {"pane_id": pane}}}
        elif command[1:3] == ["agent", "start"]:
            payload = {"result": {"agent": {"agent_id": command[3], "provider_session_id": f"session-{command[3]}"}}}
        elif command[1:3] == ["workspace", "close"]:
            payload = {"result": {}}
        else:
            payload = {"result": {}}
        return subprocess.CompletedProcess(command, 0, json.dumps(payload), "")


class RuntimeIntegrationTests(unittest.TestCase):
    def test_fake_herdr_firstmate_and_provider_boundary(self):
        herdr = FakeHerdr()
        adapter = HerdrAdapter(herdr)
        workspace = adapter.create_workspace(label="coding", cwd=Path("/tmp/work"))
        panes = [
            adapter.split_pane(workspace.root_pane_id, direction="right", cwd=Path("/tmp/work")).pane_id,
            adapter.split_pane(workspace.root_pane_id, direction="down", cwd=Path("/tmp/work")).pane_id,
        ]
        lead = adapter.start_agent("lead", kind="opencode", pane_id=workspace.root_pane_id, extra_args=("run", "--auto"))
        reviewer = adapter.start_agent("reviewer", kind="opencode", pane_id=panes[1])
        with tempfile.TemporaryDirectory(prefix="omagent-runtime-") as directory:
            firstmate = FirstmateAdapter(
                Path(directory) / "state",
                runner=lambda command, **_kwargs: subprocess.CompletedProcess(command, 0, "", ""),
            )
            firstmate.register_task(
                task_id="task-review",
                pane_id=reviewer.pane_id,
                workspace_id=workspace.workspace_id,
                tab_id=workspace.tab_id,
                workspace=Path("/tmp/work"),
                harness="opencode",
                role="reviewer",
            )
            firstmate.send_task("task-review", "inspect the diff")
        self.assertEqual(lead.provider_session_id, "session-lead")
        self.assertEqual(reviewer.provider_session_id, "session-reviewer")
        self.assertTrue(any(call[1:3] == ["workspace", "create"] for call in herdr.calls))
        self.assertTrue(any(call[1:3] == ["agent", "start"] for call in herdr.calls))

    def test_incomplete_herdr_split_stops_before_provider_launch(self):
        herdr = FakeHerdr(incomplete_split=True)
        adapter = HerdrAdapter(herdr)
        workspace = adapter.create_workspace(label="coding", cwd=Path("/tmp/work"))
        with self.assertRaises(HerdrError):
            adapter.split_pane(workspace.root_pane_id, direction="right", cwd=Path("/tmp/work"))
        self.assertFalse(any(call[1:3] == ["agent", "start"] for call in herdr.calls))

    def test_firstmate_send_failure_is_not_acknowledged_as_success(self):
        def failed_runner(_command, **_kwargs):
            return subprocess.CompletedProcess([], 7, "", "send failed")

        with tempfile.TemporaryDirectory(prefix="omagent-runtime-") as directory:
            adapter = FirstmateAdapter(Path(directory), runner=failed_runner)
            with self.assertRaises(FirstmateError):
                adapter.send_task("task-1", "continue")

    def test_repair_reverification_is_bounded_and_reuses_context(self):
        engine = QualityEngine(
            TaskContract(request="fix parser", profile="coding", acceptance_criteria=["tests pass"]),
            repair_limit=2,
        )
        checks = [
            CheckResult("task_contract", True, ["captured"]),
            CheckResult("implementation", False, ["no files"]),
            CheckResult("verification", False, ["tests failed"]),
            CheckResult("review", True, ["review pending"], blocking=False),
        ]
        repaired = [
            CheckResult("task_contract", True, ["captured"]),
            CheckResult("implementation", True, ["file changed"]),
            CheckResult("verification", True, ["tests passed"]),
            CheckResult("review", True, ["review pending"], blocking=False),
        ]
        contexts = []

        def repair(attempt, failed):
            contexts.append((attempt, tuple(failed)))
            return repaired, None

        engine.begin_execution()
        verified, _ = engine.verify_with_repair(checks, repair)
        self.assertTrue(verified)
        self.assertEqual(contexts, [(1, ("implementation", "verification"))])
        self.assertEqual(engine.report().repair_attempts, 1)


if __name__ == "__main__":
    unittest.main()
