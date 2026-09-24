"""Pure provider routing decisions.

Health, quota, and catalog data are snapshots. This module never probes a
provider, launches a process, or mutates the model pool.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable


SUPPORTED_PROVIDERS = frozenset({"agy", "opencode", "cline"})


@dataclass(frozen=True)
class ProviderHealth:
    provider: str
    available: bool
    authenticated: bool = True
    quota_exhausted: bool = False
    reason: str = ""


@dataclass(frozen=True)
class RoutingDecision:
    provider: str
    model: str
    requested_provider: str
    fallback_used: bool
    reason: str
    considered: tuple[str, ...]


def choose_provider(
    *,
    requested_provider: str,
    requested_model: str,
    health: Iterable[ProviderHealth],
    models_by_provider: dict[str, str],
    preferred_order: Iterable[str] = ("agy", "opencode", "cline"),
    available_models: dict[str, set[str]] | None = None,
) -> RoutingDecision:
    health_by_provider = {item.provider: item for item in health}
    considered: list[str] = []
    if requested_provider in SUPPORTED_PROVIDERS:
        considered.append(requested_provider)
        item = health_by_provider.get(requested_provider)
        model_allowed = available_models is None or requested_model in available_models.get(requested_provider, set())
        if item and item.available and item.authenticated and not item.quota_exhausted and model_allowed:
            return RoutingDecision(requested_provider, requested_model, requested_provider, False, "requested provider is healthy", tuple(considered))
        reason = item.reason if item and item.reason else "requested provider is unavailable"
        if not model_allowed:
            reason = f"requested model {requested_model!r} is not in the {requested_provider} catalog"
    else:
        reason = f"requested provider {requested_provider!r} has no adapter"
    for provider in preferred_order:
        if provider in considered:
            continue
        considered.append(provider)
        if provider not in SUPPORTED_PROVIDERS:
            continue
        item = health_by_provider.get(provider)
        if item and item.available and item.authenticated and not item.quota_exhausted and models_by_provider.get(provider):
            return RoutingDecision(provider, models_by_provider[provider], requested_provider, True, reason, tuple(considered))
    raise RoutingUnavailable(reason, tuple(considered))


class RoutingUnavailable(RuntimeError):
    def __init__(self, reason: str, considered: tuple[str, ...]) -> None:
        super().__init__(f"{reason}; considered: {', '.join(considered) or 'none'}")
        self.reason = reason
        self.considered = considered
