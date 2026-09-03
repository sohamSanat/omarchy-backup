---
name: multi-agent-orchestrator
description: >
  Orchestrating multi-agent collaboration, delegation pipelines, and parallel agent workflows
  using Herdr workspaces, panes, and socket controls. Use when creating agent teams
  (Architect, Coder, Reviewer, QA), dispatching tasks between agents, monitoring agent status,
  and handling agent handoffs and approvals.
---

# Multi-Agent Orchestration with Herdr

Herdr is the premier terminal workspace manager designed specifically for orchestrating multiple AI agents in parallel. This skill details patterns for configuring, running, and synchronizing multi-agent workflows inside Herdr.

## When to Use This Skill
- Orchestrating multi-role agent pipelines (e.g., Lead Architect $\to$ Implementer $\to$ Test Suite $\to$ Code Reviewer).
- Programmatically launching agents across Herdr panes using `herdr agent start`.
- Passing structured work artifacts and tasks between agents via `herdr agent prompt`.
- Monitoring agent lifecycle states (`idle`, `working`, `blocked`, `done`) and waiting for completion.
- Managing approvals and human-in-the-loop interventions when an agent enters `blocked` state.
- Isolating branch workflows using Git worktrees with `herdr worktree`.

---

## The Herdr Multi-Agent Topology

A standard multi-agent development environment in Herdr uses a dedicated workspace with organized panes:

```
+-------------------------------------------------------------+
| Herdr Workspace: "Feature-Development"                      |
| Tab 1: [w1:t1]                                              |
+------------------------------+------------------------------+
| Pane 1 [w1:p1]               | Pane 2 [w1:p2]               |
| Agent: "architect" (Claude)  | Agent: "coder" (Codex/OpenCode)
| - Analyzes spec & creates    | - Writes code implementation |
|   architecture markdown      |   following design doc       |
| Status: [DONE]               | Status: [WORKING]            |
+------------------------------+------------------------------+
| Pane 3 [w1:p3]               | Pane 4 [w1:p4]               |
| Agent: "tester" (Bash/pytest)| Agent: "reviewer" (Antigravity)|
| - Executes automated tests   | - Performs security & lint   |
|   and benchmarks             |   review                     |
| Status: [IDLE]               | Status: [IDLE]               |
+------------------------------+------------------------------+
```

---

## Step-by-Step Orchestration Recipe

### 1. Create a Sibling Pane in Herdr
Inspect the current pane and split horizontally or vertically without stealing focus from the user:
```bash
# Split to the right preserving the current working directory
herdr pane split --current --direction right --cwd "$PWD" --no-focus
```
*Note: Extract the new pane ID (e.g. `w1:p2`) from the JSON output.*

### 2. Spawn a Specialized Agent
Launch the appropriate agent kind (`claude`, `codex`, `opencode`, `gemini`, `agy`) inside the new pane:
```bash
# Launch a reviewer agent
herdr agent start code-reviewer --kind codex --pane "w1:p2"
```

### 3. Dispatch a Work Order
Send instructions to the agent with `--wait` to monitor progress until it settles (`idle`, `done`, or `blocked`):
```bash
herdr agent prompt code-reviewer \
  "Review the unstaged changes in src/agent/state.py. Check for edge cases, error handling, and type safety." \
  --wait --timeout 180000
```

### 4. Inspect State & Read Results
Check the status and retrieve the agent's recent output:
```bash
# Check status (idle, working, blocked, done)
herdr agent get code-reviewer

# Read complete unwrapped output
herdr agent read code-reviewer --source recent-unwrapped --lines 80
```

### 5. Handle Human Approvals (`blocked`)
If an agent enters `blocked` state (e.g., asking permission to edit files or run tests):
```bash
# View the prompt the agent is stuck on
herdr agent read code-reviewer --source visible --lines 20

# Send interactive approval key (e.g. Enter or 'y')
herdr agent send-keys code-reviewer y enter
```

---

## Safe Coordination Principles

1. **Explicit Identification**: Always reference agents by their explicit unique names (`code-reviewer`, `test-runner`) or opaque pane IDs (`w1:p2`), never by fuzzy matching or tab indices.
2. **Handoff via Shared Storage**:
   - For complex handoffs, have the upstream agent write a structured artifact (e.g. `/tmp/spec-v1.md` or a Git commit).
   - Pass the file path in the prompt to the downstream agent. Avoid dumping 1,000 lines of raw text across the socket.
3. **Prevent Cascading Loops**:
   - Limit inter-agent feedback loops (e.g., Coder $\leftrightarrow$ Reviewer) to a maximum of 3 iterations.
   - If convergence is not achieved in 3 rounds, flag as `blocked` for human steering.
