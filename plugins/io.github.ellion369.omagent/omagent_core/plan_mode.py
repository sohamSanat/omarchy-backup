"""Side-effect-free planning contract.

Plan mode is a pure operation: it validates and describes work but never
opens a process, provider, Git repository, network connection, or store.
"""
from __future__ import annotations

from typing import Any


def build_plan(request: str, *, mode: str = "regular", workspace: str | None = None) -> dict[str, Any]:
    normalized = request.strip()
    if not normalized:
        raise ValueError("request must not be empty")
    return {
        "schema_version": 1,
        "kind": "plan",
        "mode": mode,
        "workspace": workspace,
        "request": normalized,
        "steps": [
            {"order": 1, "action": "confirm the task contract"},
            {"order": 2, "action": "select the quality profile and execution strategy"},
            {"order": 3, "action": "execute and collect evidence"},
            {"order": 4, "action": "verify, review, repair if needed, and report"},
        ],
        "side_effects": [],
    }
