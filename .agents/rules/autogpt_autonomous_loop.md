# AutoGPT Continuous Autonomous Goal Loop Standard

- **Source:** AutoGPT — https://github.com/Significant-Gravitas/AutoGPT
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Guides iterative planning, execution, evaluation, and replanning.

## Application in AptReceipt

- Each loop ends with evaluation (tests, real-app check); replan when evaluation fails instead of repeating the same attempt.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
