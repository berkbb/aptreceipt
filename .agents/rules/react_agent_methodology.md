# Google Research ReAct Methodology

- **Source:** Yao et al., "ReAct", arXiv:2210.03629
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Interleaves reasoning, actions, and observations to support evidence gathering, planning, and recovery.

## Application in AptReceipt

- Gather evidence before changing code (read, search, run); after each action, check the observation (test output, screenshot) before the next step.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
