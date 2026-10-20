# Mistral AI Tool Binding Standard

- **Source:** Mistral AI function calling documentation — https://docs.mistral.ai/
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Defines reliable schemas and contracts for binding tools to agents.

## Application in AptReceipt

- Repository scripts are the tool contracts: their arguments and outputs are documented in `.agents/skills/`.
- Do not change a script's interface without updating every skill and document that calls it.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
