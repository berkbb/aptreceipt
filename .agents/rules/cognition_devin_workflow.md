# Cognition AI Devin Autonomous Software Engineering Standard

- **Source:** Cognition Devin documentation — https://docs.devin.ai/
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Structures autonomous engineering workflows from investigation through validation.

## Application in AptReceipt

- Investigate (read code, context and tests) → plan → implement in small steps → validate with `./run_all_tests_mac.command` and the real app → report.
- A change is not done until tests pass and user-facing behavior is checked.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
