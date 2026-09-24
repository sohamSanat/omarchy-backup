"""Adaptive execution sizing for agentic coding tasks.

The policy chooses the smallest safe execution envelope. It does not remove
verification; it removes ceremony that is not justified by the task.
"""
from __future__ import annotations

import re
from dataclasses import dataclass


class ExecutionMode:
    NEEDLE = "needle"
    STANDARD = "standard"
    SWORD = "sword"


_SWORD_TERMS = (
    "architecture", "architectural", "refactor", "migration", "migrate", "authentication",
    "authorization", "security", "database", "schema", "concurrency", "race condition",
    "performance", "protocol", "cross-platform", "integration", "deployment", "release",
    "breaking change", "distributed", "production incident", "security vulnerability",
)
_SCOPE_TERMS = (
    "across the codebase", "across the project", "system-wide", "end-to-end", "rewrite",
    "redesign", "replace the", "from scratch", "whole system", "all modules", "every module",
    "multiple services", "production incident", "breaking change",
)
_STANDARD_TERMS = (
    "bug", "error", "test", "feature", "endpoint", "api", "parser", "validation", "state",
    "workflow", "component", "page", "interface", "accessibility", "responsive", "implement",
    "function", "class", "module", "database query",
)
_SIMPLE_ACTIONS = re.compile(
    r"\b(typo|rename|comment|docstring|readme|documentation|docs|format|formatting|lint|"
    r"small|quick|minor|one[- ]line|single[- ]file|add a test|update a test|fix a typo|"
    r"change the label|rename a variable|update a comment)\b",
    re.IGNORECASE,
)
_MODE_OVERRIDE = re.compile(r"^/(needle|standard|sword)\b", re.IGNORECASE)


@dataclass(frozen=True)
class ExecutionPolicy:
    mode: str
    reason: str
    max_tool_calls: int
    max_agents: int
    max_minutes: int
    use_fleet: bool
    require_independent_review: bool
    skill_directive: str
    complexity_score: int = 0
    signals: tuple[str, ...] = ()

    def prompt_directive(self) -> str:
        return f"""[OMAGENT ADAPTIVE EXECUTION POLICY: {self.mode.upper()}]
Reason: {self.reason}
Budget: at most {self.max_tool_calls} tool calls, {self.max_agents} active agents, and {self.max_minutes} minutes of execution time.

Use the smallest tool that proves the result:
- Inspect only files directly relevant to the request.
- Prefer one direct edit or one focused command over broad exploration.
- Run the narrowest relevant verification first.
- Do not spawn subagents for a small task.
- Do not load broad lifecycle, migration, architecture, or review skills unless the task requires them or the first verification fails.
- Stop after the requested change and focused verification. Do not add speculative features, extra abstractions, or unrelated cleanup.
- If the task expands, state why the larger execution envelope is now necessary.
"""


def _policy(mode: str, reason: str, *, score: int, signals: tuple[str, ...], is_ui: bool = False) -> ExecutionPolicy:
    if mode == ExecutionMode.NEEDLE:
        return ExecutionPolicy(
            mode=mode,
            reason=reason,
            max_tool_calls=8,
            max_agents=1,
            max_minutes=10,
            use_fleet=False,
            require_independent_review=False,
            skill_directive="Use one focused edit, one relevant test, and a short report. Do not use subagents or broad skills.",
            complexity_score=score,
            signals=signals,
        )
    if mode == ExecutionMode.SWORD:
        return ExecutionPolicy(
            mode=mode,
            reason=reason,
            max_tool_calls=64,
            max_agents=4,
            max_minutes=90,
            use_fleet=True,
            require_independent_review=True,
            skill_directive="Use the full engineering, test, review, and verification envelope.",
            complexity_score=score,
            signals=signals,
        )
    return ExecutionPolicy(
        mode=mode,
        reason=reason,
        max_tool_calls=28 if is_ui else 24,
        max_agents=4,
        max_minutes=35 if is_ui else 45,
        use_fleet=True,
        require_independent_review=True,
        skill_directive="Use the Impeccable-led UI/UX bundle and rendered browser evidence." if is_ui else "Use focused implementation and verification; escalate only if evidence shows wider risk.",
        complexity_score=score,
        signals=signals,
    )


def assess_execution_policy(request: str, *, is_ui: bool = False, is_coding: bool = False) -> ExecutionPolicy:
    """Classify a request from its observable scope and risk signals."""
    text = " ".join(request.split())
    lower = text.lower()
    override = _MODE_OVERRIDE.match(lower)
    if override and not is_ui:
        requested = override.group(1).lower()
        return _policy(
            requested,
            f"The request explicitly selected the {requested} execution mode.",
            score=0,
            signals=(f"explicit:{requested}",),
        )
    sword_hits = tuple(term for term in _SWORD_TERMS if term in lower)
    scope_hits = tuple(term for term in _SCOPE_TERMS if term in lower)
    standard_hits = tuple(term for term in _STANDARD_TERMS if term in lower)
    simple_hit = bool(_SIMPLE_ACTIONS.search(lower))
    signals = tuple(
        list(("sword:" + term for term in sword_hits))
        + list(("scope:" + term for term in scope_hits))
        + list(("standard:" + term for term in standard_hits))
        + (list(("narrow",)) if simple_hit else [])
    )
    score = len(sword_hits) * 3 + len(scope_hits) * 2 + len(standard_hits)
    if is_ui:
        if sword_hits or scope_hits:
            return _policy(
                ExecutionMode.SWORD,
                "UI work has architecture, migration, security, or system-wide scope.",
                score=score,
                signals=signals,
                is_ui=True,
            )
        return _policy(
            ExecutionMode.STANDARD,
            "UI work requires a rendered design pass and visual critique.",
            score=score,
            signals=signals or ("ui-rendered-work",),
            is_ui=True,
        )
    if sword_hits or scope_hits or score >= 4:
        return _policy(
            ExecutionMode.SWORD,
            "The request has architecture, security, migration, reliability, or system-wide risk.",
            score=score,
            signals=signals,
        )
    if is_coding and len(text) <= 320 and simple_hit and not sword_hits and not scope_hits and not standard_hits:
        return _policy(
            ExecutionMode.NEEDLE,
            "The request is narrow, local, and has no detected architecture or lifecycle risk.",
            score=score,
            signals=signals,
        )
    reason = "The request changes behavior or has moderate implementation scope."
    if standard_hits:
        reason = "The request changes behavior and needs focused implementation plus verification."
    return _policy(ExecutionMode.STANDARD, reason, score=score, signals=signals)

