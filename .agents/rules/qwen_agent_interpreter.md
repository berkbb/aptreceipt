# Alibaba Qwen-Agent Code Interpreter Standard

- **Source:** Qwen-Agent — https://github.com/QwenLM/Qwen-Agent
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Governs isolated code execution, input handling, and result reporting.

## Application in AptReceipt

- Ad-hoc helper scripts run from a scratch directory outside the repository and are never committed.
- Temporary diagnostic code in the app is removed before committing; results are reported with their exact output.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
