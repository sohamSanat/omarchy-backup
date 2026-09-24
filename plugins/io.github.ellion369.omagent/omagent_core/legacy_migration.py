"""Explicit, idempotent migration of legacy JSON session projections."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Iterable

from .identity import RunIdentity
from .lifecycle import RunState
from .session_store import SessionStore, StoreError


@dataclass
class MigrationReport:
    imported: list[str] = field(default_factory=list)
    recovery_required: list[str] = field(default_factory=list)
    skipped: list[dict[str, str]] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return all(item.get("reason") == "already imported" for item in self.skipped)


def migrate_snapshots(store: SessionStore, snapshots: Iterable[dict[str, Any]]) -> MigrationReport:
    report = MigrationReport()
    for snapshot in snapshots:
        if not isinstance(snapshot, dict):
            report.skipped.append({"session": "", "reason": "snapshot is not an object"})
            continue
        session_id = str(snapshot.get("sessionId") or "").strip()
        if not session_id:
            report.skipped.append({"session": "", "reason": "snapshot has no sessionId"})
            continue
        if store.load_snapshot(session_id) is not None:
            report.skipped.append({"session": session_id, "reason": "already imported"})
            continue
        store.save_snapshot(session_id, snapshot)
        report.imported.append(session_id)
        state = str(snapshot.get("runState", "")).lower()
        try:
            legacy_pid = int(snapshot.get("runPid", 0) or 0)
        except (TypeError, ValueError):
            legacy_pid = 0
        if state in {"running", "detached"} or legacy_pid > 0:
            run_id = f"legacy-recovery-{session_id}"
            try:
                identity = RunIdentity(session_id, run_id)
                store.create_run(identity, task_contract={"legacy_snapshot": snapshot, "recovery_required": True})
                store.set_state(run_id, RunState.STARTING, reason="legacy active record")
                store.set_state(run_id, RunState.WORKING, reason="legacy active record")
                store.set_state(run_id, RunState.RECOVERING, reason="legacy ownership receipt is missing")
                report.recovery_required.append(session_id)
            except StoreError as exc:
                report.skipped.append({"session": session_id, "reason": str(exc)})
    return report
