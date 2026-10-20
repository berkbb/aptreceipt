# MemGPT / Letta OS Memory Management Standard

- **Source:** Packer et al., "MemGPT", arXiv:2310.08560; Letta — https://www.letta.com/
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Manages limited context through tiered memory and controlled retrieval.

## Application in AptReceipt

- Durable knowledge lives in `.agents/context/`; working context is retrieved from there instead of being re-derived each session.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
