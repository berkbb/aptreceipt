# Mistral AI Function Calling, Agents SDK & Managed Agents Standard

- **Source:** Mistral AI function calling — https://docs.mistral.ai/capabilities/function_calling/; Agents SDK (`mistralai-agents`) & Managed Agents (public preview) — https://docs.mistral.ai/studio/agents/overview; the former Agents and Conversations API (`client.beta.agents`) is deprecated
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-11-07)
- **Last review date:** 2026-11-07
- **Change summary:** Adopted for AptReceipt on 2026-10-20. Renamed from `mistral_tool_binding.md` on 2026-11-07; the Agents API is deprecated; replaced by the Agents SDK and Managed Agents.
- **Applicability:** Applies to agent work on this repository

## Purpose

Defines reliable schemas and contracts for binding tools to agents.

## Application in AptReceipt

- Repository scripts are the tool contracts: their arguments and outputs are documented in `.agents/skills/`.
- Do not change a script's interface without updating every skill and document that calls it.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
