# GitHub Spec Kit — Spec-Driven Development (SDD)

- **Source:** GitHub Spec Kit — https://github.com/github/spec-kit (documentation: https://github.github.com/spec-kit/)
- **Version / date:** referenced 2026-10-20
- **Last review:** 2026-10-20
- **Change summary:** Adopted as the working method for AptReceipt; templates are not vendored into the repository.

## How it applies here

| Phase | In this repository |
| --- | --- |
| Constitution | `.agents/AGENTS.md` and `.agents/rules/` |
| Specify / Clarify | `prd.md` for the product; agree behavior with the user and ask when scope is ambiguous |
| Plan | Multi-step work gets a plan file in `.agents/context/` (example: `settings_arhivar_alignment_plan.md`) with decisions and a progress log |
| Tasks | Phases of small, testable steps; one logical change per commit |
| Implement | Code against the plan; characterization tests first when behavior must not change |
| Analyze | Check the change against `code_graph_wiki.md` (impact map), the rules and the tests |
| Converge | Close the plan file with what actually shipped; record lessons in `reflexion_memory_log.md` |

Spec Kit templates and CLI commands are fetched from upstream on demand when the user asks for them; they are not copied into this repository.
