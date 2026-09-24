"""Typed evidence contracts for run-owned UI rendering and checks."""
from __future__ import annotations

import hashlib
import json
from dataclasses import asdict, dataclass, field
from typing import Any, Protocol

from .screenshot_policy import ScreenshotPolicyError, validate_screenshot_target

EVIDENCE_SCHEMA_VERSION = "ui-evidence/v1"


@dataclass(frozen=True)
class LocalTarget:
    origin: str
    host: str
    port: int
    owner_id: str
    command: str = ""
    ready: bool = False

    def validate(self) -> None:
        if not self.origin.startswith(("http://", "https://")):
            raise ScreenshotPolicyError("local target must use HTTP(S)")
        if self.host not in {"localhost", "127.0.0.1", "::1"}:
            raise ScreenshotPolicyError("local target must use a loopback host")
        if not 1 <= self.port <= 65535:
            raise ScreenshotPolicyError("local target port is invalid")
        if not self.owner_id.strip():
            raise ScreenshotPolicyError("local target requires an owner id")

    def capture_target(self) -> str:
        self.validate()
        return validate_screenshot_target(self.origin, allowed_hosts={self.host})


@dataclass(frozen=True)
class InteractionState:
    id: str
    preconditions: tuple[str, ...]
    actions: tuple[str, ...]
    expected: tuple[str, ...]
    viewports: tuple[str, ...] = ()
    required: bool = True

    def as_dict(self) -> dict[str, Any]:
        value = asdict(self)
        for key in ("preconditions", "actions", "expected", "viewports"):
            value[key] = list(value[key])
        return value


@dataclass
class RenderRecord:
    viewport: str
    state_id: str
    target: str
    width: int
    height: int
    screenshot_path: str
    checksum: str
    renderer: str
    artifact_revision: str
    evidence_generation: str
    run_id: str
    workspace: str

    def validate(self) -> None:
        if not self.viewport or not self.state_id or not self.target:
            raise ValueError("render record requires viewport, state, and target")
        if self.width <= 0 or self.height <= 0:
            raise ValueError("render dimensions must be positive")
        for name in ("checksum", "renderer", "artifact_revision", "evidence_generation", "run_id", "workspace"):
            if not str(getattr(self, name)).strip():
                raise ValueError(f"render record requires {name}")


@dataclass
class RenderManifest:
    version: str
    mode: str
    adapter: str
    capability_attested: bool
    run_id: str
    workspace: str
    contract_digest: str
    artifact_revision: str
    evidence_generation: str
    renders: list[RenderRecord] = field(default_factory=list)

    def validate(self) -> None:
        if self.version != EVIDENCE_SCHEMA_VERSION:
            raise ValueError("unsupported UI evidence version")
        if self.mode not in {"test_fake", "live_real", "unavailable"}:
            raise ValueError("evidence mode must be test_fake, live_real, or unavailable")
        if self.mode == "live_real" and not self.capability_attested:
            raise ValueError("live evidence requires an attested capability")
        for name in ("run_id", "workspace", "contract_digest", "artifact_revision", "evidence_generation"):
            if not str(getattr(self, name)).strip():
                raise ValueError(f"render manifest requires {name}")
        for render in self.renders:
            render.validate()

    @property
    def live_eligible(self) -> bool:
        return self.mode == "live_real" and self.capability_attested

    def as_dict(self) -> dict[str, Any]:
        return {
            "version": self.version,
            "mode": self.mode,
            "adapter": self.adapter,
            "capability_attested": self.capability_attested,
            "run_id": self.run_id,
            "workspace": self.workspace,
            "contract_digest": self.contract_digest,
            "artifact_revision": self.artifact_revision,
            "evidence_generation": self.evidence_generation,
            "renders": [asdict(render) for render in self.renders],
            "live_eligible": self.live_eligible,
        }


