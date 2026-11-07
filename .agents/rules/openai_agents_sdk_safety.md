# OpenAI Agents SDK Guardrails & Tool Safety Standard

- **Source:** OpenAI Agents SDK — https://github.com/openai/openai-agents-python
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-11-07)
- **Last review date:** 2026-11-07
- **Change summary:** Adopted for AptReceipt on 2026-10-20. Renamed from `openai_tool_calling_safety.md` on 2026-11-07; Swarm is retired; the Agents SDK is its successor.
- **Applicability:** Applies to agent work on this repository

## Purpose

Sets safeguards for validating and executing tool calls.

## Application in AptReceipt

- Confirm with the user before irreversible or outward-facing actions: deleting releases or tags, overwriting `docs/screenshots` with `--generate-screenshots`, resetting or importing over real data, pushing, publishing.
- Read before overwriting; prefer reversible steps; delete old artifacts only after their replacement is verified.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
