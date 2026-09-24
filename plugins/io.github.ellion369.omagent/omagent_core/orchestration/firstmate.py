"""Firstmate task ownership adapter.

Firstmate's local metadata is treated as a run-owned resource. The adapter
keeps the file format compatible with the existing Firstmate CLI while making
validation, receipts, and cleanup explicit.
"""
from __future__ import annotations

import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Callable


class FirstmateError(RuntimeError):
    """Raised when a Firstmate task cannot be safely registered or removed."""


_TASK_ID = re.compile(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,127}")


@dataclass(frozen=True)
class FirstmateTaskReceipt:
    task_id: str
    pane_id: str
    workspace_id: str
    workspace: str
    metadata_path: str


class FirstmateAdapter:
    def __init__(self, state_dir: Path, *, runner: Callable[..., subprocess.CompletedProcess[str]] | None = None) -> None:
        self.state_dir = state_dir
        self._runner = runner or subprocess.run

    def send_task(self, task_id: str, message: str) -> None:
        self._validate_task_id(task_id)
        if not message.strip():
            raise FirstmateError("Firstmate task message must not be empty")
        try:
            result = self._runner(
                ["firstmate", "send", task_id, message],
                capture_output=True,
                text=True,
                timeout=8,
            )
        except (OSError, subprocess.SubprocessError) as exc:
            raise FirstmateError(f"Firstmate send failed for {task_id}: {exc}") from exc
        if result.returncode != 0:
            raise FirstmateError(
                f"Firstmate send failed for {task_id}: {result.stderr.strip()[:160]}"
            )

    def register_task(
        self,
        *,
        task_id: str,
        pane_id: str,
        workspace_id: str,
        tab_id: str,
        workspace: Path,
        harness: str = "agy",
        model: str = "",
        role: str = "crewmate",
        skill: str = "ce-work",
    ) -> FirstmateTaskReceipt:
        self._validate_task_id(task_id)
        if not pane_id or not workspace_id or not tab_id:
            raise FirstmateError("Firstmate task requires pane, tab, and workspace IDs")
        if self.state_dir.is_symlink():
            raise FirstmateError("Firstmate state directory must not be a symlink")
        self.state_dir.mkdir(parents=True, exist_ok=True)
        metadata_path = self.state_dir / f"{task_id}.meta"
        if metadata_path.is_symlink():
            raise FirstmateError("Firstmate task metadata path is a symlink")
        content = (
            "backend=herdr\n"
            f"endpoint_task_id={task_id}\n"
            "herdr_session=default\n"
            f"herdr_workspace_id={workspace_id}\n"
            f"herdr_tab_id={tab_id}\n"
            f"herdr_pane_id={pane_id}\n"
            f"window=default:{pane_id}\n"
            f"project={workspace}\n"
            f"worktree={workspace}\n"
            f"harness={harness}\n"
            f"model={model}\n"
            f"role={role}\n"
            f"skill={skill}\n"
            "kind=crewmate\n"
            "mode=local-only\n"
            "yolo=on\n"
        )
        metadata_path.write_text(content, encoding="utf-8")
        return FirstmateTaskReceipt(task_id, pane_id, workspace_id, str(workspace), str(metadata_path))

    def unregister_task(self, task_id: str) -> bool:
        self._validate_task_id(task_id)
        if not self.state_dir.is_dir():
            return True
        if self.state_dir.is_symlink():
            raise FirstmateError("Firstmate state directory must not be a symlink")
        metadata_path = self.state_dir / f"{task_id}.meta"
        status_path = self.state_dir / f"{task_id}.status"
        inbox_path = self.state_dir / f"{task_id}.inbox"
        try:
            if metadata_path.is_symlink() or metadata_path.exists():
                metadata_path.unlink()
            if status_path.is_symlink() or status_path.exists():
                status_path.unlink()
            if inbox_path.is_symlink():
                inbox_path.unlink()
            elif inbox_path.is_dir():
                shutil.rmtree(inbox_path)
            return True
        except OSError as exc:
            raise FirstmateError(f"could not remove Firstmate task {task_id}: {exc}") from exc

    @staticmethod
    def _validate_task_id(task_id: str) -> None:
        if not _TASK_ID.fullmatch(task_id or ""):
            raise FirstmateError("Firstmate task ID contains unsafe path characters")
