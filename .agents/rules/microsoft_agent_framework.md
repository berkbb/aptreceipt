# Microsoft Agent Framework Multi-Agent Orchestration Standard

- **Source:** Microsoft Agent Framework — https://github.com/microsoft/agent-framework
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-11-07)
- **Last review date:** 2026-11-07
- **Change summary:** Adopted for AptReceipt on 2026-10-20. Renamed from `multi_agent_orchestration.md` on 2026-11-07; AutoGen is archived; the Microsoft Agent Framework is its successor.
- **Applicability:** Applies to agent work on this repository

## Purpose

Coordinates roles, communication, and handoffs among agents.

## Application in AptReceipt

- Sub-agents or parallel sessions get a self-contained brief: files, scope, what "done" means, files they must not touch.
- Two writers never edit the same files at the same time; the main session reviews and verifies their results before reporting.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
