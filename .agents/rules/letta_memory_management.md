# Letta Memory Management Standard

- **Source:** Letta (formerly MemGPT; Packer et al., 2023, arXiv:2310.08560) — https://github.com/letta-ai/letta-code
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-11-07)
- **Last review date:** 2026-11-07
- **Change summary:** Adopted for AptReceipt on 2026-10-20. Renamed from `memgpt_os_memory.md` on 2026-11-07; MemGPT is the retired name of Letta.
- **Applicability:** Applies to agent work on this repository

## Purpose

Manages limited context through tiered memory and controlled retrieval.

## Application in AptReceipt

- Durable knowledge lives in `.agents/context/`; working context is retrieved from there instead of being re-derived each session.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
