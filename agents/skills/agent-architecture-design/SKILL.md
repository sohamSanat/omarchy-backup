---
name: agent-architecture-design
description: >
  Expert guidance on designing, scaffolding, and implementing AI agent architectures.
  Use when building or analyzing autonomous agents, multi-agent workflows, state machines,
  tool-use loops, ReAct / Plan-and-Solve / Reflexion patterns, or frameworks like LangGraph,
  LlamaIndex Workflows, DSPy, and custom async agent runtimes.
---

# Agent Architecture Design

This skill provides architectural patterns, design principles, and concrete scaffolding for engineering robust, production-grade AI agents and multi-agent systems.

## When to Use This Skill
- Designing or implementing single-agent loops (ReAct, Plan-and-Solve, Reflexion, Tree of Thoughts).
- Structuring multi-agent orchestration (supervisor-worker, router-expert, peer debate).
- Implementing state management, graph execution, persistence, and checkpointing.
- Designing Human-in-the-Loop (HITL) breakpoints, approval steps, and interruptible state.
- Scaffolding new agentic projects, thesis prototypes, or coursework assignments.

---

## Core Agent Patterns Matrix

| Pattern | Flow Type | Best For | Failure Modes & Mitigations |
| :--- | :--- | :--- | :--- |
| **ReAct** (Reason + Act) | Iterative cyclic loop: Think $\to$ Act $\to$ Observe | Dynamic tasks, web browsing, command-line investigation | Infinite loops, repetitive tool calls. *Fix: Sliding window, turn limits, loop detection.* |
| **Plan-and-Solve** | Two-stage: Plan upfront $\to$ Step-by-step execute $\to$ Re-plan | Complex multi-step coding, refactoring, math | Inflexible plans failing on unexpected errors. *Fix: Dynamic replanning after step failures.* |
| **Reflexion** | Self-reflection with verbal feedback memory | Code generation, reasoning benchmarks, game playing | Hallucinated critiques. *Fix: Ground critique on deterministic test/compiler output.* |
| **Supervisor-Worker** | Central router coordinates specialized subagents | Broad domain tasks, multi-role development (Architect, Coder, QA) | Bottleneck supervisor, context blowout. *Fix: Structured summary handoffs, isolated contexts.* |
| **State Graph (DAG / Cyclic)** | Explicit graph nodes with deterministic state transitions | Mission-critical workflows, enterprise agent pipelines | Overly rigid flows. *Fix: Hybrid routing (deterministic nodes + LLM router nodes).* |

---

## Architecture Blueprint: The Modern Agent Stack

Every robust agent system consists of 5 modular components:

```
+-------------------------------------------------------------+
|                      User / Herdr TUI                       |
+-------------------------------------------------------------+
                              |
+-------------------------------------------------------------+
|                   Agent Orchestrator                        |
|  - Lifecycle Management (Init, Run, Interrupt, Resume, Kill) |
|  - Token & Budget Guardrails                                |
|  - Human-in-the-loop (HITL) Approvals                       |
+-------------------------------------------------------------+
       |                           |                     |
+---------------+          +---------------+     +---------------+
|     State     |          |  Reasoning    |     | Tool Registry |
|  Persistence  |          |    Engine     |     |   & Execution |
| - Checkpoints |          | - Prompts     |     | - Schema Gen  |
| - SQLite/WAL  |          | - Structured  |     | - Validation  |
| - Thread ID   |          |   Outputs     |     | - Sandboxing  |
+---------------+          +---------------+     +---------------+
                                   |
                           +---------------+
                           |    Memory     |
                           | - In-Context  |
                           | - Vector/RAG  |
                           | - Episodic    |
                           +---------------+
```

---

## Recommended Project Scaffolding

For college coursework, research prototypes, and production agents, use this modular directory layout:

```text
my-agent-project/
├── pyproject.toml              # Dependencies (poetry / uv / pip)
├── .env.example                # API keys and environment variables
├── README.md                   # Problem definition, architecture diagram, evals
├── src/
│   └── agent/
│       ├── __init__.py
│       ├── config.py           # Model parameters, timeout limits, max steps
│       ├── state.py            # TypedDict / Pydantic state definitions
│       ├── prompts/            # System prompts, role prompts, few-shot examples
│       │   ├── system.md
│       │   └── reflection.md
│       ├── tools/              # Granular, typed tool definitions
│       │   ├── base.py
│       │   ├── filesystem.py
│       │   └── search.py
│       ├── memory/             # Short-term buffer, episodic store, vector RAG
│       │   ├── buffer.py
│       │   └── vector_store.py
│       └── graph.py            # LangGraph / Workflow state machine definition
├── tests/
│   ├── unit/                   # Tool unit tests, state transition tests
│   └── evals/                  # Benchmark datasets, LLM-as-judge evals, pass@k
└── scripts/
    ├── run_interactive.py      # Terminal runner (integrates with Herdr)
    └── run_benchmark.py        # Eval harness runner
```

---

## Implementation Template: Robust Typed State Machine

Below is a clean, minimal reference implementation using Python dataclasses/Pydantic demonstrating ReAct with structured reflection:

```python
from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional
from enum import Enum
import json

class AgentStatus(str, Enum):
    IDLE = "idle"
    WORKING = "working"
    BLOCKED = "blocked"   # Waiting for human confirmation
    DONE = "done"
    FAILED = "failed"

@dataclass
class StepRecord:
    step: int
    thought: str
    action: str
    action_input: Dict[str, Any]
    observation: Optional[str] = None
    reflection: Optional[str] = None

@dataclass
class AgentState:
    task: str
    status: AgentStatus = AgentStatus.IDLE
    current_step: int = 0
    max_steps: int = 15
    trajectory: List[StepRecord] = field(default_factory=list)
    artifacts: Dict[str, Any] = field(default_factory=dict)
    last_error: Optional[str] = None

    def record_step(self, thought: str, action: str, action_input: Dict[str, Any]) -> StepRecord:
        self.current_step += 1
        rec = StepRecord(
            step=self.current_step,
            thought=thought,
            action=action,
            action_input=action_input
        )
        self.trajectory.append(rec)
        return rec
```

---

## Critical Design Rules for Agentic Systems

1. **Explicit Loop Termination**:
   - Always enforce a strict `max_steps` or `token_budget` safeguard.
   - Detect repeated action sequences (looping over the same tool call with identical arguments).
2. **Deterministic Output Separation**:
   - Separate tool calls from conversational text. Use native Function Calling / Structured Outputs whenever available rather than regex parsing raw text.
3. **Structured Errors for Self-Correction**:
   - When a tool fails, return a clear, diagnostic error string into the agent's observation window (e.g., `{"status": "error", "code": "FILE_NOT_FOUND", "suggestion": "Check file path with list_dir"}`).
4. **State Snapshotting**:
   - Checkpoint the full `AgentState` before every external tool invocation so you can replay, fork, or debug execution trajectories.
