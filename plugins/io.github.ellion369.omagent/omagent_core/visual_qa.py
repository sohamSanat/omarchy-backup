"""Deterministic, provider-free visual evidence for UI quality gates.

The comparator intentionally separates permitted reference fidelity from
reference-boundary compliance and novelty.  A visual hash is useful for
near-duplicate detection; it is not a semantic understanding of a screenshot.
"""
from __future__ import annotations

import json
import math
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Iterable

from .ui_brief import ConceptCandidate, _axis_differences

PROFILE_VERSION = "visual-qa/v1"


@dataclass(frozen=True)
class VisualQAProfile:
    version: str = PROFILE_VERSION
    max_hash_distance: int = 6
    max_pixel_rmse: float = 0.18
    min_concept_axis_distance: int = 3
    recent_run_limit: int = 20

    def as_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True)
class ImageSignature:
    path: str
    width: int
    height: int
    digest: str
    dhash: str
    average_luma: float

    def as_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class VisualQAResult:
    available: bool = True
    version: str = PROFILE_VERSION
    rendered: dict[str, Any] = field(default_factory=dict)
    reference: dict[str, Any] = field(default_factory=dict)
    novelty: dict[str, Any] = field(default_factory=dict)
    boundary: dict[str, Any] = field(default_factory=dict)
    concept: dict[str, Any] = field(default_factory=dict)
    errors: list[str] = field(default_factory=list)
    blocking: list[str] = field(default_factory=list)

    @property
    def passed(self) -> bool:
        return self.available and not self.blocking and not self.errors

    def as_dict(self) -> dict[str, Any]:
        return {
            "available": self.available,
            "version": self.version,
            "rendered": self.rendered,
            "reference": self.reference,
            "novelty": self.novelty,
            "boundary": self.boundary,
            "concept": self.concept,
            "errors": list(self.errors),
            "blocking": list(self.blocking),
            "passed": self.passed,
        }


def _require_pillow():
    try:
        from PIL import Image  # type: ignore
        return Image
    except ImportError:
        return None


def image_signature(path: Path | str) -> ImageSignature:
    Image = _require_pillow()
    path = Path(path)
    if Image is None:
        raise RuntimeError("Pillow is required for visual QA")
    if not path.is_file():
        raise FileNotFoundError(path)
    with Image.open(path) as image:
        image = image.convert("L")
        width, height = image.size
        pixels = list(image.resize((9, 8), Image.Resampling.LANCZOS).getdata())
        bits = []
        for row in range(8):
            left = pixels[row * 9 : row * 9 + 8]
            bits.extend("1" if left[col] > left[col + 1] else "0" for col in range(8))
        small = list(image.resize((32, 32), Image.Resampling.BILINEAR).getdata())
        average = sum(small) / max(1, len(small)) / 255.0
        import hashlib

        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        return ImageSignature(str(path), width, height, digest, "".join(bits), round(average, 6))


def _bits_to_int(bits: str) -> int:
    return int(bits, 2) if bits else 0


def hash_distance(left: ImageSignature, right: ImageSignature) -> int:
    return (_bits_to_int(left.dhash) ^ _bits_to_int(right.dhash)).bit_count()


def _sample_pixels(path: Path | str) -> list[float]:
    Image = _require_pillow()
    if Image is None:
        raise RuntimeError("Pillow is required for visual QA")
    with Image.open(path).convert("L") as image:
        return [value / 255.0 for value in image.resize((32, 32), Image.Resampling.BILINEAR).getdata()]


def pixel_rmse(left: Path | str, right: Path | str) -> float:
    left_values = _sample_pixels(left)
    right_values = _sample_pixels(right)
    if len(left_values) != len(right_values):
        return 1.0
    return round(math.sqrt(sum((a - b) ** 2 for a, b in zip(left_values, right_values)) / len(left_values)), 6)


def _concept_axis_distance(left: ConceptCandidate, right: ConceptCandidate) -> int:
    return _axis_differences(left, right)


def _boundary_result(subject: str, reference: dict[str, Any] | None) -> dict[str, Any]:
    if not reference:
        return {"required": False, "passed": True, "forbidden": [], "observed_subject": subject}
    forbidden = [str(item).lower() for item in reference.get("forbidden", ()) if str(item).strip()]
    # The deterministic check can only detect explicit product-subject collisions.
    # OCR/asset/composition checks remain independent visual-review evidence.
    collisions = [item for item in forbidden if len(item) > 3 and item in subject.lower()]
    return {
        "required": True,
        "passed": not collisions,
        "forbidden": forbidden,
        "observed_subject": subject,
        "collisions": collisions,
        "note": "This check does not infer image semantics; independent visual review is still required.",
    }


