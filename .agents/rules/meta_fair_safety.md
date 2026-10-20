# Meta FAIR Agentic Safety Protocol

- **Source:** Meta FAIR (official source to be confirmed on the next quarterly review)
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Establishes safety boundaries and risk-aware agent behavior.

## Application in AptReceipt

- Never write to real user data from tests or tools; use in-memory stores and scratch copies.
- Stop and ask after three failed attempts on the same problem.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
