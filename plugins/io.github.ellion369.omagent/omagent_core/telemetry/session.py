"""Session-scoped provider telemetry buffering.

Telemetry is accepted only after a run/provider-session binding exists. This
keeps a provider's output from being attributed to another run that happens to
share the same host or process supervisor.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


class TelemetryBindingError(ValueError):
    """Raised when telemetry does not match the run-owned provider identity."""


@dataclass(frozen=True)
class TelemetryBinding:
    run_id: str
    provider: str
    provider_session_id: str


@dataclass
class TelemetryEvent:
    run_id: str
    provider: str
    provider_session_id: str
    payload: dict[str, Any]
    sequence: int


@dataclass
class SessionTelemetry:
    bindings: dict[tuple[str, str], TelemetryBinding] = field(default_factory=dict)
    events: dict[tuple[str, str], list[TelemetryEvent]] = field(default_factory=dict)

    def bind(self, *, run_id: str, provider: str, provider_session_id: str) -> TelemetryBinding:
        if not run_id or not provider or not provider_session_id:
            raise TelemetryBindingError("telemetry binding requires run, provider, and provider session IDs")
        key = (run_id, provider_session_id)
        existing = self.bindings.get(key)
        if existing and existing.provider != provider:
            raise TelemetryBindingError("provider session is already bound to another provider")
        binding = TelemetryBinding(run_id, provider, provider_session_id)
        self.bindings[key] = binding
        return binding

    def append(self, *, run_id: str, provider: str, provider_session_id: str, payload: dict[str, Any]) -> TelemetryEvent:
        key = (run_id, provider_session_id)
        binding = self.bindings.get(key)
        if binding is None:
            raise TelemetryBindingError("provider session is not bound to this run")
        if binding.provider != provider:
            raise TelemetryBindingError("provider does not match the bound provider identity")
        if not isinstance(payload, dict):
            raise TelemetryBindingError("telemetry payload must be an object")
        sequence = len(self.events.get(key, [])) + 1
        event = TelemetryEvent(run_id, provider, provider_session_id, payload, sequence)
        self.events.setdefault(key, []).append(event)
        return event

    def for_run(self, run_id: str) -> list[TelemetryEvent]:
        return [
            event
            for (event_run, _), values in self.events.items()
            if event_run == run_id
            for event in values
        ]

    def for_session(self, run_id: str, provider: str, provider_session_id: str) -> list[TelemetryEvent]:
        binding = self.bindings.get((run_id, provider_session_id))
        if binding is None or binding.provider != provider:
            raise TelemetryBindingError("provider session is not bound to this run")
        return list(self.events.get((run_id, provider_session_id), []))
