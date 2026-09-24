"""Versioned event envelope contract for controller projections."""
from __future__ import annotations

from datetime import datetime, timezone
from enum import StrEnum
from typing import Any

from .identity import RunIdentity


class EventType(StrEnum):
    STATUS = "status"
    EVIDENCE = "evidence"
    QUESTION = "question"
    RUN_STARTED = "run_started"
    RUN_COMPLETED = "run_completed"
    RUN_FAILED = "run_failed"
    RUN_BLOCKED = "run_blocked"
    RUN_INCOMPLETE = "run_incomplete"
    RUN_CANCELLED = "run_cancelled"
    RUN_DETACHED = "run_detached"


class ProtocolError(ValueError):
    """Raised when an event violates the controller protocol."""


def make_event(identity: RunIdentity, sequence: int, kind: EventType, data: dict[str, Any]) -> dict[str, Any]:
    return {
        "schema_version": 1,
        "conversation_id": identity.conversation_id,
        "run_id": identity.run_id,
        "parent_run_id": identity.parent_run_id,
        "attempt_id": identity.attempt_id,
        "provider_session_id": identity.provider_session_id,
        "sequence": sequence,
        "kind": kind.value,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "data": data,
    }


def validate_event(event: dict[str, Any], *, raise_on_error: bool = True) -> list[str]:
    errors: list[str] = []
    if event.get("schema_version") != 1:
        errors.append("schema_version must be 1")
    for key in ("conversation_id", "run_id", "sequence", "kind", "timestamp", "data"):
        if key not in event:
            errors.append(f"missing {key}")
    sequence = event.get("sequence")
    if not isinstance(sequence, int) or sequence < 1:
        errors.append("sequence must be a positive integer")
    kind = event.get("kind")
    if kind not in {item.value for item in EventType}:
        errors.append("kind is not a supported event type")
    if not isinstance(event.get("data"), dict):
        errors.append("data must be an object")
    if errors and raise_on_error:
        raise ProtocolError("; ".join(errors))
    return errors
