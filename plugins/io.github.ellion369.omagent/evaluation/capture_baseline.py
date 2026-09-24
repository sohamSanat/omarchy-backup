#!/usr/bin/env python3
"""Capture a content-addressed snapshot of the current plugin tree.

The snapshot is intentionally metadata-only. It records relative paths and
SHA-256 digests so later migration work can prove that it did not silently
replace the pre-existing local rewrite.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

EXCLUDED_PARTS = {".git", "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache"}
EXCLUDED_NAMES = {".DS_Store"}


def iter_source_files(root: Path):
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        relative = path.relative_to(root)
        if any(part in EXCLUDED_PARTS for part in relative.parts):
            continue
        if path.name in EXCLUDED_NAMES:
            continue
        if relative.parts[:2] == ("evaluation", "baseline") and path.name == "current_tree.json":
            continue
        yield relative


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def capture(root: Path) -> dict:
    return {
        "schema_version": 1,
        "captured_at": datetime.now(timezone.utc).isoformat(),
        "root": ".",
        "files": [
            {"path": str(relative), "sha256": sha256(root / relative)}
            for relative in iter_source_files(root)
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path, default=None)
    args = parser.parse_args()
    root = args.root.resolve()
    output = args.output or root / "evaluation" / "baseline" / "current_tree.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(capture(root), indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
