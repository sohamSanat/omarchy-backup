"""Provider adapters used by the coding profile.

These adapters build commands and parse telemetry; they do not execute the
commands. Execution belongs to the run-owned orchestration layer.
"""
from __future__ import annotations

import json
from typing import Any

from .base import LaunchSpec, ProviderCapabilities


class AgyAdapter:
    provider = "agy"
    capabilities = ProviderCapabilities(provider, True, True, True, True, True)

    def build_launch_spec(self, model: str, prompt: str, *, workspace: str | None = None) -> LaunchSpec:
        return LaunchSpec(self.provider, ("agy", "--model", model, "--auto-approve", "true", "--prompt", prompt), workspace=workspace)

    def parse_telemetry(self, payload: str) -> dict[str, Any]:
        return _json_or_text(payload, self.provider)


class OpenCodeAdapter:
    provider = "opencode"
    capabilities = ProviderCapabilities(provider, True, True, True, True, True)

    def build_launch_spec(self, model: str, prompt: str, *, workspace: str | None = None) -> LaunchSpec:
        return LaunchSpec(self.provider, ("opencode", "run", "--model", model, "--auto", prompt), workspace=workspace)

    def parse_telemetry(self, payload: str) -> dict[str, Any]:
        return _json_or_text(payload, self.provider)


class ClineAdapter:
    provider = "cline"
    capabilities = ProviderCapabilities(provider, True, True, True, False, True)

    def build_launch_spec(self, model: str, prompt: str, *, workspace: str | None = None) -> LaunchSpec:
        return LaunchSpec(self.provider, ("cline", "--auto-approve", "true", "--model", model, prompt), workspace=workspace)

    def parse_telemetry(self, payload: str) -> dict[str, Any]:
        return _json_or_text(payload, self.provider)


def _json_or_text(payload: str, provider: str) -> dict[str, Any]:
    try:
        value = json.loads(payload)
        if isinstance(value, dict):
            return {"provider": provider, **value}
    except json.JSONDecodeError:
        pass
    return {"provider": provider, "text": payload}


ADAPTERS = {adapter.provider: adapter for adapter in (AgyAdapter(), OpenCodeAdapter(), ClineAdapter())}


def launch_spec(provider: str, model: str, prompt: str, *, workspace: str | None = None) -> LaunchSpec:
    try:
        adapter = ADAPTERS[provider]
    except KeyError as exc:
        raise ValueError(f"unsupported provider: {provider}") from exc
    return adapter.build_launch_spec(model, prompt, workspace=workspace)
