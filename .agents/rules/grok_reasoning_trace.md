# xAI Grok Reasoning Trace Protocol

- **Source:** xAI (official source to be confirmed on the next quarterly review)
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Maintains concise, auditable decision and execution traces.

## Application in AptReceipt

- Decisions that change behavior are recorded where they live: plan files in `.agents/context/`, `CHANGELOG.md`, commit messages.
- Reports state what was verified and what was not.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
