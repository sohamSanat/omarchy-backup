"""Controller command and projection boundaries."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol
from uuid import uuid4

from .identity import RunIdentity
from .lifecycle import RunState, is_terminal
from .session_store import SessionStore


class Projection(Protocol):
    """Read-only view consumed by QML and future clients."""

    def snapshot(self, conversation_id: str) -> dict[str, Any]: ...


@dataclass(frozen=True)
class ControllerCommand:
    name: str
    conversation_id: str
    run_id: str | None = None
    payload: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class CommandResult:
    ok: bool
    command: str
    conversation_id: str
    run_id: str | None
    state: str
    data: dict[str, Any] = field(default_factory=dict)
    error_code: str | None = None


class RunController:
    """Small orchestration facade over the authoritative store.

    Provider launch and cleanup are deliberately outside this class. It owns
    only lifecycle commands and projections, which keeps the dry-run path
    side-effect free until an explicit execution command is introduced.
    """

    def __init__(self, store: SessionStore) -> None:
        self.store = store

    def start(
        self,
        conversation_id: str,
        request: str,
        *,
        mode: str = "regular",
        parent_run_id: str | None = None,
    ) -> RunIdentity:
        run_id = f"run-{uuid4().hex}"
        identity = RunIdentity(conversation_id, run_id, parent_run_id=parent_run_id)
        self.store.create_conversation(conversation_id, title=request[:80])
        self.store.create_run(identity, task_contract={"request": request, "mode": mode})
        self.store.set_state(run_id, RunState.STARTING)
        return identity

    def ensure_run(
        self,
        conversation_id: str,
        request: str,
        *,
        mode: str = "regular",
        new_task: bool = False,
    ) -> RunIdentity:
        snapshot = self.store.snapshot(conversation_id)
        runs = snapshot.get("runs", [])
        if new_task:
            previous = runs[-1] if runs else None
            if previous:
                previous_state = previous.get("state", "")
                try:
                    previous_active = not is_terminal(previous_state)
                except ValueError:
                    previous_active = False
                if previous_active or previous_state == RunState.DETACHED.value:
                    raise RuntimeError("cannot start a new task while the prior run is active or detached")
                if self.store.has_ownership(previous.get("run_id", "")):
                    raise RuntimeError("cannot start a new task while the prior run still owns resources")
                return self.start(
                    conversation_id,
                    request,
                    mode=mode,
                    parent_run_id=previous.get("run_id"),
                )
        for run in runs:
            state = run.get("state", "")
            try:
                active = not is_terminal(state)
            except ValueError:
                active = False
            if active or state == RunState.DETACHED.value:
                return RunIdentity(
                    conversation_id,
                    run["run_id"],
                    run.get("parent_run_id"),
                )
        return self.start(conversation_id, request, mode=mode)

    def record_evidence(self, run_id: str, evidence: dict[str, Any]) -> None:
        self.store.record_evidence(run_id, evidence)

    def stop(self, run_id: str, *, ownership_confirmed: bool | None = None) -> RunState:
        # Accept the legacy keyword for compatibility, but never let a caller
        # override the authoritative manifest-derived ownership decision.
        ownership_confirmed = self.store.has_ownership(run_id)
        if not ownership_confirmed:
            current = RunState(self.store.state(run_id))
            if current in {RunState.PLANNED, RunState.STARTING}:
                self.store.set_state(run_id, RunState.CANCELLED_BEFORE_START, reason="stop before ownership receipt")
                return RunState.CANCELLED_BEFORE_START
            self.store.set_state(run_id, RunState.BLOCKED, reason="stop requested without an ownership receipt")
            return RunState.BLOCKED
        self.store.set_state(run_id, RunState.CANCEL_REQUESTED)
        return RunState.CANCEL_REQUESTED

    def acknowledge_stop(self, run_id: str) -> RunState:
        if self.store.has_ownership(run_id):
            raise RuntimeError("cannot acknowledge cancellation while resources remain owned")
        self.store.set_state(run_id, RunState.CLEANUP_PENDING)
        self.store.set_state(run_id, RunState.CANCELLED)
        return RunState.CANCELLED

    def detach(self, run_id: str) -> RunState:
        if not self.store.has_committed_ownership(run_id):
            raise RuntimeError("cannot detach a run without a committed ownership receipt")
        self.store.set_state(run_id, RunState.DETACHED)
        return RunState.DETACHED

    def resume(self, run_id: str) -> RunState:
        if not self.store.has_committed_ownership(run_id):
            raise RuntimeError("cannot resume a run without a committed ownership receipt")
        self.store.set_state(run_id, RunState.REATTACHING)
        self.store.set_state(run_id, RunState.WORKING)
        return RunState.WORKING

    def snapshot(self, conversation_id: str) -> dict[str, Any]:
        return self.store.snapshot(conversation_id)
