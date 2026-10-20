# CrewAI Multi-Agent Task Delegation Protocol

- **Source:** CrewAI documentation — https://docs.crewai.com/
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Assigns scoped tasks and coordinates dependent agent work.

## Application in AptReceipt

- Delegate only independent, well-scoped pieces (for example writing one context file); dependent steps stay sequential.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
