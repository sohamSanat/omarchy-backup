"""Small, provider-free UI flow decisions shared by the router and tests."""
from __future__ import annotations

import re
from dataclasses import dataclass
from enum import StrEnum
from typing import Any

from .ui_brief import DesignContract
from .ui_context import UiRunContext, context_from_contract


class UiFlowAction(StrEnum):
    SELECT_CONCEPT = "select_concept"
    REQUEST_MORE_CONCEPTS = "request_more_concepts"
    CONTINUE_SAME_RUN = "continue_same_run"
    START_NEW_TASK = "start_new_task"
    CANCEL = "cancel"


@dataclass(frozen=True)
class UiFlowDecision:
    action: UiFlowAction
    concept_id: str = ""
    reason: str = ""


def parse_concept_selection(text: str, candidates: list[dict[str, Any]]) -> UiFlowDecision:
    value = text.strip().lower()
    if value in {"cancel", "abort", "exit", "quit", "stop"}:
        return UiFlowDecision(UiFlowAction.CANCEL, reason="user cancelled the UI flow")
    if value in {"another", "regenerate", "more concepts", "new concepts"}:
        return UiFlowDecision(UiFlowAction.REQUEST_MORE_CONCEPTS)
    if value in {"continue", "retry", "resume"}:
        return UiFlowDecision(UiFlowAction.CONTINUE_SAME_RUN, reason="same-run continuation")
    if value in {"/new", "new task", "new project", "create project"}:
        return UiFlowDecision(UiFlowAction.START_NEW_TASK, reason="explicit new-task intent")
    ids = {str(item.get("id", "")).strip(): str(item.get("id", "")).strip() for item in candidates if item.get("id")}
    if value in ids:
        return UiFlowDecision(UiFlowAction.SELECT_CONCEPT, concept_id=ids[value])
    match = re.search(r"(?:concept\s*)?([123])\b", value)
    if match:
        index = int(match.group(1)) - 1
        if 0 <= index < len(candidates):
            concept_id = str(candidates[index].get("id", ""))
            if concept_id:
                return UiFlowDecision(UiFlowAction.SELECT_CONCEPT, concept_id=concept_id)
    for item in candidates:
        title = str(item.get("title", "")).strip().lower()
        if title and title in value:
            return UiFlowDecision(UiFlowAction.SELECT_CONCEPT, concept_id=str(item.get("id", "")))
    return UiFlowDecision(UiFlowAction.CONTINUE_SAME_RUN, reason="no concept selected; remain on the same run")


def selected_context(
    state: dict[str, Any],
    *,
    run_id: str = "",
    state_name: str = "awaiting_user",
) -> tuple[DesignContract, UiRunContext]:
    contract = DesignContract.from_dict(state.get("contract", {}))
    contract.validate()
    try:
        context = UiRunContext.from_dict(state.get("ui_context", {}))
    except (TypeError, ValueError):
        context = context_from_contract(
            contract,
            run_id=run_id or str(state.get("run_id", "")),
            reference_evidence=state.get("reference"),
            state=state_name,
        )
    context.selected_concept_id = contract.selected_concept_id
    context.state = state_name
    context.validate()
    return contract, context
