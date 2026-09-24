"""Herdr lifecycle adapter with explicit resource receipts."""
from __future__ import annotations

import json
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Any


class HerdrError(RuntimeError):
    """Raised when Herdr returns an invalid or incomplete ownership receipt."""


@dataclass(frozen=True)
class HerdrWorkspaceReceipt:
    workspace_id: str
    tab_id: str
    root_pane_id: str


@dataclass(frozen=True)
class HerdrPaneReceipt:
    pane_id: str


@dataclass(frozen=True)
class HerdrAgentReceipt:
    agent_id: str
    pane_id: str
    provider_session_id: str | None


Runner = Callable[..., subprocess.CompletedProcess[str]]


class HerdrAdapter:
    def __init__(self, runner: Runner | None = None, *, timeout: int = 5) -> None:
        self._runner = runner or subprocess.run
        self._timeout = timeout

    def create_workspace(self, *, label: str, cwd: Path) -> HerdrWorkspaceReceipt:
        data = self._run(["herdr", "workspace", "create", "--label", label, "--cwd", str(cwd)])
        result = _result(data)
        workspace = result.get("workspace")
        workspace_id = _first_string(workspace if isinstance(workspace, dict) else result, "workspace_id", "id")
        tab = result.get("tab")
        tab_id = _first_string(tab if isinstance(tab, dict) else {}, "tab_id", "id")
        root_pane_id = _first_string(result.get("root_pane", {}), "pane_id", "id")
        if not workspace_id or not tab_id or not root_pane_id:
            raise HerdrError("Herdr workspace response lacks workspace, tab, or root pane identity")
        return HerdrWorkspaceReceipt(workspace_id, tab_id, root_pane_id)

    def split_pane(self, pane_id: str, *, direction: str, cwd: Path) -> HerdrPaneReceipt:
        data = self._run([
            "herdr", "pane", "split", pane_id,
            "--direction", direction,
            "--no-focus",
            "--cwd", str(cwd),
        ])
        result = _result(data)
        child_pane_id = _first_string(result.get("pane", result), "pane_id", "id")
        if not child_pane_id:
            raise HerdrError("Herdr split response lacks child pane identity")
        return HerdrPaneReceipt(child_pane_id)

    def start_agent(
        self,
        name: str,
        *,
        kind: str,
        pane_id: str,
        extra_args: tuple[str, ...] = (),
        require_provider_session: bool = False,
    ) -> HerdrAgentReceipt:
        command = ["herdr", "agent", "start", name, "--kind", kind, "--pane", pane_id, "--timeout", "15000", "--", *extra_args]
        data = self._run(command, timeout=20)
        result = _result(data)
        agent = result.get("agent", result)
        agent_id = _first_string(agent, "agent_id", "id") or name
        provider_session_id = _first_string(agent, "provider_session_id", "agent_session_id")
        if require_provider_session and not provider_session_id:
            raise HerdrError("Herdr agent receipt lacks an explicit provider session identity")
        return HerdrAgentReceipt(agent_id, pane_id, provider_session_id)

    def pane_info(self, pane_id: str) -> dict[str, Any]:
        data = self._run(["herdr", "pane", "get", pane_id])
        return _result(data)

    def provider_session_id(self, pane_id: str) -> str | None:
        value = self.pane_info(pane_id)
        return _find_provider_session(value)

    def close_pane(self, pane_id: str) -> None:
        result = self._run(["herdr", "pane", "close", pane_id], timeout=5, allow_nonzero=True)
        if result.returncode != 0 and not _missing_resource(f"{result.stderr}\n{result.stdout}"):
            raise HerdrError(f"Herdr pane close failed for {pane_id}: {result.stderr.strip()[:160]}")

    def close_workspace(self, workspace_id: str) -> None:
        result = self._run(["herdr", "workspace", "close", workspace_id], timeout=5, allow_nonzero=True)
        if result.returncode != 0 and not _missing_resource(f"{result.stderr}\n{result.stdout}"):
            raise HerdrError(
                f"Herdr workspace close failed for {workspace_id}: {result.stderr.strip()[:160]}"
            )

    def close_workspace_by_label(self, label: str) -> None:
        data = self._run(["herdr", "workspace", "list"])
        result = _result(data)
        workspaces = result.get("workspaces")
        if not isinstance(workspaces, list):
            workspaces = result.get("items") if isinstance(result.get("items"), list) else []
        for workspace in workspaces:
            if not isinstance(workspace, dict) or workspace.get("label") != label:
                continue
            workspace_id = _first_string(workspace, "workspace_id", "id")
            if workspace_id:
                self.close_workspace(workspace_id)

    def send_text(self, pane_id: str, text: str) -> None:
        result = self._run(["herdr", "pane", "send-text", pane_id, text])
        if result.returncode != 0:
            raise HerdrError(f"Herdr send-text failed for {pane_id}: {result.stderr.strip()[:160]}")

    def _run(
        self,
        command: list[str],
        *,
        timeout: int | None = None,
        allow_nonzero: bool = False,
    ) -> subprocess.CompletedProcess[str]:
        try:
            result = self._runner(
                command,
                capture_output=True,
                text=True,
                timeout=timeout or self._timeout,
            )
        except (OSError, subprocess.SubprocessError) as exc:
            raise HerdrError(f"Herdr command failed: {exc}") from exc
        if result.returncode != 0 and not allow_nonzero:
            raise HerdrError(f"Herdr command failed: {result.stderr.strip()[:160]}")
        return result


def _result(value: subprocess.CompletedProcess[str] | dict[str, Any]) -> dict[str, Any]:
    if isinstance(value, dict):
        data = value
    else:
        try:
            data = json.loads(value.stdout or "")
        except (TypeError, json.JSONDecodeError) as exc:
            raise HerdrError("Herdr returned invalid JSON") from exc
    if not isinstance(data, dict):
        raise HerdrError("Herdr response must be a JSON object")
    result = data.get("result")
    return result if isinstance(result, dict) else data


def _first_string(value: dict[str, Any], *keys: str) -> str:
    for key in keys:
        item = value.get(key)
        if isinstance(item, str) and item.strip():
            return item
    return ""


def _missing_resource(stderr: str) -> bool:
    detail = (stderr or "").lower()
    return any(token in detail for token in ("not found", "unknown pane", "unknown workspace", "no such pane", "no such workspace"))


def _find_provider_session(value: Any) -> str | None:
    if isinstance(value, dict):
        session_id = _first_string(value, "provider_session_id", "agent_session_id")
        if session_id:
            return session_id
        for item in value.values():
            found = _find_provider_session(item)
            if found:
                return found
    elif isinstance(value, list):
        for item in value:
            found = _find_provider_session(item)
            if found:
                return found
    return None
