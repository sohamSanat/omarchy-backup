"""Two-phase ownership receipts for external resources."""
from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Literal

from .identity import RunIdentity, identity_from_dict, validate_identity

ResourceState = Literal["intended", "created", "owned", "released", "failed"]


@dataclass
class ResourceReceipt:
    kind: str
    identifier: str
    state: ResourceState = "intended"

    def validate(self) -> None:
        if not self.kind or not self.identifier:
            raise ValueError("resource receipts require kind and identifier")
        if self.state not in {"intended", "created", "owned", "released", "failed"}:
            raise ValueError(f"unsupported resource state: {self.state}")


@dataclass
class RunManifest:
    identity: RunIdentity
    workspace: str | None = None
    workspace_owned: bool = False
    evidence_generation: str = ""
    artifact_revision: str = ""
    provider: str | None = None
    reviewer: dict[str, str] | None = None
    resources: list[ResourceReceipt] = field(default_factory=list)
    committed: bool = False

    def reserve(self, kind: str, identifier: str) -> ResourceReceipt:
        if self.committed:
            raise RuntimeError("cannot reserve resources after manifest commit")
        receipt = ResourceReceipt(kind, identifier)
        receipt.validate()
        self.resources.append(receipt)
        return receipt

    def mark_created(self, receipt: ResourceReceipt) -> None:
        if receipt not in self.resources:
            raise ValueError("resource is not part of this manifest")
        if receipt.state != "intended":
            raise RuntimeError(f"resource cannot transition from {receipt.state} to created")
        receipt.state = "created"

    def mark_failed(self, receipt: ResourceReceipt) -> None:
        if receipt not in self.resources:
            raise ValueError("resource is not part of this manifest")
        if receipt.state != "intended":
            raise RuntimeError(f"resource cannot transition from {receipt.state} to failed")
        receipt.state = "failed"

    def commit(self, receipt: ResourceReceipt | None = None) -> None:
        if receipt is not None:
            if receipt not in self.resources or receipt.state != "created":
                raise RuntimeError("only created resources can be committed")
            receipt.state = "owned"
            return
        for item in self.resources:
            if item.state == "intended":
                raise RuntimeError(f"resource {item.kind} has not been created")
            if item.state == "created":
                item.state = "owned"
        self.committed = True

    def owned_resources(self) -> list[ResourceReceipt]:
        return [item for item in self.resources if item.state == "owned"]

    def release_owned(self) -> list[ResourceReceipt]:
        released: list[ResourceReceipt] = []
        for item in self.owned_resources():
            item.state = "released"
            released.append(item)
        return released

    def compensation_targets(self) -> list[ResourceReceipt]:
        return [item for item in self.resources if item.state in {"intended", "created", "owned"}]

    def as_dict(self) -> dict:
        return asdict(self)

    @classmethod
    def from_dict(cls, value: dict) -> "RunManifest":
        identity_value = value.get("identity")
        if not isinstance(identity_value, dict):
            raise ValueError("manifest identity must be an object")
        for name in ("parent_run_id", "attempt_id", "provider_session_id"):
            if identity_value.get(name) is not None and not isinstance(identity_value.get(name), str):
                raise ValueError(f"manifest identity {name} must be a string")
        try:
            identity = identity_from_dict(identity_value)
        except (KeyError, TypeError) as exc:
            raise ValueError("manifest identity is incomplete") from exc
        identity_errors = validate_identity(identity)
        if identity_errors:
            raise ValueError("; ".join(identity_errors))
        resources_value = value.get("resources", [])
        if not isinstance(resources_value, list) or any(not isinstance(item, dict) for item in resources_value):
            raise ValueError("manifest resources must be a list of objects")
        reviewer = value.get("reviewer")
        if reviewer is not None and (
            not isinstance(reviewer, dict)
            or set(reviewer) != {"reviewer_id", "provider_session_id"}
            or any(not isinstance(item, str) or not item.strip() for item in reviewer.values())
        ):
            raise ValueError("manifest reviewer must contain reviewer_id and provider_session_id")
        resources = [ResourceReceipt(**item) for item in resources_value]
        committed = value.get("committed", False)
        if not isinstance(committed, bool):
            raise ValueError("manifest committed must be a boolean")
        if value.get("workspace") is not None and not isinstance(value.get("workspace"), str):
            raise ValueError("manifest workspace must be a string")
        workspace_owned = value.get("workspace_owned", False)
        if not isinstance(workspace_owned, bool):
            raise ValueError("manifest workspace_owned must be a boolean")
        if value.get("provider") is not None and not isinstance(value.get("provider"), str):
            raise ValueError("manifest provider must be a string")
        for name in ("evidence_generation", "artifact_revision"):
            if not isinstance(value.get(name, ""), str):
                raise ValueError(f"manifest {name} must be a string")
        if committed and any(item.state in {"intended", "created"} for item in resources):
            raise ValueError("committed manifest cannot contain unowned resources")
        manifest = cls(
            identity,
            workspace=value.get("workspace"),
            workspace_owned=workspace_owned,
            evidence_generation=value.get("evidence_generation", ""),
            artifact_revision=value.get("artifact_revision", ""),
            provider=value.get("provider"),
            reviewer=reviewer,
            resources=resources,
            committed=committed,
        )
        for resource in resources:
            resource.validate()
        return manifest


def manifest_has_ownership(manifest: dict | RunManifest) -> bool:
    value = manifest.as_dict() if isinstance(manifest, RunManifest) else manifest
    return any(resource.get("state") in {"intended", "created", "owned"} for resource in value.get("resources", []))
