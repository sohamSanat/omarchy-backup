from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from omagent_core.controller import RunController
from omagent_core.lifecycle import RunState
from omagent_core.session_store import SessionStore
from omagent_core.run_manifest import RunManifest


class ControllerTests(unittest.TestCase):
    def test_stop_before_ownership_is_side_effect_free_terminal_state(self):
        with tempfile.TemporaryDirectory(prefix="omagent-controller-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            controller = RunController(store)
            identity = controller.start("conversation-1", "do work")
            state = controller.stop(identity.run_id)
            self.assertEqual(state.value, "cancelled_before_start")
            self.assertEqual(controller.snapshot("conversation-1")["runs"][0]["state"], "cancelled_before_start")
            store.close()

    def test_stop_after_ownership_requires_cleanup_acknowledgement(self):
        with tempfile.TemporaryDirectory(prefix="omagent-controller-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            controller = RunController(store)
            identity = controller.start("conversation-1", "do work")
            manifest = RunManifest(identity, workspace=str(Path(directory) / "workspace"))
            pane = manifest.reserve("pane", "pane-1")
            manifest.mark_created(pane)
            manifest.commit()
            store.save_manifest(manifest)
            self.assertEqual(controller.stop(identity.run_id).value, "cancel_requested")
            manifest.release_owned()
            store.save_manifest(manifest)
            self.assertEqual(controller.acknowledge_stop(identity.run_id).value, "cancelled")
            with self.assertRaises(RuntimeError):
                controller.resume(identity.run_id)
            store.close()

    def test_reserved_setup_resource_requires_compensation_before_completion(self):
        with tempfile.TemporaryDirectory(prefix="omagent-controller-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            controller = RunController(store)
            identity = controller.start("conversation-1", "do work")
            manifest = RunManifest(identity)
            manifest.reserve("herdr_workspace", "workspace-intended")
            store.save_manifest(manifest)
            self.assertEqual(controller.stop(identity.run_id).value, "cancel_requested")
            self.assertTrue(store.has_ownership(identity.run_id))
            store.close()

    def test_new_task_creates_parented_run_only_after_previous_terminal(self):
        with tempfile.TemporaryDirectory(prefix="omagent-controller-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            controller = RunController(store)
            first = controller.start("conversation-1", "first request")
            store.set_state(first.run_id, RunState.STARTING)
            store.set_state(first.run_id, RunState.WORKING)
            store.set_state(first.run_id, RunState.VERIFYING)
            store.set_state(first.run_id, RunState.INCOMPLETE)
            second = controller.ensure_run("conversation-1", "new request", new_task=True)
            self.assertEqual(second.parent_run_id, first.run_id)
            self.assertNotEqual(second.run_id, first.run_id)
            store.close()

    def test_new_task_refuses_to_replace_active_run(self):
        with tempfile.TemporaryDirectory(prefix="omagent-controller-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            controller = RunController(store)
            controller.start("conversation-1", "first request")
            with self.assertRaises(RuntimeError):
                controller.ensure_run("conversation-1", "new request", new_task=True)
            store.close()

    def test_ensure_run_reuses_active_conversation_run(self):
        with tempfile.TemporaryDirectory(prefix="omagent-controller-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            controller = RunController(store)
            first = controller.ensure_run("conversation-1", "first request")
            second = controller.ensure_run("conversation-1", "follow-up request")
            self.assertEqual(first.run_id, second.run_id)
            self.assertEqual(len(store.snapshot("conversation-1")["runs"]), 1)
            store.close()

    def test_stop_without_ownership_after_execution_blocks_instead_of_claiming_cancelled(self):
        with tempfile.TemporaryDirectory(prefix="omagent-controller-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            controller = RunController(store)
            identity = controller.start("conversation-1", "do work")
            store.set_state(identity.run_id, RunState.WORKING)
            self.assertEqual(controller.stop(identity.run_id).value, "blocked")
            self.assertEqual(store.snapshot("conversation-1")["runs"][0]["state"], "blocked")
            store.close()

    def test_stop_derives_ownership_from_the_store_when_not_supplied(self):
        with tempfile.TemporaryDirectory(prefix="omagent-controller-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            controller = RunController(store)
            identity = controller.start("conversation-1", "do work")
            self.assertEqual(controller.stop(identity.run_id).value, "cancelled_before_start")
            store.close()

    def test_resume_requires_a_committed_ownership_manifest(self):
        with tempfile.TemporaryDirectory(prefix="omagent-controller-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            controller = RunController(store)
            identity = controller.start("conversation-1", "do work")
            pending = RunManifest(identity)
            pending.reserve("pane", "pane-pending")
            store.save_manifest(pending)
            store.set_state(identity.run_id, RunState.WORKING)
            store.set_state(identity.run_id, RunState.DETACHED)
            with self.assertRaises(RuntimeError):
                controller.resume(identity.run_id)
            store.close()

    def test_detached_run_can_reattach_without_replacement_identity(self):
        with tempfile.TemporaryDirectory(prefix="omagent-controller-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            controller = RunController(store)
            identity = controller.start("conversation-1", "do work")
            manifest = RunManifest(identity, workspace=str(Path(directory) / "workspace"))
            pane = manifest.reserve("pane", "pane-1")
            manifest.mark_created(pane)
            manifest.commit()
            store.save_manifest(manifest)
            store.set_state(identity.run_id, "working")
            self.assertEqual(controller.detach(identity.run_id).value, "detached")
            self.assertEqual(controller.resume(identity.run_id).value, "working")
            self.assertEqual(controller.snapshot("conversation-1")["runs"][0]["run_id"], identity.run_id)
            store.close()


if __name__ == "__main__":
    unittest.main()
