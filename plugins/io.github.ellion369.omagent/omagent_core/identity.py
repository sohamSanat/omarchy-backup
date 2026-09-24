"""Identity records kept separate across the controller boundary."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class RunIdentity:
    conversation_id: str
    run_id: str
    parent_run_id: str | None = None
    attempt_id: str | None = None
    provider_session_id: str | None = None

    def as_dict(self) -> dict[str, str | None]:
        return {
            "conversation_id": self.conversation_id,
            "run_id": self.run_id,
            "parent_run_id": self.parent_run_id,
            "attempt_id": self.attempt_id,
            "provider_session_id": self.provider_session_id,
        }


def validate_identity(identity: RunIdentity) -> list[str]:
    errors: list[str] = []
    for name, value in (("conversation_id", identity.conversation_id), ("run_id", identity.run_id)):
        if not value or "/" in value or "\\" in value or value in {".", ".."}:
            errors.append(f"{name} is not a safe identifier")
    for name, value in (("parent_run_id", identity.parent_run_id), ("attempt_id", identity.attempt_id), ("provider_session_id", identity.provider_session_id)):
        if value is not None and (not value or "/" in value or "\\" in value or value in {".", ".."}):
            errors.append(f"{name} is not a safe identifier")
    return errors


def identity_from_dict(value: dict[str, Any]) -> RunIdentity:
    return RunIdentity(
        conversation_id=str(value["conversation_id"]),
        run_id=str(value["run_id"]),
        parent_run_id=value.get("parent_run_id"),
        attempt_id=value.get("attempt_id"),
        provider_session_id=value.get("provider_session_id"),
    )
