"""Authoritative run lifecycle transitions.

The legacy ``done`` acknowledgement is intentionally not a lifecycle state.
A run becomes completed only after the quality profile has committed the
required evidence and the controller emits a terminal event.
"""
from __future__ import annotations

from enum import StrEnum
from typing import Any


class RunState(StrEnum):
    PLANNED = "planned"
    STARTING = "starting"
    WORKING = "working"
    VERIFYING = "verifying"
    REVIEWING = "reviewing"
    REPAIRING = "repairing"
    AWAITING_USER = "awaiting_user"
    RECOVERING = "recovering"
    REATTACHING = "reattaching"
    BLOCKED = "blocked"
    SETUP_FAILED = "setup_failed"
    CANCELLED_BEFORE_START = "cancelled_before_start"
    CANCEL_REQUESTED = "cancel_requested"
    CLEANUP_PENDING = "cleanup_pending"
    CANCELLED = "cancelled"
    DETACHED = "detached"
    INCOMPLETE = "incomplete"
    FAILED = "failed"
    COMPLETED = "completed"


TERMINAL_STATES = frozenset({
    RunState.SETUP_FAILED,
    RunState.CANCELLED_BEFORE_START,
    RunState.CANCELLED,
    RunState.DETACHED,
    RunState.INCOMPLETE,
    RunState.FAILED,
    RunState.COMPLETED,
})

_ALLOWED: dict[RunState, frozenset[RunState]] = {
    RunState.PLANNED: frozenset({RunState.STARTING, RunState.AWAITING_USER, RunState.CANCELLED_BEFORE_START, RunState.BLOCKED}),
    RunState.STARTING: frozenset({RunState.WORKING, RunState.SETUP_FAILED, RunState.BLOCKED, RunState.CANCELLED_BEFORE_START, RunState.CANCEL_REQUESTED, RunState.DETACHED}),
    RunState.WORKING: frozenset({RunState.VERIFYING, RunState.AWAITING_USER, RunState.RECOVERING, RunState.BLOCKED, RunState.CANCEL_REQUESTED, RunState.SETUP_FAILED, RunState.DETACHED}),
    RunState.VERIFYING: frozenset({RunState.REVIEWING, RunState.REPAIRING, RunState.FAILED, RunState.INCOMPLETE, RunState.BLOCKED, RunState.CANCEL_REQUESTED}),
    RunState.REVIEWING: frozenset({RunState.REPAIRING, RunState.COMPLETED, RunState.INCOMPLETE, RunState.BLOCKED, RunState.CANCEL_REQUESTED}),
    RunState.REPAIRING: frozenset({RunState.VERIFYING, RunState.FAILED, RunState.INCOMPLETE, RunState.BLOCKED, RunState.CANCEL_REQUESTED}),
    RunState.AWAITING_USER: frozenset({RunState.STARTING, RunState.PLANNED, RunState.BLOCKED, RunState.CANCEL_REQUESTED, RunState.CANCELLED}),
    RunState.BLOCKED: frozenset({RunState.STARTING, RunState.WORKING, RunState.CANCEL_REQUESTED, RunState.CLEANUP_PENDING, RunState.FAILED, RunState.INCOMPLETE, RunState.DETACHED}),
    RunState.RECOVERING: frozenset({RunState.REATTACHING, RunState.WORKING, RunState.BLOCKED, RunState.FAILED}),
    RunState.REATTACHING: frozenset({RunState.WORKING, RunState.VERIFYING, RunState.BLOCKED, RunState.FAILED}),
    RunState.CANCEL_REQUESTED: frozenset({RunState.CLEANUP_PENDING, RunState.CANCELLED, RunState.BLOCKED}),
    RunState.CLEANUP_PENDING: frozenset({RunState.CANCELLED, RunState.FAILED, RunState.BLOCKED}),
    RunState.DETACHED: frozenset({RunState.REATTACHING, RunState.CANCEL_REQUESTED, RunState.BLOCKED}),
}

RESUMABLE_STATES = frozenset({RunState.DETACHED, RunState.RECOVERING})


class LifecycleError(ValueError):
    """Raised when a run would enter an invalid state."""


def is_terminal(state: RunState | str) -> bool:
    value = state if isinstance(state, RunState) else RunState(state)
    return value in TERMINAL_STATES


def can_transition(current: RunState | str, target: RunState | str) -> bool:
    current_value = current if isinstance(current, RunState) else RunState(current)
    target_value = target if isinstance(target, RunState) else RunState(target)
    if current_value == target_value:
        return True
    return target_value in _ALLOWED.get(current_value, frozenset())


def validate_transition(current: RunState | str, target: RunState | str) -> None:
    if not can_transition(current, target):
        raise LifecycleError(f"invalid run transition: {current} -> {target}")


def transition_data(state: RunState | str, **details: Any) -> dict[str, Any]:
    value = state if isinstance(state, RunState) else RunState(state)
    return {"state": value.value, **details}
