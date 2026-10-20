# LangChain/LangGraph Cyclic State Machine Standard

- **Source:** LangGraph — https://langchain-ai.github.io/langgraph/
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Models agent workflows as explicit, stateful, recoverable cycles.

## Application in AptReceipt

- Runtime states of the app are modeled in `.agents/context/symbolic_memory_graph.md`.
- Long tasks are split into phases with a recorded status so work can resume after an interruption.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
