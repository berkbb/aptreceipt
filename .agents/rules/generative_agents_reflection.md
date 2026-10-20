# Stanford Generative Agents Memory Reflection Standard

- **Source:** Park et al., "Generative Agents", arXiv:2304.03442
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Converts accumulated experiences into higher-level memory insights.

## Application in AptReceipt

- Mistakes and non-obvious fixes become entries in `.agents/context/reflexion_memory_log.md` with a lesson.
- Recurring lessons are promoted into rules (`.agents/rules/`) or tests.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
