"""Transactional session, run, event, and evidence storage.

The controller is the only supported writer. QML and legacy callers receive
projections from this store rather than mutating JSON sidecars directly.
"""
from __future__ import annotations

import json
import re
import sqlite3
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .identity import RunIdentity, validate_identity
from .lifecycle import LifecycleError, RunState, can_transition, is_terminal, transition_data, validate_transition
from .protocol import EventType, ProtocolError, make_event, validate_event
from .quality.review import ReviewReceipt
from .run_manifest import RunManifest, manifest_has_ownership

SCHEMA_VERSION = 2


class StoreError(RuntimeError):
    """Raised when the authoritative store cannot accept an operation."""


class SessionStore:
    """A small SQLite-backed event store with deterministic sequencing."""

    def __init__(self, path: Path | str, *, owner: str = "controller") -> None:
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = threading.RLock()
        self._connection = sqlite3.connect(self.path, check_same_thread=False)
        self._connection.row_factory = sqlite3.Row
        self._connection.execute("PRAGMA foreign_keys = ON")
        self._connection.execute("PRAGMA journal_mode = WAL")
        self._connection.execute("PRAGMA busy_timeout = 5000")
        self._owner = owner
        self._initialize()

    def _initialize(self) -> None:
        with self._lock, self._connection:
            self._connection.executescript(
                """
                CREATE TABLE IF NOT EXISTS metadata (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS conversations (
                    conversation_id TEXT PRIMARY KEY,
                    title TEXT NOT NULL DEFAULT '',
                    created_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS conversation_snapshots (
                    conversation_id TEXT PRIMARY KEY REFERENCES conversations(conversation_id),
                    snapshot_json TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS runs (
                    run_id TEXT PRIMARY KEY,
                    conversation_id TEXT NOT NULL REFERENCES conversations(conversation_id),
                    parent_run_id TEXT,
                    state TEXT NOT NULL,
                    task_contract_json TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS runs_conversation_idx ON runs(conversation_id, updated_at);
                CREATE TABLE IF NOT EXISTS events (
                    conversation_id TEXT NOT NULL,
                    run_id TEXT NOT NULL REFERENCES runs(run_id),
                    sequence INTEGER NOT NULL,
                    event_json TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    PRIMARY KEY (run_id, sequence)
                );
                CREATE TABLE IF NOT EXISTS late_events (
                    late_id INTEGER PRIMARY KEY AUTOINCREMENT,
                    run_id TEXT NOT NULL REFERENCES runs(run_id),
                    sequence INTEGER NOT NULL,
                    event_json TEXT NOT NULL,
                    created_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS ownership (
                    run_id TEXT PRIMARY KEY REFERENCES runs(run_id),
                    manifest_json TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS review_receipts (
                    run_id TEXT PRIMARY KEY REFERENCES runs(run_id),
                    receipt_json TEXT NOT NULL,
                    created_at TEXT NOT NULL
                );
                """
            )
            self._connection.execute(
                "INSERT OR REPLACE INTO metadata(key, value) VALUES ('schema_version', ?)",
                (str(SCHEMA_VERSION),),
            )

    def close(self) -> None:
        with self._lock:
            self._connection.close()

    def __enter__(self) -> "SessionStore":
        return self

    def __exit__(self, *_args: object) -> None:
        self.close()

    def create_conversation(self, conversation_id: str, *, title: str = "") -> None:
        conversation_id = _safe_identifier(conversation_id, "conversation_id")
        with self._lock, self._connection:
            self._connection.execute(
                "INSERT OR IGNORE INTO conversations(conversation_id, title, created_at) VALUES (?, ?, ?)",
                (conversation_id, title, _now()),
            )

    def save_snapshot(self, conversation_id: str, snapshot: dict[str, Any]) -> None:
        if not conversation_id:
            raise StoreError("conversation_id must not be empty")
        if not isinstance(snapshot, dict):
            raise StoreError("snapshot must be an object")
        self.create_conversation(conversation_id, title=str(snapshot.get("title", ""))[:80])
        with self._lock, self._connection:
            self._connection.execute(
                "INSERT INTO conversation_snapshots(conversation_id, snapshot_json, updated_at) VALUES (?, ?, ?) ON CONFLICT(conversation_id) DO UPDATE SET snapshot_json = excluded.snapshot_json, updated_at = excluded.updated_at",
                (conversation_id, json.dumps(snapshot, sort_keys=True), _now()),
            )

    def load_snapshot(self, conversation_id: str) -> dict[str, Any] | None:
        with self._lock:
            row = self._connection.execute(
                "SELECT snapshot_json FROM conversation_snapshots WHERE conversation_id = ?",
                (conversation_id,),
            ).fetchone()
            return json.loads(row["snapshot_json"]) if row else None

    def delete_conversation(self, conversation_id: str) -> None:
        conversation_id = _safe_identifier(conversation_id, "conversation_id")
        self.assert_deletable(conversation_id)
        with self._lock, self._connection:
            run_rows = self._connection.execute(
                "SELECT run_id FROM runs WHERE conversation_id = ?",
                (conversation_id,),
            ).fetchall()
            for row in run_rows:
                run_id = row["run_id"]
                self._connection.execute("DELETE FROM events WHERE run_id = ?", (run_id,))
                self._connection.execute("DELETE FROM late_events WHERE run_id = ?", (run_id,))
                self._connection.execute("DELETE FROM review_receipts WHERE run_id = ?", (run_id,))
                self._connection.execute("DELETE FROM ownership WHERE run_id = ?", (run_id,))
            self._connection.execute("DELETE FROM runs WHERE conversation_id = ?", (conversation_id,))
            self._connection.execute("DELETE FROM conversation_snapshots WHERE conversation_id = ?", (conversation_id,))
            self._connection.execute("DELETE FROM conversations WHERE conversation_id = ?", (conversation_id,))

    def list_snapshots(self) -> list[dict[str, Any]]:
        with self._lock:
            rows = self._connection.execute(
                "SELECT conversation_id, snapshot_json, updated_at FROM conversation_snapshots ORDER BY updated_at DESC"
            ).fetchall()
            return [json.loads(row["snapshot_json"]) for row in rows]

    def create_run(
        self,
        identity: RunIdentity,
        *,
        task_contract: dict[str, Any],
        allow_detached_replacement: bool = False,
    ) -> None:
        identity_errors = validate_identity(identity)
        if identity_errors:
            raise StoreError("; ".join(identity_errors))
        self.create_conversation(identity.conversation_id)
        with self._lock:
            row = self._connection.execute(
                "SELECT state FROM runs WHERE conversation_id = ? ORDER BY updated_at DESC",
                (identity.conversation_id,),
            ).fetchall()
            active = [item["state"] for item in row if not is_terminal(item["state"]) or item["state"] == RunState.DETACHED.value]
            if active and not allow_detached_replacement:
                raise StoreError(f"conversation {identity.conversation_id} already has a nonterminal or resumable run")
            with self._connection:
                self._connection.execute(
                    "INSERT INTO runs(run_id, conversation_id, parent_run_id, state, task_contract_json, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    (
                        identity.run_id,
                        identity.conversation_id,
                        identity.parent_run_id,
                        RunState.PLANNED.value,
                        json.dumps(task_contract, sort_keys=True),
                        _now(),
                        _now(),
                    ),
                )

    def _run_row(self, run_id: str) -> sqlite3.Row:
        row = self._connection.execute("SELECT * FROM runs WHERE run_id = ?", (run_id,)).fetchone()
        if row is None:
            raise StoreError(f"unknown run: {run_id}")
        return row

    @staticmethod
    def _event_fingerprint(event: dict[str, Any]) -> dict[str, Any]:
        value = dict(event)
        value.pop("timestamp", None)
        return value

    def _append_late_event(self, run_id: str, sequence: int, event: dict[str, Any]) -> str:
        event_json = json.dumps(event, sort_keys=True)
        normalized = dict(event)
        normalized.pop("timestamp", None)
        with self._connection:
            for existing in self._connection.execute(
                "SELECT event_json FROM late_events WHERE run_id = ?",
                (run_id,),
            ).fetchall():
                try:
                    prior = json.loads(existing["event_json"])
                except json.JSONDecodeError:
                    continue
                if self._event_fingerprint(prior) == normalized:
                    return "duplicate"
            self._connection.execute(
                "INSERT INTO late_events(run_id, sequence, event_json, created_at) VALUES (?, ?, ?, ?)",
                (run_id, sequence, event_json, _now()),
            )
        return "late"

    def append_event(self, event: dict[str, Any]) -> str:
        errors = validate_event(event, raise_on_error=False)
        if errors:
            raise ProtocolError("; ".join(errors))
        run_id = str(event["run_id"])
        sequence = int(event["sequence"])
        with self._lock:
            run = self._run_row(run_id)
            if event.get("conversation_id") != run["conversation_id"]:
                raise ProtocolError("event conversation_id does not match the run")
            if event.get("parent_run_id") != run["parent_run_id"]:
                raise ProtocolError("event parent_run_id does not match the run")
            latest = self._connection.execute(
                "SELECT sequence, event_json FROM events WHERE run_id = ? ORDER BY sequence DESC LIMIT 1",
                (run_id,),
            ).fetchone()
            expected = 1 if latest is None else int(latest["sequence"]) + 1
            if latest is not None and sequence == int(latest["sequence"]):
                try:
                    prior = json.loads(latest["event_json"])
                except json.JSONDecodeError:
                    prior = None
                if prior is not None and self._event_fingerprint(prior) == self._event_fingerprint(event):
                    return "duplicate"
                raise ProtocolError(f"sequence {sequence} already exists with different data")
            current_state = RunState(run["state"])
            claimed_state = event.get("data", {}).get("state")
            try:
                transition_allowed = claimed_state != current_state.value and can_transition(current_state, claimed_state)
            except (TypeError, ValueError):
                transition_allowed = False
            if is_terminal(current_state) and not transition_allowed:
                return self._append_late_event(run_id, sequence, event)
            if sequence < expected:
                return self._append_late_event(run_id, sequence, event)
            if sequence != expected:
                raise ProtocolError(f"expected event sequence {expected}, got {sequence}")
            terminal_targets = {
                EventType.RUN_COMPLETED.value: RunState.COMPLETED,
                EventType.RUN_FAILED.value: RunState.FAILED,
                EventType.RUN_BLOCKED.value: RunState.BLOCKED,
                EventType.RUN_INCOMPLETE.value: RunState.INCOMPLETE,
                EventType.RUN_CANCELLED.value: RunState.CANCELLED,
                EventType.RUN_DETACHED.value: RunState.DETACHED,
            }
            if event["kind"] in terminal_targets:
                target_state = terminal_targets[event["kind"]]
                claimed_target = event.get("data", {}).get("state")
                if claimed_target is not None and claimed_target != target_state.value:
                    raise ProtocolError("terminal event kind does not match its claimed state")
                try:
                    validate_transition(RunState(run["state"]), target_state)
                except LifecycleError as exc:
                    raise ProtocolError(str(exc)) from exc
                if target_state is RunState.COMPLETED:
                    receipt = event["data"].get("quality_receipt")
                    if not isinstance(receipt, dict) or receipt.get("passed") is not True:
                        raise ProtocolError("completed events require a passed quality receipt")
            with self._connection:
                self._connection.execute(
                    "INSERT INTO events(conversation_id, run_id, sequence, event_json, created_at) VALUES (?, ?, ?, ?, ?)",
                    (run_id, run_id, sequence, json.dumps(event, sort_keys=True), _now()),
                )
                if event["kind"] == EventType.RUN_COMPLETED.value:
                    self._connection.execute("UPDATE runs SET state = ?, updated_at = ? WHERE run_id = ?", (RunState.COMPLETED.value, _now(), run_id))
                elif event["kind"] in {
                    EventType.RUN_FAILED.value,
                    EventType.RUN_BLOCKED.value,
                    EventType.RUN_INCOMPLETE.value,
                    EventType.RUN_CANCELLED.value,
                    EventType.RUN_DETACHED.value,
                }:
                    state = {
                        EventType.RUN_FAILED.value: RunState.FAILED,
                        EventType.RUN_BLOCKED.value: RunState.BLOCKED,
                        EventType.RUN_INCOMPLETE.value: RunState.INCOMPLETE,
                        EventType.RUN_CANCELLED.value: RunState.CANCELLED,
                        EventType.RUN_DETACHED.value: RunState.DETACHED,
                    }[event["kind"]]
                    self._connection.execute("UPDATE runs SET state = ?, updated_at = ? WHERE run_id = ?", (state.value, _now(), run_id))
            return "accepted"

    def set_state(self, run_id: str, target: RunState | str, **details: Any) -> str:
        with self._lock:
            row = self._run_row(run_id)
            current = RunState(row["state"])
            target_value = target if isinstance(target, RunState) else RunState(target)
            if current == target_value:
                return "duplicate"
            validate_transition(current, target_value)
            sequence_row = self._connection.execute("SELECT MAX(sequence) FROM events WHERE run_id = ?", (run_id,)).fetchone()
            sequence = 1 if sequence_row[0] is None else int(sequence_row[0]) + 1
            event_kind = {
                RunState.COMPLETED: EventType.RUN_COMPLETED,
                RunState.FAILED: EventType.RUN_FAILED,
                RunState.BLOCKED: EventType.RUN_BLOCKED,
                RunState.INCOMPLETE: EventType.RUN_INCOMPLETE,
                RunState.CANCELLED: EventType.RUN_CANCELLED,
                RunState.DETACHED: EventType.RUN_DETACHED,
            }.get(target_value, EventType.STATUS)
            identity = RunIdentity(row["conversation_id"], run_id, row["parent_run_id"])
            event = make_event(identity, sequence, event_kind, transition_data(target_value, owner=self._owner, **details))
            result = self.append_event(event)
            if result == "accepted":
                with self._connection:
                    self._connection.execute("UPDATE runs SET state = ?, updated_at = ? WHERE run_id = ?", (target_value.value, _now(), run_id))
            return result

    def append_projection_event(self, run_id: str, kind: str, fields: dict[str, Any]) -> dict[str, Any]:
        with self._lock:
            row = self._run_row(run_id)
            sequence_row = self._connection.execute("SELECT MAX(sequence) FROM events WHERE run_id = ?", (run_id,)).fetchone()
            sequence = 1 if sequence_row[0] is None else int(sequence_row[0]) + 1
            identity = RunIdentity(row["conversation_id"], run_id, row["parent_run_id"])
            event = make_event(identity, sequence, EventType.EVIDENCE, {"kind": kind, "fields": fields})
            self.append_event(event)
            return event

    def record_evidence(self, run_id: str, evidence: dict[str, Any]) -> str:
        with self._lock:
            row = self._run_row(run_id)
            sequence_row = self._connection.execute("SELECT MAX(sequence) FROM events WHERE run_id = ?", (run_id,)).fetchone()
            sequence = 1 if sequence_row[0] is None else int(sequence_row[0]) + 1
            identity = RunIdentity(row["conversation_id"], run_id, row["parent_run_id"])
            return self.append_event(make_event(identity, sequence, EventType.EVIDENCE, evidence))

    def latest_evidence(self, run_id: str, kind: str) -> dict | None:
        """Return the newest run-owned evidence payload of one kind."""
        with self._lock:
            rows = self._connection.execute(
                "SELECT event_json FROM events WHERE run_id = ? ORDER BY sequence DESC",
                (run_id,),
            ).fetchall()
        for item in rows:
            try:
                event = json.loads(item["event_json"])
            except json.JSONDecodeError:
                continue
            data = event.get("data") or {}
            if data.get("kind") == kind:
                return data
        return None

    def recent_ui_visual_evidence(self, run_id: str, *, limit: int = 20) -> list[dict[str, Any]]:
        """Return recent run-owned render evidence for local novelty checks."""
        with self._lock:
            rows = self._connection.execute(
                "SELECT e.run_id, e.event_json FROM events e "
                "JOIN runs r ON r.run_id = e.run_id "
                "WHERE e.run_id != ? AND r.state = 'completed' "
                "ORDER BY e.created_at DESC LIMIT ?",
                (run_id, max(0, limit) * 20),
            ).fetchall()
        results: list[dict[str, Any]] = []
        for row in rows:
            try:
                event = json.loads(row["event_json"])
            except json.JSONDecodeError:
                continue
            data = event.get("data") or {}
            if data.get("kind") != "ui_visual_evidence":
                continue
            payload = data.get("payload") or data.get("visual") or {}
            rendered = payload.get("rendered", {}).get("images", [])
            paths = [item.get("path") for item in rendered if isinstance(item, dict) and item.get("path")]
            if paths:
                results.append({"run_id": row["run_id"], "product_family": str(payload.get("product_family", "")), "rendered": paths})
            if len(results) >= limit:
                break
        return results

    def record_provider_telemetry(
        self,
        run_id: str,
        provider: str,
        provider_session_id: str,
        payload: dict[str, Any],
        *,
        attempt_id: str | None = None,
    ) -> str:
        if not provider or not provider_session_id:
            raise StoreError("provider telemetry requires provider and provider session IDs")
        if not isinstance(payload, dict):
            raise StoreError("provider telemetry payload must be an object")
        with self._lock:
            row = self._run_row(run_id)
            manifest = self.load_manifest(run_id)
            if not manifest or not manifest_has_ownership(manifest):
                raise StoreError("provider telemetry requires an owned run manifest")
            manifest_identity = manifest.get("identity", {})
            bound_session = manifest_identity.get("provider_session_id")
            if not bound_session or bound_session != provider_session_id:
                raise StoreError("provider telemetry does not match the owned provider session")
            bound_provider = manifest.get("provider")
            if not bound_provider or bound_provider != provider:
                raise StoreError("provider telemetry does not match the owned provider")
            sequence_row = self._connection.execute("SELECT MAX(sequence) FROM events WHERE run_id = ?", (run_id,)).fetchone()
            sequence = 1 if sequence_row[0] is None else int(sequence_row[0]) + 1
            identity = RunIdentity(
                row["conversation_id"],
                run_id,
                row["parent_run_id"],
                attempt_id,
                provider_session_id,
            )
            identity_errors = validate_identity(identity)
            if identity_errors:
                raise StoreError("; ".join(identity_errors))
            event = make_event(
                identity,
                sequence,
                EventType.EVIDENCE,
                {
                    "kind": "provider_telemetry",
                    "provider": provider,
                    "provider_session_id": provider_session_id,
                    "payload": payload,
                },
            )
            return self.append_event(event)

    def save_manifest(self, manifest: dict[str, Any] | RunManifest) -> None:
        value = manifest.as_dict() if isinstance(manifest, RunManifest) else RunManifest.from_dict(manifest).as_dict()
        identity = value["identity"]
        run_id = str(identity["run_id"])
        run = self._run_row(run_id)
        if identity.get("conversation_id") != run["conversation_id"]:
            raise StoreError("manifest conversation_id does not match the run")
        with self._lock, self._connection:
            self._connection.execute(
                "INSERT INTO ownership(run_id, manifest_json, updated_at) VALUES (?, ?, ?) ON CONFLICT(run_id) DO UPDATE SET manifest_json = excluded.manifest_json, updated_at = excluded.updated_at",
                (run_id, json.dumps(value, sort_keys=True), _now()),
            )

    def load_manifest(self, run_id: str) -> dict[str, Any] | None:
        with self._lock:
            row = self._connection.execute(
                "SELECT manifest_json FROM ownership WHERE run_id = ?",
                (run_id,),
            ).fetchone()
            return json.loads(row["manifest_json"]) if row else None

    def has_ownership(self, run_id: str) -> bool:
        manifest = self.load_manifest(run_id)
        if not manifest:
            return False
        return manifest_has_ownership(manifest)

    def has_committed_ownership(self, run_id: str) -> bool:
        manifest = self.load_manifest(run_id)
        if not manifest or manifest.get("committed") is not True:
            return False
        return manifest_has_ownership(manifest)

    def save_review_receipt(self, run_id: str, receipt: ReviewReceipt) -> None:
        """Persist a reviewer receipt only after binding it to the run manifest."""
        receipt.validate()
        if self.state(run_id) not in {"starting", "working", "verifying", "reviewing", "repairing", "blocked"}:
            raise StoreError("review receipts are accepted only during an active review window")
        manifest = self.load_manifest(run_id)
        if not manifest:
            raise StoreError("cannot persist a review receipt without an ownership manifest")
        reviewer = manifest.get("reviewer") or {}
        identity = manifest.get("identity") or {}
        if (
            manifest.get("provider") != receipt.provider
            or reviewer.get("reviewer_id") != receipt.reviewer_id
            or reviewer.get("provider_session_id") != receipt.provider_session_id
            or not identity.get("provider_session_id")
            or identity.get("provider_session_id") == receipt.provider_session_id
            or receipt.run_id != run_id
            or receipt.workspace != (manifest.get("workspace") or "")
            or receipt.evidence_generation != (manifest.get("evidence_generation") or "")
            or receipt.artifact_revision != (manifest.get("artifact_revision") or "")
        ):
            raise StoreError("review receipt identity is not bound to the owned reviewer session")
        with self._lock, self._connection:
            self._connection.execute(
                "INSERT INTO review_receipts(run_id, receipt_json, created_at) VALUES (?, ?, ?) ON CONFLICT(run_id) DO UPDATE SET receipt_json = excluded.receipt_json, created_at = excluded.created_at",
                (run_id, json.dumps(receipt.as_dict(), sort_keys=True), _now()),
            )
        self.record_evidence(
            run_id,
            {
                "kind": "review_receipt_stored",
                "reviewer_id": receipt.reviewer_id,
                "provider": receipt.provider,
                "provider_session_id": receipt.provider_session_id,
            },
        )

    def load_review_receipt(self, run_id: str) -> ReviewReceipt | None:
        with self._lock:
            row = self._connection.execute(
                "SELECT receipt_json FROM review_receipts WHERE run_id = ?",
                (run_id,),
            ).fetchone()
        if not row:
            return None
        try:
            return ReviewReceipt.from_dict(json.loads(row["receipt_json"]))
        except (TypeError, ValueError, json.JSONDecodeError):
            return None

    def assert_deletable(self, conversation_id: str) -> None:
        with self._lock:
            rows = self._connection.execute(
                "SELECT run_id, state FROM runs WHERE conversation_id = ?",
                (conversation_id,),
            ).fetchall()
            if any(not is_terminal(row["state"]) or row["state"] == RunState.DETACHED.value for row in rows):
                raise StoreError(f"conversation {conversation_id} has an active or resumable run")
            for row in rows:
                manifest = self.load_manifest(row["run_id"])
                if manifest and any(resource.get("state") in {"intended", "created", "owned"} for resource in manifest.get("resources", [])):
                    raise StoreError(f"run {row['run_id']} still owns external resources")

    def state(self, run_id: str) -> str:
        with self._lock:
            return str(self._run_row(run_id)["state"])

    def snapshot(self, conversation_id: str) -> dict[str, Any]:
        with self._lock:
            conversation = self._connection.execute("SELECT * FROM conversations WHERE conversation_id = ?", (conversation_id,)).fetchone()
            runs = self._connection.execute("SELECT * FROM runs WHERE conversation_id = ? ORDER BY created_at", (conversation_id,)).fetchall()
            result: dict[str, Any] = {
                "conversation": dict(conversation) if conversation else None,
                "runs": [],
            }
            for run in runs:
                events = self._connection.execute("SELECT event_json FROM events WHERE run_id = ? ORDER BY sequence", (run["run_id"],)).fetchall()
                late = self._connection.execute("SELECT event_json FROM late_events WHERE run_id = ? ORDER BY late_id", (run["run_id"],)).fetchall()
                ownership = self._connection.execute("SELECT manifest_json FROM ownership WHERE run_id = ?", (run["run_id"],)).fetchone()
                result["runs"].append({
                    "run_id": run["run_id"],
                    "parent_run_id": run["parent_run_id"],
                    "state": run["state"],
                    "task_contract": json.loads(run["task_contract_json"]),
                    "events": [json.loads(item["event_json"]) for item in events],
                    "late_events": [json.loads(item["event_json"]) for item in late],
                    "ownership": json.loads(ownership["manifest_json"]) if ownership else None,
                })
            return result


def _safe_identifier(value: str, field: str) -> str:
    value = str(value or "")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,127}", value) or value in {".", ".."}:
        raise StoreError(f"{field} contains unsafe path characters")
    return value


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()
