from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from omagent_core.identity import RunIdentity
from omagent_core.lifecycle import LifecycleError, RunState
from omagent_core.plan_mode import build_plan
from omagent_core.protocol import EventType, ProtocolError, make_event
from omagent_core.quality import ReviewReceipt
from omagent_core.run_manifest import RunManifest
from omagent_core.session_store import SessionStore, StoreError


class LifecycleStoreTests(unittest.TestCase):
    def test_run_events_are_ordered_idempotent_and_late_safe(self):
        with tempfile.TemporaryDirectory(prefix="omagent-store-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            identity = RunIdentity("conversation-1", "run-1")
            store.create_run(identity, task_contract={"request": "test"})
            first = store.set_state("run-1", RunState.STARTING)
            second = store.set_state("run-1", RunState.WORKING)
            self.assertEqual((first, second), ("accepted", "accepted"))
            snapshot = store.snapshot("conversation-1")
            self.assertEqual(snapshot["runs"][0]["state"], "working")
            self.assertEqual([event["sequence"] for event in snapshot["runs"][0]["events"]], [1, 2])
            with self.assertRaises(StoreError):
                store.create_run(RunIdentity("conversation-1", "run-2"), task_contract={"request": "blocked"})
            store.close()

    def test_provider_telemetry_is_persisted_under_the_owned_session(self):
        with tempfile.TemporaryDirectory(prefix="omagent-store-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            identity = RunIdentity("conversation-1", "run-1")
            store.create_run(identity, task_contract={})
            manifest = RunManifest(
                RunIdentity("conversation-1", "run-1", provider_session_id="provider-session-a"),
                workspace="/tmp/worktree",
                provider="opencode",
            )
            pane = manifest.reserve("pane", "pane-1")
            manifest.mark_created(pane)
            manifest.commit()
            store.save_manifest(manifest)
            store.set_state(identity.run_id, RunState.STARTING)
            store.set_state(identity.run_id, RunState.WORKING)
            store.record_provider_telemetry(
                identity.run_id,
                "opencode",
                "provider-session-a",
                {"text": "progress"},
            )
            snapshot = store.snapshot(identity.conversation_id)
            event = snapshot["runs"][0]["events"][-1]
            self.assertEqual(event["provider_session_id"], "provider-session-a")
            self.assertEqual(event["data"]["payload"], {"text": "progress"})
            with self.assertRaises(StoreError):
                store.record_provider_telemetry(identity.run_id, "opencode", "provider-session-b", {})
            with self.assertRaises(StoreError):
                store.record_provider_telemetry(identity.run_id, "agy", "provider-session-a", {})
            store.close()

    def test_review_receipt_channel_requires_manifest_bound_reviewer(self):
        with tempfile.TemporaryDirectory(prefix="omagent-store-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            identity = RunIdentity("conversation-1", "run-1")
            store.create_run(identity, task_contract={})
            manifest = RunManifest(
                RunIdentity(identity.conversation_id, identity.run_id, provider_session_id="implementer-session"),
                workspace=str(Path(directory) / "workspace"),
                evidence_generation=f"evidence-{identity.run_id}",
                artifact_revision="revision-1",
                provider="opencode",
                reviewer={"reviewer_id": "reviewer-1", "provider_session_id": "reviewer-session"},
            )
            resource = manifest.reserve("pane", "pane-1")
            manifest.mark_created(resource)
            manifest.commit()
            store.save_manifest(manifest)
            store.set_state(identity.run_id, RunState.STARTING)
            receipt = ReviewReceipt(
                reviewer_id="reviewer-1",
                provider="opencode",
                provider_session_id="reviewer-session",
                independent=True,
                evidence=["reviewed diff"],
                findings=[],
                run_id=identity.run_id,
                workspace=str(Path(directory) / "workspace"),
                evidence_generation=f"evidence-{identity.run_id}",
                artifact_revision="revision-1",
            )
            store.save_review_receipt(identity.run_id, receipt)
            self.assertEqual(store.load_review_receipt(identity.run_id), receipt)
            with self.assertRaises(StoreError):
                store.save_review_receipt(
                    identity.run_id,
                    ReviewReceipt(
                        reviewer_id="reviewer-1",
                        provider="opencode",
                        provider_session_id="implementer-session",
                        independent=True,
                        evidence=["not independent"],
                        findings=[],
                        run_id=identity.run_id,
                        workspace=str(Path(directory) / "workspace"),
                        evidence_generation=f"evidence-{identity.run_id}",
                        artifact_revision="revision-1",
                    ),
                )
            store.close()

    def test_terminal_run_records_late_evidence_without_mutating_state(self):
        with tempfile.TemporaryDirectory(prefix="omagent-store-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            identity = RunIdentity("conversation-1", "run-1")
            store.create_run(identity, task_contract={})
            store.set_state(identity.run_id, RunState.STARTING)
            store.set_state(identity.run_id, RunState.WORKING)
            store.set_state(identity.run_id, RunState.VERIFYING)
            store.set_state(identity.run_id, RunState.REVIEWING)
            store.set_state(identity.run_id, RunState.COMPLETED, quality_receipt={"passed": True})
            self.assertEqual(store.record_evidence(identity.run_id, {"kind": "late_worker_output"}), "late")
            self.assertEqual(store.record_evidence(identity.run_id, {"kind": "late_worker_output"}), "duplicate")
            snapshot = store.snapshot(identity.conversation_id)
            self.assertEqual(snapshot["runs"][0]["state"], "completed")
            self.assertEqual(snapshot["runs"][0]["events"][-1]["kind"], "run_completed")
            self.assertEqual(snapshot["runs"][0]["late_events"][0]["data"]["kind"], "late_worker_output")
            duplicate_terminal = make_event(
                identity,
                int(snapshot["runs"][0]["events"][-1]["sequence"]) + 1,
                EventType.RUN_COMPLETED,
                {"state": "completed", "quality_receipt": {"passed": True}},
            )
            self.assertEqual(store.append_event(duplicate_terminal), "late")
            self.assertEqual(store.snapshot(identity.conversation_id)["runs"][0]["state"], "completed")
            store.close()

    def test_event_cannot_claim_a_different_conversation(self):
        with tempfile.TemporaryDirectory(prefix="omagent-store-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            identity = RunIdentity("conversation-1", "run-1")
            store.create_run(identity, task_contract={})
            event = make_event(RunIdentity("conversation-2", identity.run_id), 1, EventType.EVIDENCE, {"kind": "wrong"})
            with self.assertRaises(ProtocolError):
                store.append_event(event)
            store.close()

    def test_repeated_state_transition_is_idempotent(self):
        with tempfile.TemporaryDirectory(prefix="omagent-store-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            identity = RunIdentity("conversation-1", "run-1")
            store.create_run(identity, task_contract={})
            self.assertEqual(store.set_state(identity.run_id, RunState.STARTING), "accepted")
            self.assertEqual(store.set_state(identity.run_id, RunState.STARTING), "duplicate")
            self.assertEqual(len(store.snapshot(identity.conversation_id)["runs"][0]["events"]), 1)
            store.close()

    def test_terminal_run_with_owned_resources_cannot_be_deleted(self):
        with tempfile.TemporaryDirectory(prefix="omagent-store-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            identity = RunIdentity("conversation-1", "run-1")
            store.create_run(identity, task_contract={})
            manifest = RunManifest(identity, workspace=str(Path(directory) / "workspace"))
            resource = manifest.reserve("pane", "pane-1")
            manifest.mark_created(resource)
            manifest.commit()
            store.save_manifest(manifest)
            store.set_state(identity.run_id, RunState.STARTING)
            store.set_state(identity.run_id, RunState.WORKING)
            store.set_state(identity.run_id, RunState.CANCEL_REQUESTED)
            store.set_state(identity.run_id, RunState.CANCELLED)
            with self.assertRaises(StoreError):
                store.delete_conversation(identity.conversation_id)
            store.close()

    def test_active_conversation_cannot_be_deleted_without_termination(self):
        with tempfile.TemporaryDirectory(prefix="omagent-store-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            identity = RunIdentity("conversation-1", "run-1")
            store.create_run(identity, task_contract={})
            with self.assertRaises(StoreError):
                store.delete_conversation(identity.conversation_id)
            self.assertEqual(store.snapshot(identity.conversation_id)["runs"][0]["state"], "planned")
            store.close()

    def test_invalid_transition_cannot_report_completion(self):
        with tempfile.TemporaryDirectory(prefix="omagent-store-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            store.create_run(RunIdentity("conversation-1", "run-1"), task_contract={})
            with self.assertRaises(LifecycleError):
                store.set_state("run-1", RunState.COMPLETED)
            store.set_state("run-1", RunState.STARTING)
            store.set_state("run-1", RunState.WORKING)
            store.set_state("run-1", RunState.VERIFYING)
            store.set_state("run-1", RunState.REVIEWING)
            store.set_state("run-1", RunState.COMPLETED, quality_receipt={"passed": True})
            self.assertEqual(store.snapshot("conversation-1")["runs"][0]["state"], "completed")
            store.close()

    def test_terminal_event_kind_must_match_claimed_state(self):
        with tempfile.TemporaryDirectory(prefix="omagent-store-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            identity = RunIdentity("conversation-1", "run-1")
            store.create_run(identity, task_contract={})
            store.set_state(identity.run_id, RunState.STARTING)
            store.set_state(identity.run_id, RunState.WORKING)
            store.set_state(identity.run_id, RunState.VERIFYING)
            store.set_state(identity.run_id, RunState.REVIEWING)
            event = make_event(identity, 5, EventType.RUN_COMPLETED, {"state": "working", "quality_receipt": {"passed": True}})
            with self.assertRaises(ProtocolError):
                store.append_event(event)
            store.close()

    def test_raw_completion_event_cannot_skip_lifecycle_validation(self):
        with tempfile.TemporaryDirectory(prefix="omagent-store-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            identity = RunIdentity("conversation-1", "run-1")
            store.create_run(identity, task_contract={})
            event = make_event(identity, 1, EventType.RUN_COMPLETED, {"quality_receipt": {"passed": True}})
            with self.assertRaises(ProtocolError):
                store.append_event(event)
            self.assertEqual(store.snapshot("conversation-1")["runs"][0]["state"], "planned")
            store.close()

    def test_manifest_decoder_rejects_ambiguous_types(self):
        with self.assertRaises(ValueError):
            RunManifest.from_dict({
                "identity": {"conversation_id": "conversation-1", "run_id": "run-1"},
                "resources": [],
                "committed": "false",
            })
        with self.assertRaises(ValueError):
            RunManifest.from_dict({
                "identity": {"conversation_id": "conversation-1", "run_id": "run-1"},
                "resources": [],
                "committed": False,
                "workspace": 3,
            })

    def test_manifest_compensation_is_limited_to_created_resources(self):
        manifest = RunManifest(RunIdentity("conversation-1", "run-1"))
        pane = manifest.reserve("pane", "pane-1")
        manifest.mark_created(pane)
        manifest.commit()
        self.assertEqual([item.identifier for item in manifest.compensation_targets()], ["pane-1"])
        self.assertEqual([item.identifier for item in manifest.release_owned()], ["pane-1"])
        self.assertEqual(manifest.compensation_targets(), [])

    def test_snapshot_is_authoritative_and_round_trips(self):
        with tempfile.TemporaryDirectory(prefix="omagent-store-") as directory:
            store = SessionStore(Path(directory) / "state.sqlite")
            snapshot = {"sessionId": "session-1", "entries": [{"rowKind": "you", "rowText": "hello"}]}
            store.save_snapshot("session-1", snapshot)
            self.assertEqual(store.load_snapshot("session-1"), snapshot)
            self.assertEqual(store.list_snapshots(), [snapshot])
            store.delete_conversation("session-1")
            self.assertIsNone(store.load_snapshot("session-1"))
            self.assertEqual(store.list_snapshots(), [])
            store.close()

    def test_plan_mode_is_side_effect_free_by_construction(self):
        with tempfile.TemporaryDirectory(prefix="omagent-plan-") as directory:
            before = sorted(Path(directory).iterdir())
            plan = build_plan("Do the work", workspace=directory)
            self.assertEqual(sorted(Path(directory).iterdir()), before)
        self.assertEqual(plan["side_effects"], [])


if __name__ == "__main__":
    unittest.main()
