---
name: agentic-research-scout
description: >
  Academic research companion for discovering, dissecting, summarizing, and reproducing
  frontier AI and Agentic Engineering research papers (arXiv cs.AI, cs.CL, cs.SE, cs.MA).
  Use when conducting literature reviews, analyzing agent system architectures from papers,
  extracting algorithmic pseudocode, or preparing research prototypes for class or thesis work.
---

# Agentic Research Scout

A specialized research skill for college students and researchers in **Agentic AI**. It turns research papers into actionable insights, algorithmic specifications, and reproducible prototypes.

## When to Use This Skill
- Deconstructing newly published agent papers from arXiv or top conferences (NeurIPS, ICLR, ICML, ACL).
- Synthesizing literature reviews on agent topics (e.g., multi-agent consensus, memory compaction, tool-use learning).
- Extracting exact prompt templates, system instructions, and state transition graphs from papers.
- Scaffolding a minimal working prototype (MVP) to reproduce an experiment or benchmark.
- Finding unexplored research questions and ablation ideas for coursework, hackathons, or thesis projects.

---

## 5-Point Paper Deconstruction Framework

When analyzing an agent paper, dissect it through these 5 lenses:

```
+----------------------------------------------------------------+
| 1. Core Hypothesis & Innovation                                |
|    - What specific bottleneck does this paper solve?           |
|    - E.g.: Context window explosion, error recovery failure?   |
+----------------------------------------------------------------+
                               |
+----------------------------------------------------------------+
| 2. Agentic Architecture Specification                          |
|    - Perception: How are inputs and environmental state fed?   |
|    - Reasoning Loop: ReAct, Tree of Thoughts, Reflexion, etc.? |
|    - Action Space: Shell, Python REPL, custom API schema?      |
|    - Memory Topology: Short-term buffer, vector, episodic?     |
+----------------------------------------------------------------+
                               |
+----------------------------------------------------------------+
| 3. Evaluation Rigor & Benchmarks                               |
|    - Datasets: SWE-bench, GAIA, HumanEval, WebArena, AgentBench|
|    - Baselines: Which models/frameworks did they compare to?   |
|    - Ablations: Which component actually drives the score?     |
+----------------------------------------------------------------+
                               |
+----------------------------------------------------------------+
| 4. Failure Modes & Critical Blindspots                         |
|    - What tasks did the agent fail?                            |
|    - Cost & Token Overhead: Is it practical in production?    |
+----------------------------------------------------------------+
                               |
+----------------------------------------------------------------+
| 5. Reproducibility Roadmap                                     |
|    - Minimal lines of code needed to verify the core idea.     |
|    - Key prompt strings and state graph nodes.                 |
+----------------------------------------------------------------+
```

---

## Milestone Agent Papers Taxonomy

| Category | Seminal Papers | Key Contribution |
| :--- | :--- | :--- |
| **Reasoning Loops** | *ReAct* (Yao et al., 2022)<br>*Reflexion* (Shinn et al., 2023)<br>*Tree of Thoughts* (Yao et al., 2023) | Synergizing reasoning and acting; verbal reinforcement learning without parameter updates. |
| **Software Engineering** | *SWE-agent* (Yang et al., 2024)<br>*Agentless* (Xia et al., 2024)<br>*OpenCode / Devin* | Agent-Computer Interface (ACI) design; hierarchical localization and deterministic patch generation. |
| **Multi-Agent Systems** | *CAMEL* (Li et al., 2023)<br>*ChatDev* (Qian et al., 2023)<br>*MetaGPT* (Hong et al., 2023) | Role-playing frameworks; standard operating procedures (SOPs) for multi-agent software development. |
| **Memory & Long Context** | *MemGPT* (Packer et al., 2023)<br>*Voyager* (Wang et al., 2023)<br>*Generative Agents* (Park et al., 2023) | OS-inspired hierarchical memory management; iterative skill library accumulation in Minecraft. |
| **Tool & Function Calling** | *Toolformer* (Schick et al., 2023)<br>*Gorilla* (Patil et al., 2023)<br>*ToolBench* (Qin et al., 2023) | Teaching LMs when and how to invoke external APIs via self-supervised fine-tuning. |

---

## Research Synthesis Template

When asked to summarize an agent paper or literature topic, format the output as follows:

```markdown
## Paper Title & Metadata
- **Authors & Affiliation**: ...
- **Venue / arXiv ID**: ...
- **Code Repository**: ...

### 1. Problem Statement & Motivation
[Why existing agent systems fail at this task]

### 2. Proposed Architecture & Innovation
- **Prompting / Flow Strategy**: [e.g., Two-stage debate with moderator]
- **State & Memory Model**: [e.g., Working memory + Episodic retrieval]
- **Tool / Environment Interface**: [e.g., Sandboxed Bash environment]

### 3. Empirical Results & Ablations
- **Benchmark**: [e.g., SWE-bench Lite]
- **Metric**: [e.g., 27.3% resolved vs 18.2% baseline]
- **Key Ablation Finding**: [e.g., Removing the reflection step drops pass rate by 9%]

### 4. Critical Assessment for Practitioners
- **Strengths**: ...
- **Limitations & Cost**: [e.g., Requires 15 LLM calls per step; high latency]
- **Applicability in Herdr Multi-Agent Setups**: ...

### 5. Minimal Python Prototype
```python
# Minimal 30-50 line script demonstrating the core algorithmic mechanism
```
```
