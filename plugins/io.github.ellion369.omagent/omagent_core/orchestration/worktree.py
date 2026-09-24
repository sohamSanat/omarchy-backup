"""Git workspace discovery and worktree planning.

The planner is pure after repository discovery. It never initializes Git,
edits ignore files, or creates a worktree by itself.
"""
from __future__ import annotations

import re
import subprocess
from dataclasses import dataclass
from pathlib import Path


class WorkspaceError(RuntimeError):
    """Raised when coding work has no safe repository or workspace."""


@dataclass(frozen=True)
class RepositoryRoot:
    path: Path
    git_dir: Path


@dataclass(frozen=True)
class WorktreePlan:
    repository_root: str
    worktree_root: str
    branch: str
    base_ref: str = "HEAD"


def discover_repository(start: Path) -> RepositoryRoot:
    start = start.expanduser().resolve()
    if not start.exists():
        raise WorkspaceError(f"workspace does not exist: {start}")
    result = subprocess.run(
        ["git", "-C", str(start), "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=False,
        timeout=10,
    )
    if result.returncode != 0:
        raise WorkspaceError(f"not inside a Git repository: {start}")
    root = Path(result.stdout.strip()).resolve()
    git_dir_result = subprocess.run(
        ["git", "-C", str(root), "rev-parse", "--absolute-git-dir"],
        capture_output=True,
        text=True,
        check=False,
        timeout=10,
    )
    if git_dir_result.returncode != 0:
        raise WorkspaceError(f"could not resolve Git directory for {root}")
    return RepositoryRoot(root, Path(git_dir_result.stdout.strip()).resolve())


def safe_branch_name(request: str, run_id: str) -> str:
    slug = re.sub(r"[^a-zA-Z0-9._-]+", "-", request.strip().lower()).strip("-.") or "task"
    return f"omagent/{slug[:40]}-{run_id[:12]}"


def plan_worktree(start: Path, *, managed_root: Path, request: str, run_id: str) -> WorktreePlan:
    repository = discover_repository(start)
    if not managed_root.is_absolute():
        raise WorkspaceError("managed worktree root must be absolute")
    branch = safe_branch_name(request, run_id)
    worktree_root = managed_root / run_id
    return WorktreePlan(str(repository.path), str(worktree_root), branch)


def remove_managed_worktree(workspace: Path, *, runner=subprocess.run) -> None:
    """Remove only a Git worktree explicitly owned by a run.

    This deliberately does not delete a project directory or a branch. A
    failed Git operation remains visible to the controller for recovery.
    """
    workspace = workspace.expanduser().resolve()
    managed_root = (Path.home() / ".local" / "state" / "omagent" / "worktrees").resolve()
    try:
        workspace.relative_to(managed_root)
    except ValueError as exc:
        raise WorkspaceError("refusing to remove a worktree outside Omagent's managed root") from exc
    if not workspace.exists():
        return
    if not workspace.is_dir():
        raise WorkspaceError(f"managed worktree is not a directory: {workspace}")
    try:
        result = runner(
            ["git", "-C", str(workspace), "worktree", "remove", "--force", str(workspace)],
            capture_output=True,
            text=True,
            timeout=15,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        raise WorkspaceError(f"Git worktree cleanup failed: {exc}") from exc
    if result.returncode != 0:
        detail = result.stderr.strip()[:200] or "git worktree remove returned failure"
        raise WorkspaceError(f"Git worktree cleanup failed: {detail}")
