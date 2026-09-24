"""Task-driven fleet planning.

Fleet planning chooses roles and shared-workspace policy; it does not spawn
workers or create Firstmate tasks.
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class FleetRole:
    name: str
    mission: str
    writes_workspace: bool = False
    model_override: str | None = None


@dataclass(frozen=True)
class FleetPlan:
    roles: tuple[FleetRole, ...]
    serialize_writes: bool = True

    @property
    def role_names(self) -> tuple[str, ...]:
        return tuple(role.name for role in self.roles)


def plan_fleet(*, track: str, requires_review: bool = True, requires_ui: bool = False) -> FleetPlan:
    if track not in {"coding", "ui"}:
        return FleetPlan((FleetRole("lead", "produce the requested deliverable", writes_workspace=True),))
    roles = [FleetRole("lead", "plan and implement the requested deliverable", writes_workspace=True)]
    if track == "ui" or requires_ui:
        roles.append(FleetRole("ui-specialist", "implement and inspect the visual contract", writes_workspace=True))
    if requires_review:
        roles.append(FleetRole("reviewer", "independently review evidence and report blocking findings"))
    return FleetPlan(tuple(roles))