@dataclass
class InteractionReport:
    mode: str
    run_id: str
    artifact_revision: str
    evidence_generation: str
    results: list[dict[str, Any]] = field(default_factory=list)
    unavailable_reason: str = ""

    def validate(self) -> None:
        if self.mode not in {"test_fake", "live_real", "unavailable"}:
            raise ValueError("interaction report mode is invalid")
        if self.mode == "live_real" and not self.results:
            raise ValueError("live interaction report requires results")

    def as_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class AccessibilityReport:
    mode: str
    run_id: str
    artifact_revision: str
    evidence_generation: str
    results: list[dict[str, Any]] = field(default_factory=list)
    unavailable_reason: str = ""

    def validate(self) -> None:
        if self.mode not in {"test_fake", "live_real", "unavailable"}:
            raise ValueError("accessibility report mode is invalid")
        if self.mode == "live_real" and not self.results:
            raise ValueError("live accessibility report requires results")

    def as_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class UiEvidenceResult:
    manifest: RenderManifest
    interaction: InteractionReport
    accessibility: AccessibilityReport
    errors: list[str] = field(default_factory=list)

    @property
    def live_eligible(self) -> bool:
        return not self.errors and self.manifest.live_eligible and self.interaction.mode == "live_real" and self.accessibility.mode == "live_real"

    def validate(self) -> None:
        self.manifest.validate()
        self.interaction.validate()
        self.accessibility.validate()
        if not self.errors and not self.manifest.renders:
            raise ValueError("UI evidence requires at least one render")
        if self.manifest.run_id != self.interaction.run_id or self.manifest.run_id != self.accessibility.run_id:
            raise ValueError("UI evidence reports must belong to one run")
        if self.manifest.artifact_revision != self.interaction.artifact_revision or self.manifest.artifact_revision != self.accessibility.artifact_revision:
            raise ValueError("UI evidence reports must bind one artifact revision")
        if self.manifest.evidence_generation != self.interaction.evidence_generation or self.manifest.evidence_generation != self.accessibility.evidence_generation:
            raise ValueError("UI evidence reports must bind one evidence generation")

    def digest(self) -> str:
        payload = json.dumps({"manifest": self.manifest.as_dict(), "interaction": self.interaction.as_dict(), "accessibility": self.accessibility.as_dict()}, sort_keys=True, separators=(",", ":"))
        return hashlib.sha256(payload.encode("utf-8")).hexdigest()

    def as_dict(self) -> dict[str, Any]:
        return {
            "manifest": self.manifest.as_dict(),
            "interaction": self.interaction.as_dict(),
            "accessibility": self.accessibility.as_dict(),
            "errors": list(self.errors),
        }

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> "UiEvidenceResult":
        if not isinstance(value, dict):
            raise ValueError("UI evidence must be an object")
        manifest_value = value.get("manifest")
        if not isinstance(manifest_value, dict):
            raise ValueError("UI evidence manifest must be an object")
        render_values = manifest_value.get("renders", [])
        if not isinstance(render_values, list) or any(not isinstance(item, dict) for item in render_values):
            raise ValueError("UI evidence renders must be a list of objects")
        interaction_value = value.get("interaction", {})
        accessibility_value = value.get("accessibility", {})
        if not isinstance(interaction_value, dict) or not isinstance(accessibility_value, dict):
            raise ValueError("UI evidence reports must be objects")
        result = cls(
            manifest=RenderManifest(
                version=str(manifest_value.get("version", "")),
                mode=str(manifest_value.get("mode", "")),
                adapter=str(manifest_value.get("adapter", "")),
                capability_attested=bool(manifest_value.get("capability_attested", False)),
                run_id=str(manifest_value.get("run_id", "")),
                workspace=str(manifest_value.get("workspace", "")),
                contract_digest=str(manifest_value.get("contract_digest", "")),
                artifact_revision=str(manifest_value.get("artifact_revision", "")),
                evidence_generation=str(manifest_value.get("evidence_generation", "")),
                renders=[RenderRecord(**item) for item in render_values],
            ),
            interaction=InteractionReport(
                mode=str(interaction_value.get("mode", "")),
                run_id=str(interaction_value.get("run_id", "")),
                artifact_revision=str(interaction_value.get("artifact_revision", "")),
                evidence_generation=str(interaction_value.get("evidence_generation", "")),
                results=list(interaction_value.get("results", [])),
                unavailable_reason=str(interaction_value.get("unavailable_reason", "")),
            ),
            accessibility=AccessibilityReport(
                mode=str(accessibility_value.get("mode", "")),
                run_id=str(accessibility_value.get("run_id", "")),
                artifact_revision=str(accessibility_value.get("artifact_revision", "")),
                evidence_generation=str(accessibility_value.get("evidence_generation", "")),
                results=list(accessibility_value.get("results", [])),
                unavailable_reason=str(accessibility_value.get("unavailable_reason", "")),
            ),
            errors=list(value.get("errors", [])),
        )
        result.validate()
        return result


class BrowserAdapter(Protocol):
    mode: str
    adapter: str
    capability_attested: bool

    def capture(self, *, run_id: str, workspace: str, target: LocalTarget, contract_digest: str, viewports: list[str], states: list[InteractionState], artifact_revision: str, evidence_generation: str) -> UiEvidenceResult: ...
