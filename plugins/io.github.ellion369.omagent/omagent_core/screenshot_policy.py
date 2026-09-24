"""Restrict screenshot targets to approved local run evidence."""
from __future__ import annotations

from pathlib import Path
from urllib.parse import urlparse


class ScreenshotPolicyError(ValueError):
    """Raised when a screenshot target is outside the approved boundary."""


def validate_screenshot_target(target: str, *, workspace: Path, allowed_hosts: set[str] | None = None) -> str:
    parsed = urlparse(target)
    if parsed.scheme in {"file", "data", "javascript"}:
        raise ScreenshotPolicyError("unsupported screenshot URL scheme")
    if parsed.scheme not in {"http", "https"}:
        raise ScreenshotPolicyError("screenshot target must be HTTP(S)")
    if allowed_hosts is not None and parsed.hostname not in allowed_hosts:
        raise ScreenshotPolicyError(f"screenshot host is not approved: {parsed.hostname}")
    if parsed.scheme in {"http", "https"}:
        return target
    raise ScreenshotPolicyError("unreachable screenshot target policy branch")


def validate_workspace_output(path: Path, *, workspace: Path) -> Path:
    workspace = workspace.resolve()
    candidate = path.expanduser().resolve()
    try:
        candidate.relative_to(workspace)
    except ValueError as exc:
        raise ScreenshotPolicyError("screenshot output must stay inside the run workspace") from exc
    return candidate
