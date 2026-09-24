"""Load and normalize the shared harness catalog."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

CATALOG_PATH = Path(__file__).resolve().parents[1] / "config" / "harnesses.json"
_ICONS = {"agy": "󰲋", "opencode": "󰘳", "cline": "󰚩"}
_DISPLAY_NAMES = {"agy": "Antigravity CLI", "opencode": "OpenCode", "cline": "Cline"}
_FULL_NAMES = {"agy": "Antigravity CLI (Base Default)", "opencode": "OpenCode Engine", "cline": "Cline Autonomous Agent"}


class CatalogError(ValueError):
    """Raised when the shared harness catalog is malformed."""


def load_harness_catalog(path: Path = CATALOG_PATH) -> dict[str, dict[str, Any]]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise CatalogError(f"could not read harness catalog {path}: {exc}") from exc
    if not isinstance(payload, dict) or payload.get("schema_version") != 1:
        raise CatalogError("harness catalog must use schema_version 1")
    harnesses = payload.get("harnesses")
    if not isinstance(harnesses, list) or not harnesses:
        raise CatalogError("harness catalog must contain harnesses")
    result: dict[str, dict[str, Any]] = {}
    for item in harnesses:
        if not isinstance(item, dict):
            raise CatalogError("each harness must be an object")
        harness_id = item.get("id")
        models = item.get("models")
        default_model = item.get("default_model") or item.get("defaultModel")
        if not isinstance(harness_id, str) or harness_id in result:
            raise CatalogError("harness IDs must be unique non-empty strings")
        if not isinstance(models, list) or not models or default_model not in {model.get("id") for model in models if isinstance(model, dict)}:
            raise CatalogError(f"harness {harness_id} has no valid default model")
        result[harness_id] = {
            "name": str(item.get("name", harness_id)),
            "display_name": _DISPLAY_NAMES.get(harness_id, harness_id),
            "full_name": _FULL_NAMES.get(harness_id, str(item.get("full_name") or item.get("fullName") or item.get("name", harness_id))),
            "icon": str(item.get("icon") or _ICONS.get(harness_id, "")),
            "provider": harness_id,
            "default_model": default_model,
            "reasoning_level": str(item.get("reasoning_level", "standard")),
            "models": [
                {
                    "id": str(model["id"]),
                    "name": str(model.get("name", model["id"])),
                    "badge": str(model.get("badge", "")),
                    "free": bool(model.get("free", model.get("isFree", False))),
                }
                for model in models
                if isinstance(model, dict) and model.get("id")
            ],
        }
    return result
