# AWS Bedrock Agentic Governance Standard

- **Source:** Amazon Bedrock documentation — https://docs.aws.amazon.com/bedrock/
- **Version / publication date:** as listed in the global `CLAUDE.md` core standards (reviewed 2026-10-20)
- **Last review date:** 2026-10-20
- **Change summary:** Adopted for AptReceipt on 2026-10-20.
- **Applicability:** Applies to agent work on this repository

## Purpose

Covers operational controls, observability, and governance for agents.

## Application in AptReceipt

- Every agent change is traceable: atomic commits in the agreed format, CHANGELOG entries, plan files.
- Releases go only through the repository's release script.

## Rollback

Delete this file and its row in `about_rules.md`. No code depends on it.
