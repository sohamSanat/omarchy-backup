---
name: agent-memory-and-rag
description: >
  Guide and implementations for engineering agent memory systems, context compaction,
  episodic trajectory storage, and agentic Retrieval-Augmented Generation (RAG).
  Use when implementing short/long-term memory, context window pruning, semantic retrieval,
  vector databases (Chroma, Qdrant, LanceDB), or MemGPT-style hierarchical memory.
---

# Agent Memory & Context Engineering

Long-horizon agents must operate beyond the limits of a single context window. **Memory engineering** equips agents with the ability to recall facts, learn from past mistakes, retain user preferences, and navigate massive codebases.

## When to Use This Skill
- Implementing episodic memory (storing task history and self-reflections).
- Implementing semantic memory / Agentic RAG (codebase search, documentation retrieval).
- Managing context window limits through recursive summarization and message compaction.
- Designing persistent memory stores using SQLite, Chroma, Qdrant, or LanceDB.
- Mitigating the "lost in the middle" attention problem and catastrophic forgetting.

---

## The 4 Tiers of Agent Memory

```
+-------------------------------------------------------------------+
| 1. Working Memory (Short-Term / In-Context)                       |
|    - System prompt, immediate chat history, active scratchpad     |
|    - Lifespan: Current execution turn / conversation              |
+-------------------------------------------------------------------+
                               |
+-------------------------------------------------------------------+
| 2. Episodic Memory (Experience & Trajectories)                   |
|    - Past task attempts, successes, failures, Reflexion records    |
|    - "Last time I ran 'npm build' in this project, it needed flag"|
|    - Lifespan: Cross-session persistent                           |
+-------------------------------------------------------------------+
                               |
+-------------------------------------------------------------------+
| 3. Semantic Memory (World & Domain Knowledge)                     |
|    - Vector embeddings, RAG over codebases, technical docs        |
|    - Hybrid dense (vector) + sparse (BM25) search                 |
|    - Lifespan: Static or periodically updated index               |
+-------------------------------------------------------------------+
                               |
+-------------------------------------------------------------------+
| 4. Procedural Memory (Skills & Tools)                             |
|    - Reusable executable functions, MCP tools, shell scripts      |
|    - Dynamic skill acquisition (e.g. Voyager skill library)       |
|    - Lifespan: System runtime repository                          |
+-------------------------------------------------------------------+
```

---

## Context Compaction Techniques

When an agent conversation approaches token capacity:

1. **Sliding Window with Pinned System Context**:
   - Keep the system prompt, initial task description, and latest $K$ interaction turns.
   - Discard intermediate turns.
2. **Recursive Structured Summarization**:
   - Summarize older turns into a compact structured state:
     ```json
     {
       "goal": "Build JWT authentication endpoint",
       "completed_actions": ["Created src/auth.py", "Added PyJWT dependency"],
       "current_blocker": "Token expiration test failing with 401",
       "active_hypotheses": ["Timezone mismatch in datetime.utcnow()"]
     }
     ```
3. **Observation Pruning**:
   - Long command outputs (e.g., `git diff` or build logs of 500+ lines) should be truncated immediately after the agent acknowledges them, keeping only the final exit code and summary.

---

## Reference Implementation: SQLite-Backed Episodic Memory

A lightweight, zero-external-dependency episodic memory store using Python's standard `sqlite3`:

```python
import sqlite3
import json
import time
from typing import List, Dict, Any, Optional

class EpisodicMemoryStore:
    def __init__(self, db_path: str = "agent_memory.sqlite"):
        self.conn = sqlite3.connect(db_path)
        self._init_db()

    def _init_db(self):
        with self.conn:
            self.conn.execute("""
                CREATE TABLE IF NOT EXISTS episodes (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp REAL,
                    task TEXT,
                    success INTEGER,
                    reflection TEXT,
                    tags TEXT
                )
            """)

    def record_episode(self, task: str, success: bool, reflection: str, tags: List[str]):
        with self.conn:
            self.conn.execute(
                "INSERT INTO episodes (timestamp, task, success, reflection, tags) VALUES (?, ?, ?, ?, ?)",
                (time.time(), task, int(success), reflection, json.dumps(tags))
            )

    def retrieve_relevant_lessons(self, query: str, limit: int = 3) -> List[Dict[str, Any]]:
        cursor = self.conn.cursor()
        # Full-text or tag match query
        cursor.execute(
            "SELECT task, success, reflection FROM episodes WHERE task LIKE ? OR reflection LIKE ? ORDER BY timestamp DESC LIMIT ?",
            (f"%{query}%", f"%{query}%", limit)
        )
        return [{"task": r[0], "success": bool(r[1]), "reflection": r[2]} for r in cursor.fetchall()]
```

---

## Production Rules for Memory Systems

- **Never Trust Vector Search Alone**: Always combine vector search with keyword/BM25 filtering (Hybrid Search). Code symbols (e.g., `process_payment_v2`) require exact lexical matching that embeddings often miss.
- **Deduplicate Lessons**: Prevent the agent from inserting repetitive reflections into episodic memory. Cluster similar reflections before storage.
- **Audit Logs**: Maintain a human-readable SQLite or JSONL log of memory insertions for debugging.
