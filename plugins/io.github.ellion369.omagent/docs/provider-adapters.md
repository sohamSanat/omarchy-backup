# Provider adapters

The supported coding providers are:

| Provider | Launch | Telemetry | Cancellation | Same-session resume | Same-workspace handoff |
|---|---:|---:|---:|---:|---:|
| AGY | yes | yes | yes | yes | yes |
| OpenCode | yes | yes | yes | yes | yes |
| Cline | yes | yes | yes | no | yes |

Kilo remains a research/model-pool source for historical reasons, but it is not a dispatch adapter. Routing rejects it rather than sending a command to a provider the router cannot monitor or own.

The shared catalog is `config/harnesses.json`. The router normalizes it for Python consumers; the QML overlay loads the same file. A provider must have an adapter, a health snapshot, and a model before it can be selected.

A routing decision is pure: it consumes requested provider/model, health, quota, catalog, and preference snapshots. Health probes and pool refreshes are separate operations and must use isolated temporary state. Selecting a provider never refreshes or rewrites the model pool; refresh and research are explicit maintenance commands. Live verification uses a bounded retry budget and only promotes a model after its probe passes.

A provider attempt is bound to a run, provider session, workspace, pane, and process group before monitoring or cleanup is allowed. Herdr's `agent start` response is the ownership boundary; the router accepts only explicit `provider_session_id` or `agent_session_id` fields. Follow-ups use the existing run and workspace. A tested fallback starts a new provider attempt in the same run; it does not silently create a second active worktree.

The router uses the Herdr and Firstmate adapters at setup, dispatch, and cleanup boundaries. A workspace receipt must include Herdr's opaque `workspace_id`, `tab_id`, and root pane identity; Firstmate metadata uses that tab identity rather than fabricating `:t1`. Missing workspace, pane, agent, or task receipts are setup failures. Worktree cleanup is limited to paths under Omagent's managed worktree root; it never removes an arbitrary project directory.

## Adding a provider

Before enabling a new provider by default:

1. Add its catalog entry and adapter.
2. Define launch, telemetry, cancellation, resume, and handoff capabilities.
3. Add sanitized parser fixtures and a fake integration test.
4. Verify that the provider cannot write outside its isolated health/probe area.
5. Run the held-out quality benchmark with the provider and without it.
6. Document its authentication, cost, and failure behavior.
