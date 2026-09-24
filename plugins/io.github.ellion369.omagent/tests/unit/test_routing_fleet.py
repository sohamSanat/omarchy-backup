from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

from omagent_core.orchestration.fleet import plan_fleet
from omagent_core.orchestration.worktree import WorkspaceError, discover_repository, plan_worktree, safe_branch_name
from omagent_core.providers.adapters import ADAPTERS, launch_spec
from omagent_core.routing import ProviderHealth, RoutingUnavailable, choose_provider
from omagent_core.telemetry.session import SessionTelemetry, TelemetryBindingError


class RoutingFleetTests(unittest.TestCase):
    def test_unsupported_provider_is_never_dispatched(self):
        with self.assertRaises(RoutingUnavailable):
            choose_provider(
                requested_provider="kilo",
                requested_model="kilo/model",
                health=[ProviderHealth("kilo", True)],
                models_by_provider={"kilo": "kilo/model"},
            )

    def test_routing_falls_back_to_first_healthy_supported_provider(self):
        decision = choose_provider(
            requested_provider="agy",
            requested_model="agy/model",
            health=[ProviderHealth("agy", False, reason="quota"), ProviderHealth("opencode", True), ProviderHealth("cline", True)],
            models_by_provider={"agy": "agy/model", "opencode": "opencode/model", "cline": "cline/model"},
        )
        self.assertEqual(decision.provider, "opencode")
        self.assertEqual(decision.model, "opencode/model")
        self.assertTrue(decision.fallback_used)

    def test_requested_model_must_belong_to_requested_provider_catalog(self):
        decision = choose_provider(
            requested_provider="agy",
            requested_model="opencode/big-pickle",
            health=[ProviderHealth("agy", True), ProviderHealth("opencode", True)],
            models_by_provider={"agy": "agy/model", "opencode": "opencode/model"},
            available_models={"agy": {"agy/model"}, "opencode": {"opencode/model"}},
        )
        self.assertEqual(decision.provider, "opencode")
        self.assertEqual(decision.model, "opencode/model")

    def test_adapters_build_auto_approved_commands_without_execution(self):
        spec = launch_spec("opencode", "opencode/big-pickle", "do work", workspace="/tmp/worktree")
        self.assertTrue(spec.auto_approve)
        self.assertIn("opencode", spec.command)
        self.assertIn("--auto", spec.command)
        self.assertTrue(ADAPTERS["cline"].capabilities.same_workspace_handoff)
        self.assertFalse(ADAPTERS["cline"].capabilities.same_session_resume)

    def test_fleet_size_is_task_driven_and_serializes_writes(self):
        self.assertEqual(plan_fleet(track="regular").role_names, ("lead",))
        coding = plan_fleet(track="coding")
        self.assertEqual(coding.role_names, ("lead", "reviewer"))
        self.assertTrue(coding.serialize_writes)
        self.assertIn("ui-specialist", plan_fleet(track="ui").role_names)

    def test_worktree_discovery_requires_git_and_does_not_initialize(self):
        with tempfile.TemporaryDirectory(prefix="omagent-worktree-") as directory:
            root = Path(directory) / "not-a-repo"
            root.mkdir()
            with self.assertRaises(WorkspaceError):
                discover_repository(root)
            repo = Path(directory) / "repo"
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            discovered = discover_repository(repo)
            self.assertEqual(discovered.path, repo.resolve())
            plan = plan_worktree(repo, managed_root=Path(directory) / "managed", request="Fix the parser", run_id="run-123456")
            self.assertEqual(plan.repository_root, str(repo.resolve()))
            self.assertTrue(plan.branch.startswith("omagent/fix-the-parser-"))
        self.assertEqual(safe_branch_name("A weird / request", "run-abcdef123456"), "omagent/a-weird-request-run-abcdef12")

    def test_telemetry_is_scoped_to_run_and_provider_session(self):
        telemetry = SessionTelemetry()
        telemetry.bind(run_id="run-1", provider="opencode", provider_session_id="session-a")
        telemetry.bind(run_id="run-2", provider="opencode", provider_session_id="session-b")
        telemetry.append(run_id="run-1", provider="opencode", provider_session_id="session-a", payload={"text": "a"})
        telemetry.append(run_id="run-2", provider="opencode", provider_session_id="session-b", payload={"text": "b"})
        self.assertEqual([event.payload["text"] for event in telemetry.for_run("run-1")], ["a"])

    def test_telemetry_rejects_unbound_or_wrong_provider_sessions(self):
        telemetry = SessionTelemetry()
        with self.assertRaises(TelemetryBindingError):
            telemetry.append(run_id="run-1", provider="opencode", provider_session_id="session-a", payload={})
        telemetry.bind(run_id="run-1", provider="opencode", provider_session_id="session-a")
        with self.assertRaises(TelemetryBindingError):
            telemetry.append(run_id="run-1", provider="agy", provider_session_id="session-a", payload={})
        with self.assertRaises(TelemetryBindingError):
            telemetry.append(run_id="run-1", provider="opencode", provider_session_id="session-b", payload={})
        with self.assertRaises(TelemetryBindingError):
            telemetry.bind(run_id="run-1", provider="agy", provider_session_id="session-a")


if __name__ == "__main__":
    unittest.main()
