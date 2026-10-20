# Microsoft AutoGen Multi-Agent Orchestration Protocol

- **Source:** Microsoft AutoGen — https://microsoft.github.io/autogen/
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Coordinates roles, communication, and handoffs among agents.

## Application in AptReceipt

- Sub-agents or parallel sessions get a self-contained brief: files, scope, what "done" means, files they must not touch.
- Two writers never edit the same files at the same time; the main session reviews and verifies their results before reporting.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
