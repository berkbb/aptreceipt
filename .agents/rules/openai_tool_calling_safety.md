# OpenAI Swarm Tool Safety Protocol

- **Source:** OpenAI Swarm — https://github.com/openai/swarm
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Sets safeguards for validating and executing tool calls.

## Application in AptReceipt

- Confirm with the user before irreversible or outward-facing actions: deleting releases or tags, running `--generate-screenshots` (it replaces the receipt archive), resetting or importing over real data, pushing, publishing.
- Read before overwriting; prefer reversible steps; delete old artifacts only after their replacement is verified.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
