# Operations

## State

The authoritative session and run store is:

```text
~/.local/state/omagent/controller.sqlite
```

QML sends session snapshots through `omagent-route --import-session-file`. The router stores the snapshot in SQLite and writes only compatibility projections for the existing overlay. SQLite is the source of truth; JSON files are recovery and compatibility data.

Each owned coding run also has a run manifest in SQLite. It records the workspace, Herdr workspace, panes, Firstmate tasks, provider session, and their ownership state. New workspace, pane, and task receipts are persisted before the next external side effect. Stop and delete commands use this manifest; legacy fleet JSON is imported only as a compatibility input. An active or detached run cannot be deleted, and late evidence is stored without changing a terminal state.

Agentic coding uses adaptive execution sizing. Small local edits use the `needle` path: one provider, no subagents, at most eight tool calls, and a ten-minute execution budget, followed by focused deterministic verification. Moderate work uses `standard`; architecture, security, migration, reliability, and release-scale work uses the full `sword` fleet with independent review. UI work never uses the `needle` shortcut because rendered design review is required.

UI concept cards, the selected concept, reference evidence, frozen design contract, and the authoritative `UiRunContext` are recorded as run events. The legacy Grill-Me JSON file is only a compatibility projection. A reference cache is valid only for the same content fingerprint and analyzer version; changing an image or analyzer invalidates the old evidence. UI render, interaction, and accessibility evidence is a typed run-owned payload bound to the current artifact revision and evidence generation. Provider text markers are not evidence. A fake adapter is allowed in deterministic tests but cannot complete a live run. Rendered evidence is compared locally against the contract and recorded comparison population. If Pillow, the browser/accessibility adapter, or another required local comparison capability is unavailable, the run is blocked or incomplete rather than treated as novel.

Herdr setup is fail-closed: `workspace create`, pane splits, and agent starts must return explicit identities. Firstmate metadata is scoped to validated task IDs and its local task files are treated as run-owned resources. A provider session is recorded only when Herdr returns an explicit provider/agent session field; a missing identity leaves independent review blocked rather than being inferred from a pane or terminal session ID.

A valid reviewer receipt is first read from `.omagent/review-receipts/<run-id>.json`, then imported into the controller-owned SQLite receipt channel. The controller binds it to the run's provider and independent reviewer session before the quality engine can use it. Receipt files are compatibility input, not the authority.

The overlay uses a bounded handoff directory:

```text
~/.local/state/omagent/handoff/
```

A handoff file is accepted only inside that directory and is removed after import.

## Lifecycle recovery

- `planned`: accepted, but not started.
- `starting` / `working`: provider execution is active.
- `verifying` / `reviewing`: evidence and independent review are in progress.
- `awaiting_user`: the run needs a response before continuing.
- `blocked`: user, reviewer, or system input is required.
- `detached`: the run can be reattached to its recorded provider identity.
- `cancelled`: the owned provider and workspace were cleaned up.
- `incomplete`: a deliverable exists, but a blocking quality gate remains.
- `failed`: no safe deliverable exists.
- `completed`: all required gates and review findings passed.

A legacy `done` record is a router acknowledgement, not proof that a task completed. Legacy active records without an ownership receipt require manual recovery before automatic reattachment.

## Plan mode

`omagent-route --plan "request"` and `OMAGENT_DRY_RUN=1` planning output a plan only. They do not launch a provider, call a network service, create a Git worktree, or write controller state.

## Credentials

Do not put provider credentials in normal Omagent session files, prompts, events, or logs. Prefer environment variables or an external secret source. If a legacy config contains a credential, rotate it and remove it after migration.

## Validation

Run the deterministic suite with:

```sh
python3 -m unittest discover -s tests -p 'test_*.py'
python3 -m compileall -q omagent_core evaluation tests
```

Provider calls, Herdr, Firstmate, and live model benchmarks are separate manual checks. They must not be used as CI substitutes.
