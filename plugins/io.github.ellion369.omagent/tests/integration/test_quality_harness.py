from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from evaluation.quality_runner import load, score_result


PLUGIN = Path(__file__).resolve().parents[2]


class QualityHarnessTests(unittest.TestCase):
    def test_task_manifests_are_valid_and_have_fixtures(self):
        for profile in ("direct", "web", "coding", "ui"):
            manifest = load(PLUGIN / "evaluation" / profile / "tasks.json")
            self.assertEqual(manifest["profile"], profile)
            for task in manifest["tasks"]:
                self.assertTrue((PLUGIN / "evaluation" / profile / task["fixture"]).is_file())
                self.assertTrue(task["rubric"])

    def test_quality_runner_accepts_complete_fixture_result(self):
        task = load(PLUGIN / "evaluation" / "direct" / "tasks.json")["tasks"][0]
        result = {
            "task_id": task["id"],
            "scores": {criterion: 4 for criterion in task["rubric"]},
            "evidence": ["fixture evidence"],
            "terminal_state": "completed",
        }
        self.assertEqual(score_result(task, result), [])

    def test_ui_quality_runner_rejects_untyped_completed_result(self):
        task = load(PLUGIN / "evaluation" / "ui" / "tasks.json")["tasks"][0]
        result = {
            "task_id": task["id"],
            "scores": {criterion: 4 for criterion in task["rubric"]},
            "evidence": ["ui_interaction: passed"],
            "terminal_state": "completed",
        }
        errors = score_result(task, result, profile="ui")
        self.assertIn("completed UI results require live typed ui_evidence", errors)

    def test_quality_runner_rejects_incomplete_result(self):
        task = load(PLUGIN / "evaluation" / "direct" / "tasks.json")["tasks"][0]
        result = {"task_id": task["id"], "scores": {}, "evidence": [], "terminal_state": "done"}
        self.assertGreaterEqual(len(score_result(task, result)), 3)

    def test_baseline_manifest_contains_content_hashes_only(self):
        baseline = load(PLUGIN / "evaluation" / "baseline" / "current_tree.json")
        self.assertEqual(baseline["schema_version"], 1)
        self.assertGreater(len(baseline["files"]), 5)
        for item in baseline["files"]:
            self.assertFalse(Path(item["path"]).is_absolute())
            self.assertEqual(len(item["sha256"]), 64)

    def test_session_handoff_is_stored_and_read_through_router(self):
        from tests.support.isolated_env import isolated_process_env, run_router

        payload = {"sessionId": "session-1", "title": "Stored session", "entries": []}
        with isolated_process_env() as (env, root):
            handoff = root / "home" / ".local" / "state" / "omagent" / "handoff" / "session-1.json"
            handoff.parent.mkdir(parents=True)
            handoff.write_text(json.dumps(payload), encoding="utf-8")
            saved = run_router(["--import-session-file", str(handoff)], env)
            self.assertEqual(saved.returncode, 0, saved.stderr)
            loaded = run_router(["--get-session", "session-1"], env)
        self.assertEqual(json.loads(loaded.stdout)["title"], "Stored session")

    def test_missing_provider_setup_is_recorded_as_setup_failed(self):
        from omagent_core.session_store import SessionStore
        from tests.support.isolated_env import isolated_process_env, run_router

        with isolated_process_env() as (env, root):
            result = run_router(["--", "hello"], env)
            events = [json.loads(line) for line in result.stdout.splitlines() if line.strip()]
            for event in events:
                self.assertEqual(event["schema_version"], 1)
                self.assertEqual(event["kind"], "evidence")
                self.assertGreaterEqual(event["sequence"], 1)
                self.assertIn("kind", event["data"])
            agent_event = next(
                event for event in events
                if event.get("kind") == "agent" or (event.get("data") or {}).get("kind") == "agent"
            )
            fields = agent_event.get("data", {}).get("fields", agent_event)
            session_id = fields["session"]
            store = SessionStore(root / "home" / ".local" / "state" / "omagent" / "controller.sqlite")
            snapshot = store.snapshot(session_id)
            store.close()
        self.assertEqual(snapshot["runs"][0]["state"], "setup_failed")

    def test_router_rejects_unsafe_session_ids_before_filesystem_access(self):
        from tests.support.isolated_env import isolated_process_env, run_router

        with isolated_process_env() as (env, root):
            result = run_router(["--get-session", "../escape"], env)
            self.assertEqual(result.returncode, 1)
            self.assertIn("unsafe", result.stdout.lower())
            self.assertFalse((root / "home" / "escape.json").exists())

    def test_router_plan_mode_has_no_state_side_effect(self):
        from tests.support.isolated_env import isolated_process_env, run_router

        with isolated_process_env() as (env, root):
            result = run_router(["--plan", "do work"], env)
            state_dir = root / "home" / ".local" / "state" / "omagent"
            self.assertFalse(state_dir.exists())
        self.assertEqual(json.loads(result.stdout)["kind"], "plan")

    def test_legacy_dry_run_environment_uses_plan_mode(self):
        from tests.support.isolated_env import isolated_process_env, run_router

        with isolated_process_env() as (env, root):
            env["OMAGENT_DRY_RUN"] = "1"
            result = run_router(["--", "do work"], env)
            state_dir = root / "home" / ".local" / "state" / "omagent"
            self.assertFalse(state_dir.exists())
        self.assertEqual(json.loads(result.stdout)["kind"], "plan")

    def test_stop_session_closes_only_recorded_panes(self):
        from omagent_core.controller import RunController
        from omagent_core.session_store import SessionStore
        from tests.support.isolated_env import isolated_process_env, run_router

        with isolated_process_env() as (env, root):
            state_dir = root / "home" / ".local" / "state" / "omagent"
            session_dir = state_dir / "sessions"
            session_dir.mkdir(parents=True)
            (session_dir / "session-1.fleet.json").write_text(json.dumps({"fmTaskId": "task-1", "herdrWorkspaceId": "ws-owned", "herdrPaneId": "pane-owned", "herdrMotionPaneId": "pane-motion"}), encoding="utf-8")
            store = SessionStore(state_dir / "controller.sqlite")
            run_id = RunController(store).start("session-1", "work").run_id
            store.close()
            log = root / "herdr.log"
            fake = root / "bin" / "herdr"
            fake.write_text("#!/bin/sh\nprintf '%s\\n' \"$*\" >> '" + str(log) + "'\n", encoding="utf-8")
            fake.chmod(0o755)
            env["PATH"] = str(root / "bin") + ":" + env["PATH"]
            result = run_router(["--stop-session", "session-1", "--run-id", run_id], env)
            store = SessionStore(state_dir / "controller.sqlite")
            snapshot = store.snapshot("session-1")
            store.close()
            self.assertEqual(result.returncode, 0, result.stderr)
            deleted = run_router(["--delete-session", "session-1"], env)
            self.assertEqual(deleted.returncode, 0, deleted.stderr)
            calls = log.read_text(encoding="utf-8").splitlines()
            fleet_exists = (session_dir / "session-1.fleet.json").exists()
        self.assertEqual(calls, ["pane close pane-owned", "pane close pane-motion", "workspace close ws-owned"])
        self.assertEqual(snapshot["runs"][0]["state"], "cancelled")
        self.assertFalse(fleet_exists)

    def test_failed_verification_does_not_enter_review_after_terminalizing(self):
        import importlib.util
        from importlib.machinery import SourceFileLoader

        from omagent_core.controller import RunController
        from omagent_core.session_store import SessionStore

        loader = SourceFileLoader("omagent_route_quality_failure", str(PLUGIN / "omagent-route"))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        self.assertIsNotNone(spec)
        self.assertIsNotNone(spec.loader)
        route = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(route)
        with tempfile.TemporaryDirectory(prefix="omagent-quality-failure-") as directory:
            root = Path(directory)
            route.STATE_DIR = root
            route.SESSION_DIR = root / "sessions"
            route.CONTROLLER_DB_PATH = root / "controller.sqlite"
            store = SessionStore(route.CONTROLLER_DB_PATH)
            identity = RunController(store).start("session-failure", "implement the parser")
            state = route.record_lane_quality(
                "coding",
                "implement the parser",
                "provider stopped",
                evidence=[],
                run_id=identity.run_id,
            )
            snapshot = store.snapshot(identity.conversation_id)
            store.close()
            route._close_session_store()
        self.assertEqual(state, "incomplete")
        self.assertEqual(snapshot["runs"][0]["state"], "incomplete")

    def test_valid_independent_receipt_completes_the_owned_quality_run(self):
        import importlib.util
        from importlib.machinery import SourceFileLoader

        from omagent_core.controller import RunController
        from omagent_core.identity import RunIdentity
        from omagent_core.quality import ReviewReceipt
        from omagent_core.run_manifest import RunManifest
        from omagent_core.session_store import SessionStore

        loader = SourceFileLoader("omagent_route_test", str(PLUGIN / "omagent-route"))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        self.assertIsNotNone(spec)
        self.assertIsNotNone(spec.loader)
        route = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(route)
        with tempfile.TemporaryDirectory(prefix="omagent-quality-") as directory:
            root = Path(directory)
            route.STATE_DIR = root
            route.SESSION_DIR = root / "sessions"
            route.CONTROLLER_DB_PATH = root / "controller.sqlite"
            store = SessionStore(route.CONTROLLER_DB_PATH)
            identity = RunController(store).start("session-1", "implement the parser")
            manifest = RunManifest(
                RunIdentity(identity.conversation_id, identity.run_id, provider_session_id="implementer-session-1"),
                workspace=str(root / "workspace"),
                evidence_generation=f"evidence-{identity.run_id}",
                artifact_revision="revision-1",
                provider="opencode",
                reviewer={"reviewer_id": "reviewer-1", "provider_session_id": "reviewer-session-1"},
            )
            resource = manifest.reserve("pane", "pane-owned")
            manifest.mark_created(resource)
            manifest.commit()
            store.save_manifest(manifest)
            receipt = ReviewReceipt(
                reviewer_id="reviewer-1",
                provider="opencode",
                provider_session_id="reviewer-session-1",
                independent=True,
                evidence=["independent diff inspection"],
                findings=[],
                run_id=identity.run_id,
                workspace=str(manifest.workspace),
                evidence_generation=manifest.evidence_generation,
                artifact_revision="revision-1",
            )
            state = route.record_lane_quality(
                "coding",
                "implement the parser",
                "done",
                evidence=["implementation: fixture", "verification: pytest passed"],
                run_id=identity.run_id,
                review_receipt=receipt,
            )
            snapshot = store.snapshot(identity.conversation_id)
            store.close()
            route._close_session_store()
        self.assertEqual(state, "completed")
        self.assertEqual(snapshot["runs"][0]["state"], "completed")
        self.assertEqual(snapshot["runs"][0]["events"][-1]["kind"], "run_completed")
        self.assertTrue(any(
            event.get("data", {}).get("kind") == "quality_completed"
            for event in snapshot["runs"][0]["events"]
        ))

    def test_delete_rejects_an_active_controller_run_before_legacy_cleanup(self):
        from omagent_core.controller import RunController
        from omagent_core.session_store import SessionStore
        from tests.support.isolated_env import isolated_process_env, run_router

        with isolated_process_env() as (env, root):
            state_dir = root / "home" / ".local" / "state" / "omagent"
            session_dir = state_dir / "sessions"
            session_dir.mkdir(parents=True)
            session_file = session_dir / "session-1.json"
            session_file.write_text(json.dumps({"sessionId": "session-1", "entries": []}), encoding="utf-8")
            store = SessionStore(state_dir / "controller.sqlite")
            RunController(store).start("session-1", "work")
            store.close()
            result = run_router(["--delete-session", "session-1"], env)
            self.assertEqual(result.returncode, 1)
            self.assertTrue(session_file.exists())
            self.assertIn("active", result.stdout.lower())

    def test_legacy_migration_is_explicit_and_idempotent(self):
        from tests.support.isolated_env import isolated_process_env, run_router

        with isolated_process_env() as (env, root):
            session_dir = root / "home" / ".local" / "state" / "omagent" / "sessions"
            session_dir.mkdir(parents=True)
            (session_dir / "session-1.json").write_text(json.dumps({"sessionId": "session-1", "title": "Active", "runState": "running", "runPid": 4, "entries": []}), encoding="utf-8")
            first = run_router(["--migrate-legacy"], env)
            second = run_router(["--migrate-legacy"], env)
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(json.loads(first.stdout)["recoveryRequired"], ["session-1"])
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(json.loads(second.stdout)["imported"], [])


if __name__ == "__main__":
    unittest.main()
