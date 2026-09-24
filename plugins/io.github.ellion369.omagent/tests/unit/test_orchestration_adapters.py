from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from omagent_core.orchestration.firstmate import FirstmateAdapter, FirstmateError
from omagent_core.orchestration.herdr import HerdrAdapter, HerdrError
from omagent_core.orchestration.worktree import WorkspaceError, remove_managed_worktree


class FakeHerdrRunner:
    def __init__(self) -> None:
        self.calls: list[list[str]] = []
        self.responses: dict[tuple[str, ...], subprocess.CompletedProcess[str]] = {}

    def __call__(self, command, **kwargs):
        self.calls.append(list(command))
        key = tuple(command)
        return self.responses.get(key, subprocess.CompletedProcess(command, 0, "{}", ""))


class HerdrAdapterTests(unittest.TestCase):
    def test_workspace_and_agent_receipts_are_explicit(self):
        runner = FakeHerdrRunner()
        runner.responses[("herdr", "workspace", "create", "--label", "code", "--cwd", "/tmp/work")] = subprocess.CompletedProcess(
            ["herdr"], 0, json.dumps({"result": {"workspace": {"workspace_id": "ws-1"}, "tab": {"tab_id": "tab-1"}, "root_pane": {"pane_id": "pane-1"}}}), ""
        )
        runner.responses[("herdr", "agent", "start", "lead", "--kind", "opencode", "--pane", "pane-1", "--timeout", "15000", "--",)] = subprocess.CompletedProcess(
            ["herdr"], 0, json.dumps({"result": {"agent": {"agent_id": "agent-1", "provider_session_id": "session-1"}}}), ""
        )
        adapter = HerdrAdapter(runner)
        workspace = adapter.create_workspace(label="code", cwd=Path("/tmp/work"))
        agent = adapter.start_agent("lead", kind="opencode", pane_id=workspace.root_pane_id)
        self.assertEqual(workspace.workspace_id, "ws-1")
        self.assertEqual(agent.provider_session_id, "session-1")
        self.assertEqual(len(runner.calls), 2)

    def test_provider_session_is_required_when_requested(self):
        runner = FakeHerdrRunner()
        command = (
            "herdr", "agent", "start", "lead", "--kind", "agy", "--pane", "pane-1",
            "--timeout", "15000", "--",
        )
        runner.responses[command] = subprocess.CompletedProcess(
            ["herdr"], 0, json.dumps({"result": {"agent": {"agent_id": "agent-1"}}}), ""
        )
        with self.assertRaises(HerdrError):
            HerdrAdapter(runner).start_agent(
                "lead", kind="agy", pane_id="pane-1", require_provider_session=True
            )

    def test_incomplete_workspace_receipt_fails_closed(self):
        runner = FakeHerdrRunner()
        runner.responses[("herdr", "workspace", "create", "--label", "code", "--cwd", "/tmp/work")] = subprocess.CompletedProcess(
            ["herdr"], 0, json.dumps({"result": {"workspace": {"workspace_id": "ws-1"}}}), ""
        )
        with self.assertRaises(HerdrError):
            HerdrAdapter(runner).create_workspace(label="code", cwd=Path("/tmp/work"))


class FirstmateAdapterTests(unittest.TestCase):
    def test_registration_round_trips_and_cleanup_is_scoped(self):
        with tempfile.TemporaryDirectory(prefix="omagent-firstmate-") as directory:
            state = Path(directory) / "state"
            adapter = FirstmateAdapter(state)
            receipt = adapter.register_task(
                task_id="task-1",
                pane_id="pane-1",
                workspace_id="ws-1",
                tab_id="tab-1",
                workspace=Path("/tmp/work"),
                harness="opencode",
                model="opencode/model",
                role="lead",
            )
            self.assertTrue(Path(receipt.metadata_path).is_file())
            self.assertIn("herdr_pane_id=pane-1", Path(receipt.metadata_path).read_text())
            self.assertIn("herdr_tab_id=tab-1", Path(receipt.metadata_path).read_text())
            self.assertTrue(adapter.unregister_task("task-1"))
            self.assertFalse(Path(receipt.metadata_path).exists())

    def test_task_ids_cannot_escape_state_directory(self):
        with tempfile.TemporaryDirectory(prefix="omagent-firstmate-") as directory:
            adapter = FirstmateAdapter(Path(directory) / "state")
            with self.assertRaises(FirstmateError):
                adapter.register_task(
                    task_id="../escape",
                    pane_id="pane-1",
                    workspace_id="ws-1",
                    tab_id="tab-1",
                    workspace=Path("/tmp/work"),
                )


class WorktreeCleanupTests(unittest.TestCase):
    def test_cleanup_refuses_paths_outside_managed_root(self):
        with tempfile.TemporaryDirectory(prefix="omagent-worktree-") as directory:
            root = Path(directory)
            outside = root / "user-project"
            outside.mkdir()
            with patch.object(Path, "home", return_value=root):
                with self.assertRaises(WorkspaceError):
                    remove_managed_worktree(outside, runner=lambda *_args, **_kwargs: subprocess.CompletedProcess([], 0, "", ""))

    def test_cleanup_uses_git_worktree_remove_for_managed_path(self):
        calls = []
        with tempfile.TemporaryDirectory(prefix="omagent-worktree-") as directory:
            root = Path(directory)
            managed = root / ".local/state/omagent/worktrees/run-1"
            managed.mkdir(parents=True)

            def runner(command, **_kwargs):
                calls.append(command)
                return subprocess.CompletedProcess(command, 0, "", "")

            with patch.object(Path, "home", return_value=root):
                remove_managed_worktree(managed, runner=runner)
            self.assertEqual(calls[0][1:4], ["-C", str(managed), "worktree"])


if __name__ == "__main__":
    unittest.main()
