"""Source assessment and grounded web context.

Retrieval is represented as data so quality gates can distinguish evidence
from model synthesis and fail honestly when no usable source exists.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from urllib.parse import urlparse


@dataclass(frozen=True)
class Source:
    url: str
    title: str = ""
    text: str = ""
    quality: str = "unknown"

    def validate(self) -> None:
        parsed = urlparse(self.url)
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            raise ValueError("source URL must be an HTTP(S) URL")


@dataclass
class RetrievalResult:
    query: str
    sources: list[Source] = field(default_factory=list)
    failure: str = ""
    warnings: list[str] = field(default_factory=list)

    @property
    def usable(self) -> bool:
        return bool(self.sources) and not self.failure


def assess_retrieval(query: str, sources: list[Source], *, source_limit: int = 4) -> RetrievalResult:
    if not query.strip():
        return RetrievalResult(query=query, failure="empty query")
    usable: list[Source] = []
    warnings: list[str] = []
    for source in sources:
        try:
            source.validate()
        except ValueError as exc:
            warnings.append(str(exc))
            continue
        if not source.text.strip():
            warnings.append(f"source has no extractable text: {source.url}")
            continue
        if source.quality in {"low", "untrusted"}:
            warnings.append(f"low-quality source retained with warning: {source.url}")
        usable.append(source)
        if len(usable) >= source_limit:
            if len(usable) < len(sources):
                warnings.append(f"source limit {source_limit} applied")
            break
    if not usable:
        return RetrievalResult(query=query, sources=[], failure="no usable web evidence", warnings=warnings)
    return RetrievalResult(query=query, sources=usable, warnings=warnings)


def grounded_context(result: RetrievalResult) -> str:
    if not result.usable:
        raise ValueError(result.failure or "retrieval has no usable evidence")
    return "\n\n".join(f"[{source.title or source.url}] {source.text}" for source in result.sources)
