"""Browser evidence adapters with a provider-free fake implementation."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from .ui_evidence import (
    EVIDENCE_SCHEMA_VERSION,
    AccessibilityReport,
    InteractionReport,
    InteractionState,
    LocalTarget,
    RenderManifest,
    RenderRecord,
    UiEvidenceResult,
)
from .screenshot_policy import validate_workspace_output


class FakeBrowserAdapter:
    """Deterministic fixture adapter. It is never live-completion eligible."""

    mode = "test_fake"
    adapter = "fake-browser/v1"
    capability_attested = False

    def capture(
        self,
        *,
        run_id: str,
        workspace: str,
        target: LocalTarget,
        contract_digest: str,
        viewports: list[str],
        states: list[InteractionState],
        artifact_revision: str,
        evidence_generation: str,
    ) -> UiEvidenceResult:
        workspace_path = Path(workspace).resolve()
        output_dir = workspace_path / ".omagent" / "ui-evidence" / evidence_generation
        output_dir.mkdir(parents=True, exist_ok=True)
        renders: list[RenderRecord] = []
        for viewport in viewports:
            applicable = [state for state in states if not state.viewports or viewport in state.viewports]
            for state in applicable or [InteractionState("initial", (), (), ("initial state renders",), (viewport,))]:
                filename = f"{viewport.replace(':', '-')}-{state.id}.json"
                output = validate_workspace_output(output_dir / filename, workspace=workspace_path)
                payload = {
                    "fixture": True,
                    "viewport": viewport,
                    "state": state.id,
                    "target": target.origin,
                    "contract_digest": contract_digest,
                }
                output.write_text(json.dumps(payload, sort_keys=True) + "\n", encoding="utf-8")
                renders.append(RenderRecord(
                    viewport=viewport,
                    state_id=state.id,
                    target=target.origin,
                    width=int(viewport.split(":")[1].split("x")[0]),
                    height=int(viewport.split(":")[1].split("x")[1]),
                    screenshot_path=str(output),
                    checksum=hashlib.sha256(output.read_bytes()).hexdigest(),
                    renderer=self.adapter,
                    artifact_revision=artifact_revision,
                    evidence_generation=evidence_generation,
                    run_id=run_id,
                    workspace=workspace,
                ))
        manifest = RenderManifest(
            version=EVIDENCE_SCHEMA_VERSION,
            mode=self.mode,
            adapter=self.adapter,
            capability_attested=self.capability_attested,
            run_id=run_id,
            workspace=workspace,
            contract_digest=contract_digest,
            artifact_revision=artifact_revision,
            evidence_generation=evidence_generation,
            renders=renders,
        )
        interaction = InteractionReport(
            mode=self.mode,
            run_id=run_id,
            artifact_revision=artifact_revision,
            evidence_generation=evidence_generation,
            results=[{"state": state.id, "status": "fixture-pass", "focus": "fixture-focus", "action": "fixture-action"} for state in states],
            unavailable_reason="test fixture adapter",
        )
        accessibility = AccessibilityReport(
            mode=self.mode,
            run_id=run_id,
            artifact_revision=artifact_revision,
            evidence_generation=evidence_generation,
            results=[{"check": "fixture-structure", "status": "pass"}, {"check": "fixture-focus", "status": "pass"}],
            unavailable_reason="test fixture adapter",
        )
        result = UiEvidenceResult(manifest=manifest, interaction=interaction, accessibility=accessibility)
        result.validate()
        return result


class UnavailableBrowserAdapter:
    mode = "unavailable"
    adapter = "unavailable-browser/v1"
    capability_attested = False

    def capture(self, **_: object) -> UiEvidenceResult:
        manifest = RenderManifest(
            version=EVIDENCE_SCHEMA_VERSION,
            mode=self.mode,
            adapter=self.adapter,
            capability_attested=False,
            run_id=str(_.get("run_id", "")),
            workspace=str(_.get("workspace", "")),
            contract_digest=str(_.get("contract_digest", "")),
            artifact_revision=str(_.get("artifact_revision", "")),
            evidence_generation=str(_.get("evidence_generation", "")),
        )
        interaction = InteractionReport(
            mode=self.mode,
            run_id=manifest.run_id,
            artifact_revision=manifest.artifact_revision,
            evidence_generation=manifest.evidence_generation,
            unavailable_reason="browser capability unavailable",
        )
        accessibility = AccessibilityReport(
            mode=self.mode,
            run_id=manifest.run_id,
            artifact_revision=manifest.artifact_revision,
            evidence_generation=manifest.evidence_generation,
            unavailable_reason="browser capability unavailable",
        )
        return UiEvidenceResult(manifest=manifest, interaction=interaction, accessibility=accessibility, errors=["browser capability unavailable"])
