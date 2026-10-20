# TencentDB Agent Memory Architecture

- **Source:** TencentDB Agent Memory architecture, as adopted in the global `CLAUDE.md` (4 memory assets, 2 core pillars, L0–L3 pyramid).
- **Version / date:** 2026-10-20
- **Last review:** 2026-10-20
- **Change summary:** Adopted for AptReceipt.

## Memory assets in this repository

| Asset | File |
| --- | --- |
| LLM-Wiki (domain knowledge) | `.agents/context/domain_wiki.md` (with `prd.md`) |
| Code-Graph (symbols, call paths, impact map) | `.agents/context/code_graph_wiki.md` |
| Reflexion (episodic lessons) | `.agents/context/reflexion_memory_log.md` |
| Symbolic short-term graph (runtime states) | `.agents/context/symbolic_memory_graph.md` |

Supporting: `roadmap.md` (pending work), `user_rejected_spec.md` (redlines) and plan files.

## L0–L3 pyramid

- **L0** — conversation and execution logs stay outside the repository; lessons go into `reflexion_memory_log.md`.
- **L1** — atomic parameters: `ReceiptSettingsStore` keys and `Defaults`, late-fee profile defaults, `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION`, `AptReceiptUpdatePublicEDKey`.
- **L2** — scenario states: draft editing, preview/export, settings draft, update check, backup (`symbolic_memory_graph.md`).
- **L3** — persona and governance: `.agents/AGENTS.md`, `.agents/rules/`, `user_rejected_spec.md`.

## Lifecycle

1. Read the assets before work; ground claims in them or in the code.
2. Update the code graph and the state graph when symbols, call paths or states change.
3. Add a reflexion entry after a mistake, a false pass or a non-obvious fix.
4. Remove finished roadmap items; record rejected ideas immediately.
