# IBM Granite Enterprise Agent Standard

- **Source:** IBM Granite — https://www.ibm.com/granite
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Applies enterprise-grade security, reliability, and accountability requirements.

## Application in AptReceipt

- Signing keys, secrets and update public keys are never changed or committed by agents.
- Backward compatibility of stored data is checked with `.agents/skills/snapshot_audit_skill.md`.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
