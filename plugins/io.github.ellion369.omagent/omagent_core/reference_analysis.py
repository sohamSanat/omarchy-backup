"""Deterministic, run-scoped reference-image evidence.

Reference images are visual evidence only.  This module never treats OCR,
filenames, or the depicted subject as product instructions.
"""
from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

ANALYZER_VERSION = "reference-evidence/v1"


@dataclass(frozen=True)
class ReferenceEvidence:
    width: int | None
    height: int | None
    format: str | None
    aspect_ratio: float | None
    subject: str | None = None
    image_id: str = ""
    sha256: str = ""
    analyzer_version: str = ANALYZER_VERSION
    mode: str = "style-only"
    primary_reference_id: str = ""
    borrowable: tuple[str, ...] = field(default_factory=tuple)
    forbidden: tuple[str, ...] = field(default_factory=tuple)
    unavailable: bool = False

    @property
    def evidence_fingerprint(self) -> str:
        return self.sha256

    def as_dict(self) -> dict[str, Any]:
        return {
            "width": self.width,
            "height": self.height,
            "format": self.format,
            "aspect_ratio": self.aspect_ratio,
            "subject": self.subject,
            "image_id": self.image_id,
            "sha256": self.sha256,
            "evidence_fingerprint": self.evidence_fingerprint,
            "analyzer_version": self.analyzer_version,
            "mode": self.mode,
            "primary_reference_id": self.primary_reference_id or self.image_id,
            "borrowable": list(self.borrowable),
            "forbidden": list(self.forbidden),
            "unavailable": self.unavailable,
        }

    def as_contract_reference(self) -> dict[str, Any]:
        return self.as_dict()

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> "ReferenceEvidence":
        return cls(
            width=value.get("width"),
            height=value.get("height"),
            format=value.get("format"),
            aspect_ratio=value.get("aspect_ratio"),
            subject=value.get("subject"),
            image_id=str(value.get("image_id", "")),
            sha256=str(value.get("sha256", value.get("evidence_fingerprint", ""))),
            analyzer_version=str(value.get("analyzer_version", ANALYZER_VERSION)),
            mode=str(value.get("mode", "style-only")),
            primary_reference_id=str(value.get("primary_reference_id", "")),
            borrowable=tuple(str(item) for item in value.get("borrowable", ())),
            forbidden=tuple(str(item) for item in value.get("forbidden", ())),
            unavailable=bool(value.get("unavailable", False)),
        )


def fingerprint_reference(path: Path | str) -> str:
    digest = hashlib.sha256()
    path = Path(path)
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _default_policy() -> tuple[list[str], list[str]]:
    return (
        ["palette relationships", "contrast and tonal direction", "type personality", "spacing rhythm"],
        ["subject", "copy", "brand", "assets", "geometry", "composition"],
    )


def inspect_reference(
    path: Path | str,
    *,
    subject: str | None = None,
    image_id: str = "",
    mode: str = "style-only",
) -> ReferenceEvidence:
    path = Path(path)
    if not path.is_file():
        raise FileNotFoundError(path)
    image_id = image_id or path.name
    digest = fingerprint_reference(path)
    borrowable, forbidden = _default_policy()
    try:
        from PIL import Image  # type: ignore
    except ImportError:
        return ReferenceEvidence(
            None,
            None,
            path.suffix.lower().lstrip(".") or None,
            None,
            subject,
            image_id=image_id,
            sha256=digest,
            mode=mode,
            borrowable=tuple(borrowable),
            forbidden=tuple(forbidden),
        )
    try:
        with Image.open(path) as image:
            width, height = image.size
            return ReferenceEvidence(
                width,
                height,
                image.format,
                round(width / height, 4) if height else None,
                subject,
                image_id=image_id,
                sha256=digest,
                mode=mode,
                borrowable=tuple(borrowable),
                forbidden=tuple(forbidden),
            )
    except Exception:
        return ReferenceEvidence(
            None,
            None,
            path.suffix.lower().lstrip(".") or None,
            None,
            subject,
            image_id=image_id,
            sha256=digest,
            mode=mode,
            borrowable=tuple(borrowable),
            forbidden=tuple(forbidden),
            unavailable=True,
        )


def reference_cache_key(path: Path | str, *, analyzer_version: str = ANALYZER_VERSION) -> str:
    """Return a run-safe key; session IDs and mutable filenames are excluded."""
    path = Path(path)
    return f"{path.name}:{fingerprint_reference(path)}:{analyzer_version}"


def load_reference_evidence(path: Path | str) -> ReferenceEvidence:
    value = json.loads(Path(path).read_text("utf-8"))
    if not isinstance(value, dict):
        raise ValueError("reference evidence must be an object")
    return ReferenceEvidence.from_dict(value)


def save_reference_evidence(path: Path | str, evidence: ReferenceEvidence) -> None:
    Path(path).write_text(json.dumps(evidence.as_dict(), indent=2, sort_keys=True) + "\n", encoding="utf-8")
