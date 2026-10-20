# Hugging Face Actions-as-Code Standard (CodeAgent)

- **Source:** smolagents — https://github.com/huggingface/smolagents
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Standardizes executable code actions over raw JSON tool calls for deterministic execution and error recovery.

## Application in AptReceipt

- Large mechanical edits (for example moving ~200 texts into language files) are done with a reviewed, dry-run-first script, not by hand; the dry run must report zero problems before applying.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
