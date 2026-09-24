"""Provider adapter contract and immutable launch specifications."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Protocol


@dataclass(frozen=True)
class ProviderCapabilities:
    provider: str
    launch: bool
    telemetry: bool
    cancellation: bool
    same_session_resume: bool
    same_workspace_handoff: bool


@dataclass(frozen=True)
class LaunchSpec:
    provider: str
    command: tuple[str, ...]
    auto_approve: bool = True
    workspace: str | None = None

    def as_dict(self) -> dict[str, Any]:
        return {"provider": self.provider, "command": list(self.command), "auto_approve": self.auto_approve, "workspace": self.workspace}


class ProviderAdapter(Protocol):
    capabilities: ProviderCapabilities

    def build_launch_spec(self, model: str, prompt: str, *, workspace: str | None = None) -> LaunchSpec: ...
    def parse_telemetry(self, payload: str) -> dict[str, Any]: ...
