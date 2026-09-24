# Quality engine

Omagent uses one evidence-based quality lifecycle for direct, web, coding, and UI work.

## Lifecycle

1. **Understand** — normalize the request and create a task contract.
2. **Plan** — select a profile, workspace, provider policy, and verification plan.
3. **Execute** — run the requested work without changing the contract silently.
4. **Verify** — collect deterministic evidence for every required profile check.
5. **Review** — ask an independent reviewer to inspect the task contract and evidence.
6. **Repair** — retry failed gates with the same workspace and context.
7. **Deliver** — complete only when blocking checks and findings are resolved.

A quality run with an unresolved blocking gate is `incomplete`. A run waiting for user input or an unavailable reviewer is `blocked`. A run with no safe deliverable is `failed`. `completed` is never inferred from a router process exiting successfully.

## Independent review receipts

A reviewer is not accepted because it says the work is complete. A valid receipt must contain:

- a distinct `reviewer_id`;
- the reviewer `provider` and `provider_session_id`;
- the controller-issued `run_id`, `workspace`, `evidence_generation`, and current `artifact_revision` binding;
- `independent: true`;
- non-empty evidence; and
- findings with evidence and a blocking/resolved status.

UI receipts additionally require `review_scope: "ui"`, the selected concept id, and the current render-manifest, interaction-report, and accessibility-report digests. A generic receipt can never complete a UI run.

Coding and UI reviewers write the receipt under the run workspace at `.omagent/review-receipts/<run-id>.json`, using the adjacent `<run-id>.request.json` binding created by the controller. The router imports that run-scoped compatibility file into SQLite and accepts it only after binding the provider, implementer session, independent reviewer session, workspace, evidence generation, and artifact revision to the run manifest. Missing, malformed, non-independent, or identity-mismatched receipts block or incomplete the run; they never fall back to the implementer's completion claim.

Coding verification must be a controller-run, non-shell command. The router discovers common project test commands when none is configured, or uses `coding_verification_command` from config. UI work requires an explicit `ui_verification_command` that produces rendered evidence; absent rendered evidence remains incomplete.

## Profiles

- `direct`: instruction coverage, context use, clarity, and uncertainty.
- `web`: retrieval honesty, source quality, grounding, injection resistance, and failure behavior.
- `coding`: task contract, implementation, verification, and independent review.
- `ui`: subject fidelity, frozen design contract, reference boundary, reference fidelity, concept novelty, rendered evidence, interaction quality, accessibility, and independent visual review. UI work starts with three structurally distinct concepts; a selected concept is frozen before implementation. Reference images are fingerprinted, run-scoped evidence with separate borrowable and forbidden attributes. A style-only reference is the default; exact recreation is an explicit mode. UI render, interaction, and accessibility evidence must arrive as a typed, run-bound evidence payload. Provider prose and literal pass markers are not sufficient. Visual comparison is deterministic and provider-free; unavailable comparison, browser/accessibility capability, or render evidence blocks completion.

The default repair limit is two complete repair-and-reverification attempts. The limit is recorded in the run report.

Every UI run also records the Impeccable-led skill bundle. The implementation, component, motion, and reviewer roles receive the same bundle; the reviewer must use `visual-critique`, `accessibility-audit`, and `impeccable` against rendered evidence. A skill name in a provider prompt is not evidence that the skill ran. The run remains incomplete or blocked when the required rendered design review is absent.

## Offline benchmark

The fixtures under `evaluation/` and the runner at `evaluation/quality_runner.py` are deterministic and do not call providers. The live benchmark is intentionally separate from CI.

Use the runner with a result file shaped like:

```json
{
  "results": [
    {
      "task_id": "coding-001",
      "scores": {"task_contract": 4, "implementation": 4, "verification": 4, "review": 4},
      "evidence": ["command output", "review receipt"],
      "terminal_state": "completed"
    }
  ]
}
```

The current offline test suite must remain network-free.
