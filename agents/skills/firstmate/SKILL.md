---
name: firstmate
description: >
  Operate and coordinate with Firstmate, an agent fleet distro integrated with Herdr.
  Use when dispatching tasks to parallel agent crewmates, checking fleet status,
  inspecting crew progress, or supervising multi-agent projects using Herdr workspaces
  and Treehouse git worktrees.
---

# Firstmate + Herdr Integration

[Firstmate](https://github.com/kunchenguid/firstmate) is an **agent distro** for orchestrating a crew of autonomous coding agents. Instead of manually juggling multiple terminals, you interact with a single liaison agent (the **First Mate**), which dispatches and supervises autonomous crewmates across git worktrees and visible terminal backends.

On this system, Firstmate is fully integrated with **Herdr** as its native runtime session provider and **Treehouse** as its worktree provider.

---

## System Architecture

```
+-------------------------------------------------------------+
|                      Captain (User / You)                   |
+-------------------------------------------------------------+
                              |
+-------------------------------------------------------------+
|              First Mate Liaison (Herdr Workspace)           |
|  - Manages task intake, briefs, and dispatch                |
|  - Supervises fleet state and escalates blockers            |
|  - Path: /home/soham/firstmate                              |
+-------------------------------------------------------------+
                              |
       +----------------------+----------------------+
       |                      |                      |
+---------------+      +---------------+      +---------------+
| Task: fm-001  |      | Task: fm-002  |      | Task: fm-003  |
| Herdr Tab     |      | Herdr Tab     |      | Herdr Tab     |
| Treehouse WT  |      | Treehouse WT  |      | Treehouse WT  |
| Agent: Claude |      | Agent: Codex  |      | Agent: OpenCode|
| State: [DONE] |      | State: [WORK] |      | State: [IDLE] |
+---------------+      +---------------+      +---------------+
```

---

## Configuration & Environment

- **Repository Root**: `/home/soham/firstmate`
- **Configured Backend**: `herdr` (stored in `/home/soham/firstmate/config/backend`)
- **Git Worktree Provider**: `treehouse` (`/home/soham/.local/bin/treehouse`)
- **CLI Wrapper**: `firstmate` and `fm` in `~/.local/bin`

---

## Operational Commands

### 1. View Fleet Status
Check active crewmates, queued backlog tasks, and completed outcomes:
```bash
firstmate fleet
# or shorthand:
fm fleet
```

### 2. Launch Firstmate in Herdr
Start an interactive Firstmate session inside Herdr using your preferred agent harness (`claude`, `codex`, `opencode`, or `agy`):
```bash
firstmate launch claude
# or codex:
firstmate launch codex
```

### 3. Peek at Crewmate Output
Inspect recent terminal output from an active crewmate without switching tabs or stealing focus:
```bash
firstmate peek <task-id>
```

### 4. Steer or Message a Crewmate
Send an instruction or human feedback directly to an ongoing task:
```bash
firstmate send <task-id> "Run pytest on tests/test_auth.py and fix any failures."
```

### 5. Fleet Synchronization & Branch Pruning
Synchronize project repos and prune merged feature branches safely:
```bash
firstmate sync
```

### 6. Environment Health Check
Run the bootstrap diagnostics script to verify dependencies and hooks:
```bash
firstmate bootstrap
```

---

## How Agents Collaborate with Firstmate

When an agent running in Herdr needs to delegate a parallel task:
1. **Submit a task**: Put work items into Firstmate's backlog (`data/backlog.md`) or prompt the First Mate agent.
2. **Firstmate executes**: Firstmate uses `bin/fm-spawn.sh` to create a dedicated Treehouse worktree and a new Herdr task tab (`fm-<id>`).
3. **Monitor via Herdr**: Herdr's semantic detection tracks when the crewmate finishes (`done`) or requires input (`blocked`).
4. **Handoff**: Once the task is approved and merged, Firstmate tears down the disposable worktree and updates the fleet board.
