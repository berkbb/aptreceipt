# Uber Agentic AI Detection and Response (ADR)

- **Source:** Uber ADR framework (see `uber_adr_research_paper.md`)
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Not applicable to the product (reason below)

## Purpose

Enterprise agentic security framework: observability sensors, pre-deployment red-teaming, two-tier detection, ADR-Bench for MCP-based agents.

## Application in AptReceipt

- AptReceipt ships no agent. For agents working on the repository, the security rules in `owasp_agentic_security.md` and `openai_tool_calling_safety.md` apply.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
