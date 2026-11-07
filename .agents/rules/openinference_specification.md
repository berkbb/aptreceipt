# Arize AI OpenInference Specification

- **Source:** OpenInference — https://github.com/Arize-ai/openinference
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-11-07)
- **Last review date:** 2026-11-07
- **Change summary:** Adopted for AptReceipt on 2026-10-20. Absorbed the verification-reporting directive from the retired `grok_reasoning_trace.md` on 2026-11-07 (that file had no primary source).
- **Applicability:** Not applicable to the product (reason below)

## Purpose

Defines interoperable observability traces for LLM, agent, tool, retrieval, guardrail, and evaluation operations.

## Application in AptReceipt

- AptReceipt runs no LLM operations and sends no telemetry (zero-telemetry rule).
- Reports state what was verified and what was not. Change summary (2026-11-07): absorbed this directive from the retired `grok_reasoning_trace.md`, which had no primary source.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
