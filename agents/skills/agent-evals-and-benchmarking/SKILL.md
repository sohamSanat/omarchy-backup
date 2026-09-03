---
name: agent-evals-and-benchmarking
description: >
  Guide and tooling for rigorous evaluation, benchmarking, and quality assurance of AI agents.
  Use when creating eval harnesses, measuring pass@k, benchmarking agent trajectories,
  implementing LLM-as-a-judge rubrics, testing tool precision/recall, or setting up SWE-bench / GAIA style tests.
---

# Agent Evaluations & Benchmarking

In agentic engineering, **evaluation is the unit of progress**. Anyone can make a demo work once; engineering begins when you measure task completion rates, cost, latency, and regressions systematically across hundreds of runs.

## When to Use This Skill
- Designing an evaluation harness for an agent or multi-agent system.
- Formulating test cases, synthetic edge cases, and deterministic ground-truth assertions.
- Implementing LLM-as-a-Judge evaluators with rubric scoring and bias mitigation.
- Measuring agent performance: pass@1, pass@k, step count, token cost, and tool selection accuracy.
- Comparing model backends (e.g. Gemini 3.8 Flash vs Claude 3.7 Sonnet vs GPT-4o) on specific agent tasks.
- Preparing benchmarks for research papers, thesis presentations, or portfolio projects.

---

## Evaluation Taxonomy

Agent evaluations fall into two complementary layers:

### 1. Outcome / State-Based Evaluation (Deterministic)
Evaluates whether the final environment state matches the desired goal:
- Did the test suite pass (`pytest`, `npm test`)?
- Was the target file created with valid syntax?
- Did the database record contain the expected values?
- *Advantages:* 100% reproducible, zero judge hallucinations, fast.
- *Limitations:* Doesn't measure efficiency, safety, or reasoning quality.

### 2. Trajectory / Process-Based Evaluation (Analytical & LLM-as-a-Judge)
Evaluates the path the agent took to reach the solution:
- **Tool Selection Precision & Recall:** Did the agent invoke unnecessary tools? Did it call the optimal tool?
- **Redundant Steps / Loops:** Did the agent query the same URL or grep repeatedly?
- **Information Leakage / Guardrail Violations:** Did the agent expose secrets or bypass safety constraints?
- **Reasoning Fidelity:** Was the chain-of-thought coherent, or did it arrive at the answer via spurious correlation?

---

## Core Metrics Formulas

| Metric | Definition | Goal |
| :--- | :--- | :--- |
| **Pass@1** | Proportion of tasks solved on the first attempt ($N=1$). | High reliability |
| **Pass@k** | Probability that at least one of $k$ independent runs succeeds: $1 - \binom{n-c}{k}/\binom{n}{k}$. | Exploration capacity |
| **Tool Precision** | $\frac{\text{Relevant Tools Called}}{\text{Total Tools Called}}$ | Minimize noise & token waste |
| **Step Efficiency** | $\frac{\text{Optimal Step Count}}{\text{Actual Steps Taken}}$ | Minimize latency & API cost |
| **Cost per Resolved Task** | Total tokens consumed across attempts $\times$ price / successful tasks. | Production viability |

---

## Reference Implementation: Lightweight Python Eval Harness

Below is a complete, extensible evaluation harness pattern for testing agent tasks:

```python
import json
import time
from dataclasses import dataclass, asdict
from typing import Callable, Dict, Any, List

@dataclass
class EvalCase:
    id: str
    prompt: str
    ground_truth: Dict[str, Any]
    eval_type: str  # "deterministic" | "llm_judge"

@dataclass
class EvalResult:
    case_id: str
    success: bool
    score: float
    duration_sec: float
    total_tokens: int
    cost_usd: float
    error: str = ""
    trajectory_summary: str = ""

class AgentEvalHarness:
    def __init__(self, agent_runner: Callable[[str], Dict[str, Any]]):
        self.agent_runner = agent_runner
        self.results: List[EvalResult] = []

    def run_case(self, case: EvalCase) -> EvalResult:
        start_time = time.time()
        try:
            output = self.agent_runner(case.prompt)
            duration = time.time() - start_time
            
            # Deterministic check example
            success = output.get("result") == case.ground_truth.get("expected")
            score = 1.0 if success else 0.0
            
            res = EvalResult(
                case_id=case.id,
                success=success,
                score=score,
                duration_sec=duration,
                total_tokens=output.get("tokens", 0),
                cost_usd=output.get("cost", 0.0),
                trajectory_summary=f"Steps: {len(output.get('steps', []))}"
            )
        except Exception as e:
            res = EvalResult(
                case_id=case.id,
                success=False,
                score=0.0,
                duration_sec=time.time() - start_time,
                total_tokens=0,
                cost_usd=0.0,
                error=str(e)
            )
        self.results.append(res)
        return res

    def report(self) -> Dict[str, Any]:
        total = len(self.results)
        passed = sum(1 for r in self.results if r.success)
        return {
            "total_cases": total,
            "pass_rate": passed / total if total > 0 else 0.0,
            "avg_duration": sum(r.duration_sec for r in self.results) / total if total > 0 else 0.0,
            "total_cost_usd": sum(r.cost_usd for r in self.results)
        }
```

---

## LLM-as-a-Judge: Best Practices & Bias Mitigation

When deterministic evaluation is impossible (e.g., evaluating code readability, report quality, or conversational empathy), use LLM-as-a-Judge with these safeguards:

1. **Rubric-Based Scoring**: Provide explicit criteria for each score bracket (1 through 5).
2. **Chain-of-Thought First**: Demand that the judge model write its analytical critique *before* outputting the numerical score.
3. **Position Bias Defense**: When comparing two agent outputs ($A$ vs $B$), swap the positions ($B$ vs $A$) and verify consistency.
4. **Length Bias Defense**: Instruct the judge explicitly: *"Do not penalize concise answers if they completely satisfy the prompt requirements."*
5. **Calibrate Against Human Annotations**: Annotate 20-50 samples manually and ensure the judge achieves $>85\%$ agreement (Cohen's Kappa $\kappa > 0.7$).
