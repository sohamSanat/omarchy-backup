"""Authoritative dictation state transitions for UI projections."""
from __future__ import annotations

from enum import StrEnum


class DictationState(StrEnum):
    IDLE = "idle"
    STARTING = "starting"
    LISTENING = "listening"
    STOPPING = "stopping"
    ERROR = "error"


_ALLOWED = {
    DictationState.IDLE: {DictationState.STARTING},
    DictationState.STARTING: {DictationState.LISTENING, DictationState.ERROR, DictationState.IDLE},
    DictationState.LISTENING: {DictationState.STOPPING, DictationState.ERROR, DictationState.IDLE},
    DictationState.STOPPING: {DictationState.IDLE, DictationState.ERROR},
    DictationState.ERROR: {DictationState.IDLE, DictationState.STARTING},
}


class DictationStateError(ValueError):
    """Raised when backend state is impossible or out of order."""


def transition(current: DictationState | str, target: DictationState | str) -> DictationState:
    current_value = current if isinstance(current, DictationState) else DictationState(current)
    target_value = target if isinstance(target, DictationState) else DictationState(target)
    if target_value not in _ALLOWED[current_value]:
        raise DictationStateError(f"invalid dictation transition: {current_value} -> {target_value}")
    return target_value
