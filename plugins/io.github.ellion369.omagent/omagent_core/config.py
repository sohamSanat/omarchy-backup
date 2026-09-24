"""Validated configuration loading for the modular controller."""
from __future__ import annotations

import copy
import json
from pathlib import Path
from typing import Any

DEFAULT_CONFIG: dict[str, Any] = {
    "routes": {
        "default_mode": "regular",
        "coding_harness": "agy",
        "coding_model": "claude-opus-4-6-thinking",
    },
    "quality": {
        "repair_attempts": 2,
        "reviewer_required": True,
    },
    "quota": {
        "enabled": True,
        "trigger_usage_pct": 95,
        "unknown_policy": "trust-agy",
    },
    "runtime": {
        "state_dir": "~/.local/state/omagent",
        "controller_socket": "~/.local/state/omagent/controller.sock",
    },
}


class ConfigError(ValueError):
    """Raised when Omagent configuration cannot be trusted."""


def deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    result = copy.deepcopy(base)
    for key, value in override.items():
        if isinstance(result.get(key), dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = copy.deepcopy(value)
    return result


def load_config(path: Path, *, required: bool = False) -> dict[str, Any]:
    path = Path(path)
    if not path.is_file():
        if required:
            raise ConfigError(f"configuration file does not exist: {path}")
        return copy.deepcopy(DEFAULT_CONFIG)
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ConfigError(f"could not read configuration {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ConfigError("configuration root must be an object")
    config = deep_merge(DEFAULT_CONFIG, value)
    validate_config(config)
    return config


def validate_config(config: dict[str, Any]) -> None:
    quality = config.get("quality")
    if not isinstance(quality, dict):
        raise ConfigError("quality must be an object")
    attempts = quality.get("repair_attempts")
    if not isinstance(attempts, int) or attempts < 0:
        raise ConfigError("quality.repair_attempts must be a non-negative integer")
    routes = config.get("routes")
    if not isinstance(routes, dict):
        raise ConfigError("routes must be an object")
    if not isinstance(routes.get("default_mode"), str) or not routes["default_mode"]:
        raise ConfigError("routes.default_mode must be a non-empty string")
    runtime = config.get("runtime")
    if not isinstance(runtime, dict):
        raise ConfigError("runtime must be an object")
    for key in ("state_dir", "controller_socket"):
        if not isinstance(runtime.get(key), str) or not runtime[key]:
            raise ConfigError(f"runtime.{key} must be a non-empty string")
