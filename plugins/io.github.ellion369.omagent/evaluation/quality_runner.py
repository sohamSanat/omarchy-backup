#!/usr/bin/env python3
"""Validate and score deterministic quality-benchmark result fixtures.

The runner is intentionally offline. It does not call a model or a provider.
A later live benchmark can produce the same result shape and feed it to the
same threshold gate.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from omagent_core.ui_evidence import UiEvidenceResult


def _has_live_ui_evidence(evidence: list) -> bool:
    for item in evidence:
        value = None
        if isinstance(item, dict) and item.get("kind") == "ui_evidence":
            value = item.get("payload")
        elif isinstance(item, str) and item.startswith("ui_evidence:"):
            try:
                value = json.loads(item[len("ui_evidence:"):])
            except json.JSONDecodeError:
                continue
        if not isinstance(value, dict):
            continue
        try:
            if UiEvidenceResult.from_dict(value).live_eligible:
                return True
        except (TypeError, ValueError):
            continue
    return False


def load(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def score_result(task: dict, result: dict, *, profile: str = "") -> list[str]:
    errors: list[str] = []
    if result.get("task_id") != task["id"]:
        errors.append("task_id does not match the task")
    scores = result.get("scores")
    if not isinstance(scores, dict):
        return errors + ["scores must be an object"]
    for criterion in task["rubric"]:
        value = scores.get(criterion)
        if not isinstance(value, int) or not 0 <= value <= 4:
            errors.append(f"score for {criterion} must be an integer from 0 to 4")
    if not isinstance(result.get("evidence"), list):
        errors.append("evidence must be an array")
    if profile == "ui" and result.get("terminal_state") == "completed":
        evidence = result.get("evidence")
        if not _has_live_ui_evidence(evidence or []):
            errors.append("completed UI results require live typed ui_evidence")
    if result.get("terminal_state") not in {"completed", "incomplete", "failed", "blocked"}:
        errors.append("terminal_state is not a supported quality outcome")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tasks", type=Path, required=True)
    parser.add_argument("--results", type=Path, required=True)
    args = parser.parse_args()
    task_manifest = load(args.tasks)
    tasks = task_manifest.get("tasks", [])
    profile = str(task_manifest.get("profile", ""))
    results = load(args.results).get("results", [])
    by_id = {item.get("task_id"): item for item in results if isinstance(item, dict)}
    errors: list[str] = []
    for task in tasks:
        result = by_id.get(task["id"])
        if result is None:
            errors.append(f"missing result for {task['id']}")
            continue
        errors.extend(f"{task['id']}: {error}" for error in score_result(task, result, profile=profile))
    if errors:
        print(json.dumps({"ok": False, "errors": errors}, indent=2))
        return 1
    print(json.dumps({"ok": True, "task_count": len(tasks)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
