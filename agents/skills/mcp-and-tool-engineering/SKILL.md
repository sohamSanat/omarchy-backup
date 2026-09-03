---
name: mcp-and-tool-engineering
description: >
  Comprehensive guide and templates for designing, implementing, testing, and debugging
  Model Context Protocol (MCP) servers and LLM tool interfaces in Python and TypeScript.
  Use when creating custom MCP tools, integrating external APIs, building secure tool sandboxes,
  or optimizing function-calling schemas for agents.
---

# MCP & Tool Engineering

The **Model Context Protocol (MCP)** is the open standard that connects AI agents to data sources and execution environments. Mastering tool engineering is fundamental to agentic engineering: well-designed tools drastically reduce hallucination and execution failures.

## When to Use This Skill
- Creating custom MCP servers in Python (FastMCP / `mcp`) or TypeScript (`@modelcontextprotocol/sdk`).
- Designing tool schemas, parameter types, and docstrings that optimize LLM function-calling accuracy.
- Implementing error returns that guide agents toward self-correction rather than crashing.
- Setting up tool sandboxing, input sanitization, and security guardrails.
- Debugging MCP servers using the MCP Inspector or JSON-RPC testing scripts.

---

## MCP Primitives Overview

| Primitive | Purpose | Agent Interaction | Example |
| :--- | :--- | :--- | :--- |
| **Tools** | Executable functions with side effects or dynamic data fetching. | Model calls tool, environment executes and returns output. | `run_query`, `compile_code`, `create_github_issue` |
| **Resources** | Static or dynamic context data accessible via URI. | Attached to context or read on-demand. | `file:///src/main.py`, `postgres://db/schema` |
| **Prompts** | Pre-packaged prompt templates and workflows. | User or agent selects prompt to guide conversation. | `review_code`, `explain_architecture` |

---

## Tool Engineering Best Practices (Reducing Hallucinations)

1. **Self-Explanatory Parameter Names**:
   - Prefer `absolute_file_path` over `path` or `file`.
   - Prefer `timeout_seconds` over `timeout`.
2. **Explicit Enums over Free Strings**:
   - If an argument accepts only a few options, declare them as an `Enum` or `Literal["a", "b"]`.
3. **Docstring Structure**:
   - **Action**: What the tool does in 1-2 sentences.
   - **Arguments**: Description of each parameter with expected format and boundaries.
   - **Returns**: Explanation of output format.
   - **Errors**: Explicit list of errors the agent might encounter and how to recover.
4. **Actionable Error Reporting**:
   - Bad: `"Error: 404"`
   - Good: `{"status": "error", "error_code": "RESOURCE_NOT_FOUND", "message": "File 'foo.txt' does not exist.", "available_files": ["foo.py", "bar.txt"]}`

---

## Python FastMCP Server Reference Template

FastMCP provides the fastest, most declarative way to build production-ready MCP servers in Python:

```python
#!/usr/bin/env python3
"""
Custom MCP Server for Project Analysis & Agent Utilities.
Run with: python server.py
Inspect with: npx @modelcontextprotocol/inspector python server.py
"""

from mcp.server.fastmcp import FastMCP
from pydantic import BaseModel, Field
from typing import List, Optional
import os
import subprocess

mcp = FastMCP("AgentToolkit")

class GrepInput(BaseModel):
    pattern: str = Field(..., description="Regex pattern or literal string to search for.")
    directory: str = Field(default=".", description="Target directory path relative to workspace.")
    file_extension: Optional[str] = Field(default=None, description="Optional extension filter, e.g., '.py'.")

@mcp.tool()
def search_codebase(args: GrepInput) -> str:
    """
    Search for regex patterns across files in the target directory.
    Returns matched file lines with line numbers.
    """
    cmd = ["grep", "-rn", args.pattern, args.directory]
    if args.file_extension:
        cmd.extend(["--include", f"*{args.file_extension}"])
    
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        if res.returncode == 0:
            lines = res.stdout.strip().split("\n")
            if len(lines) > 50:
                return "\n".join(lines[:50]) + f"\n... [Truncated: {len(lines) - 50} more matches]"
            return res.stdout
        elif res.returncode == 1:
            return "No matches found."
        else:
            return f"Error executing search: {res.stderr}"
    except subprocess.TimeoutExpired:
        return "Search timed out after 15 seconds. Narrow your search pattern or target directory."

@mcp.resource("config://app-settings")
def get_app_settings() -> str:
    """Read the current environment application configuration."""
    return "ENV=development\nLOG_LEVEL=DEBUG\nAGENT_MAX_STEPS=20"

if __name__ == "__main__":
    mcp.run(transport="stdio")
```

---

## Testing & Verifying MCP Servers

1. **Interactive Testing via Inspector**:
   ```bash
   npx @modelcontextprotocol/inspector python /path/to/server.py
   ```
2. **Integrating into Herdr Agents**:
   - In Herdr, start agents with MCP configuration enabled.
   - For Claude Code: Add server to `~/.claude/settings.json` or project `claude.json`.
   - For OpenCode: Configure in `~/.config/opencode/opencode.json` under `mcpServers`.
   - For Codex: Add to `~/.codex/config.toml`.
