"""Deterministic text and stream assembly rules."""
from __future__ import annotations

from collections.abc import Iterable


def assemble_stream(chunks: Iterable[str]) -> str:
    """Join provider chunks exactly once without normalizing whitespace."""
    return "".join(str(chunk) for chunk in chunks)


def limit_request(request: str, limit: int = 2500) -> tuple[str, bool]:
    text = str(request)
    if len(text) <= limit:
        return text, False
    return text[:limit], True
