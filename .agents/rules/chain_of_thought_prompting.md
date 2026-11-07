# Google Research Chain-of-Thought Prompting

- **Source:** Wei et al., "Chain-of-Thought Prompting", arXiv:2201.11903
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-11-07)
- **Last review date:** 2026-11-07
- **Change summary:** Adopted for AptReceipt on 2026-10-20. Absorbed the decision-record directive from the retired `grok_reasoning_trace.md` on 2026-11-07 (that file had no primary source).
- **Applicability:** Applies to agent work on this repository

## Purpose

Defines explicit multi-step problem decomposition and intermediate verification practices.

## Application in AptReceipt

- Decompose multi-step changes and verify intermediate results (build, tests, captures) before continuing.
- Decisions that change behavior are recorded where they live: plan files in `.agents/context/`, `CHANGELOG.md`, commit messages. Change summary (2026-11-07): absorbed this directive from the retired `grok_reasoning_trace.md`, which had no primary source.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