def evaluate_visual_evidence(
    rendered: Iterable[Path | str],
    *,
    reference: dict[str, Any] | None = None,
    concepts: Iterable[ConceptCandidate] = (),
    recent_runs: Iterable[dict[str, Any]] = (),
    product_family: str = "",
    profile: VisualQAProfile = VisualQAProfile(),
) -> VisualQAResult:
    result = VisualQAResult()
    paths = [Path(item) for item in rendered]
    if not paths:
        result.available = False
        result.errors.append("no rendered evidence was provided")
        return result
    try:
        signatures = [image_signature(path) for path in paths]
    except (OSError, RuntimeError, FileNotFoundError) as exc:
        result.available = False
        result.errors.append(f"visual QA unavailable: {exc}")
        return result

    result.rendered = {
        "count": len(signatures),
        "images": [signature.as_dict() for signature in signatures],
        "profile": profile.as_dict(),
    }
    result.boundary = _boundary_result(str(reference.get("subject", "")) if reference else "", reference)
    if not result.boundary["passed"]:
        result.blocking.append("reference boundary: requested product collides with forbidden reference subject")

    candidate_values = list(concepts)
    if candidate_values:
        selected = candidate_values[0]
        distances = [_concept_axis_distance(selected, other) for other in candidate_values[1:]]
        result.concept = {
            "selected": selected.id,
            "axis_distances": distances,
            "min_required": profile.min_concept_axis_distance,
            "passed": bool(distances) and all(distance >= profile.min_concept_axis_distance for distance in distances),
        }
        if not result.concept["passed"]:
            result.blocking.append("concept diversity: candidate directions do not differ across the required axes")

    if reference and reference.get("path"):
        try:
            reference_signature = image_signature(Path(str(reference["path"])))
            distances = [hash_distance(reference_signature, signature) for signature in signatures]
            result.reference = {
                "path": str(reference["path"]),
                "hash_distances": distances,
                "max_hash_distance": profile.max_hash_distance,
                "boundary_required": True,
                "passed": all(distance > profile.max_hash_distance for distance in distances),
                "fidelity_status": "review-required",
                "permitted_attributes": list(reference.get("borrowable", ())),
                "note": "Hash distance is a composition guard, not a semantic fidelity score; independent review must assess permitted fidelity.",
            }
            if not result.reference["passed"]:
                result.blocking.append("reference boundary: rendered result is too close to the reference composition")
        except (OSError, RuntimeError, FileNotFoundError) as exc:
            result.errors.append(f"reference comparison unavailable: {exc}")

    recent_values = [
        item for item in recent_runs
        if not (product_family and str(item.get("product_family", "")) == product_family)
    ][: profile.recent_run_limit]
    recent_distances: list[dict[str, Any]] = []
    for item in recent_values:
        for path in item.get("rendered", []):
            try:
                prior = image_signature(Path(str(path)))
                recent_distances.append({
                    "path": str(path),
                    "distances": [hash_distance(prior, signature) for signature in signatures],
                })
            except (OSError, RuntimeError, FileNotFoundError):
                continue
    duplicate = [item for item in recent_distances if any(distance <= profile.max_hash_distance for distance in item["distances"])]
    result.novelty = {
        "population_size": len(recent_values),
        "comparisons": recent_distances,
        "near_duplicates": duplicate,
        "max_hash_distance": profile.max_hash_distance,
        "passed": not duplicate,
    }
    if duplicate:
        result.blocking.append("template convergence: rendered result is near-duplicate with a recent different-product run")
    return result


def evidence_from_json(value: str | Path) -> VisualQAResult:
    raw = json.loads(Path(value).read_text("utf-8"))
    if not isinstance(raw, dict):
        raise ValueError("visual QA evidence must be an object")
    return VisualQAResult(
        available=bool(raw.get("available", True)),
        version=str(raw.get("version", PROFILE_VERSION)),
        rendered=dict(raw.get("rendered", {})),
        reference=dict(raw.get("reference", {})),
        novelty=dict(raw.get("novelty", {})),
        boundary=dict(raw.get("boundary", {})),
        concept=dict(raw.get("concept", {})),
        errors=[str(item) for item in raw.get("errors", [])],
        blocking=[str(item) for item in raw.get("blocking", [])],
    )
