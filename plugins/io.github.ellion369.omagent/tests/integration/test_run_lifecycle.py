from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from omagent_core.controller import RunController
from omagent_core.identity import RunIdentity
from omagent_core.lifecycle import RunState
from omagent_core.run_manifest import RunManifest
from omagent_core.session_store import SessionStore
from omagent_core.telemetry.session import SessionTelemetry, TelemetryBindingError


class FakeOwnedRuntime:
    """In-memory stand-in for Herdr/Firstmate cleanup in integration tests."""

    def __init__(self) -> None:
        self.panes = {"pane-owned", "pane-unrelated"}
        self.tasks = {"task-owned", "task-unrelated"}
        self.closed_panes: list[str] = []
        self.removed_tasks: list[str] = []

    def cleanup(self, manifest: dict) -> None:
        for resource in manifest.get("resources", []):
            if resource.get("state") != "owned":
                continue
            if resource.get("kind") == "pane" and resource.get("identifier") in self.panes:
                self.panes.remove(resource["identifier"])
                self.closed_panes.append(resource["identifier"])
            elif resource.get("kind") == "firstmate_task" and resource.get("identifier") in self.tasks:
                self.tasks.remove(resource["identifier"])
                self.removed_tasks.append(resource["identifier"])


class RunLifecycleIntegrationTests(unittest.TestCase):
    def test_fake_owned_resources_are_cleaned_without_touching_unrelated_resources(self):
        with tempfile.TemporaryDirectory(prefix="omagent-run-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            controller = RunController(store)
            identity = controller.start("session-1", "build the feature")
            store.set_state(identity.run_id, RunState.WORKING)
            manifest = RunManifest(identity, workspace=str(Path(directory) / "worktree"))
            for kind, identifier in (("pane", "pane-owned"), ("firstmate_task", "task-owned")):
                resource = manifest.reserve(kind, identifier)
                manifest.mark_created(resource)
            manifest.commit()
            store.save_manifest(manifest)

            runtime = FakeOwnedRuntime()
            self.assertEqual(controller.stop(identity.run_id).value, "cancel_requested")
            stored_manifest = store.load_manifest(identity.run_id)
            runtime.cleanup(stored_manifest)
            released_manifest = RunManifest.from_dict(stored_manifest)
            released_manifest.release_owned()
            store.save_manifest(released_manifest)
            controller.acknowledge_stop(identity.run_id)

            self.assertEqual(runtime.closed_panes, ["pane-owned"])
            self.assertEqual(runtime.removed_tasks, ["task-owned"])
            self.assertIn("pane-unrelated", runtime.panes)
            self.assertIn("task-unrelated", runtime.tasks)
            self.assertEqual(store.snapshot("session-1")["runs"][0]["state"], "cancelled")
            store.close()

    def test_restart_preserves_provider_telemetry_binding_and_detached_identity(self):
        with tempfile.TemporaryDirectory(prefix="omagent-run-") as directory:
            db = Path(directory) / "state.sqlite"
            store = SessionStore(db)
            controller = RunController(store)
            identity = controller.start("session-1", "build the feature")
            manifest = RunManifest(
                RunIdentity(identity.conversation_id, identity.run_id, provider_session_id="provider-session-a"),
                workspace=str(Path(directory) / "worktree"),
                provider="opencode",
            )
            resource = manifest.reserve("pane", "pane-owned")
            manifest.mark_created(resource)
            manifest.commit()
            store.save_manifest(manifest)
            store.set_state(identity.run_id, RunState.WORKING)
            store.record_provider_telemetry(identity.run_id, "opencode", "provider-session-a", {"text": "working"})
            controller.detach(identity.run_id)
            store.close()

            restarted = SessionStore(db)
            resumed = RunController(restarted)
            self.assertEqual(resumed.resume(identity.run_id).value, "working")
            snapshot = restarted.snapshot("session-1")["runs"][0]
            telemetry_event = next(event for event in snapshot["events"] if event["data"].get("kind") == "provider_telemetry")
            self.assertEqual(telemetry_event["provider_session_id"], "provider-session-a")
            self.assertEqual(snapshot["ownership"]["identity"]["provider_session_id"], "provider-session-a")
            restarted.close()

            telemetry = SessionTelemetry()
            telemetry.bind(run_id=identity.run_id, provider="opencode", provider_session_id="provider-session-a")
            telemetry.append(run_id=identity.run_id, provider="opencode", provider_session_id="provider-session-a", payload={"text": "after restart"})
            with self.assertRaises(TelemetryBindingError):
                telemetry.append(run_id=identity.run_id, provider="opencode", provider_session_id="other-session", payload={})


if __name__ == "__main__":
    unittest.main()
