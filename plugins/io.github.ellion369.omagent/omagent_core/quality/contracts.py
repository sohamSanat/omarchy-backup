"""Small, serializable quality contracts shared by every profile."""
from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any


@dataclass(frozen=True)
class TaskContract:
    request: str
    profile: str
    acceptance_criteria: list[str] = field(default_factory=list)
    constraints: list[str] = field(default_factory=list)
    assumptions: list[str] = field(default_factory=list)

    def validate(self) -> None:
        if not self.request.strip():
            raise ValueError("quality task request must not be empty")
        if not self.profile.strip():
            raise ValueError("quality profile must not be empty")
        if not self.acceptance_criteria:
            raise ValueError("quality task must declare acceptance criteria")


@dataclass(frozen=True)
class CheckResult:
    name: str
    passed: bool
    evidence: list[str] = field(default_factory=list)
    blocking: bool = True

    def validate(self) -> None:
        if not self.name.strip():
            raise ValueError("check name must not be empty")
        if not self.evidence:
            raise ValueError(f"check {self.name} must include evidence")


@dataclass(frozen=True)
class ReviewFinding:
    title: str
    blocking: bool
    evidence: list[str] = field(default_factory=list)
    resolved: bool = False

    def validate(self) -> None:
        if not isinstance(self.title, str) or not self.title.strip():
            raise ValueError("review finding must have a title")
        if not isinstance(self.blocking, bool) or not isinstance(self.resolved, bool):
            raise ValueError("review finding flags must be booleans")
        if not isinstance(self.evidence, list) or not self.evidence or any(not isinstance(item, str) or not item.strip() for item in self.evidence):
            raise ValueError(f"review finding {self.title} must include evidence")


def contract_dict(contract: TaskContract) -> dict[str, Any]:
    return asdict(contract)
