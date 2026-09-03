---
name: treehouse
description: >
  Manage reusable, isolated git worktrees for parallel AI coding agents.
  Use when running multiple agents on the same repository, isolating experimental features,
  inspecting worktree pool status, or pruning stale worktrees.
---

# Treehouse Git Worktree Manager

[Treehouse](https://github.com/kunchenguid/treehouse) manages a pool of reusable, isolated git worktrees so that multiple AI coding agents can work on the same repository simultaneously without collisions or reinstalling dependencies.

## Why Treehouse is Critical for Agentic Workflows

| Problem Without Treehouse | How Treehouse Solves It |
| :--- | :--- |
| **Branch Collisions**: Two agents trying to edit the same git workspace break each other's edits. | Each agent works in an independent git worktree on its own branch. |
| **Dependency Re-install Overhead**: Normal `git worktree` wipes `node_modules` or `.venv`, taking 5 minutes per agent run. | Treehouse preserves pools of worktrees with dependencies and build caches intact. |
| **Lingering Zombie Processes**: Background test runners or dev servers lock files after an agent exits. | `treehouse return` automatically terminates lingering child processes. |

---

## Command Reference

### 1. Acquire a Worktree (Instant Subshell)
Run inside any git repository to enter an isolated worktree:
```bash
treehouse
# Drops you into: ~/.treehouse/<repo-hash>/1/<repo-name>
# Type 'exit' to return it to the pool
```

### 2. Inspect Worktree Pool Status
See all active and idle worktrees across projects:
```bash
treehouse status
```

### 3. Clean & Prune Worktrees
Safely remove stale worktrees that are no longer in use:
```bash
treehouse prune
```

### 4. Integration with Firstmate & Herdr
- **Firstmate**: Calls `treehouse` internally whenever a `ship` or `scout` task is spawned via `bin/fm-spawn.sh`.
- **Herdr**: Each Treehouse worktree is assigned to a distinct Herdr tab or workspace (`fm-<id>`).
- **Safe Merging**: Once the task in the worktree is complete, Firstmate verifies the diff with `no-mistakes` before merging back into main.
