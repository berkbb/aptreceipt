# AGENTS.md — Agent Constitution for AptReceipt

- **Last updated:** 2026-10-20
- **Scope:** `aptreceipt` (AptReceipt for macOS)

## Overview
`aptreceipt` is a modern, lightweight, native macOS application designed for apartment managers, building supervisors, and property administrators. It provides fast, multilingual, and elegant receipt creation, expense tracking, PDF export, printing, and archive management.

This file is binding for every human and AI agent. Read it **first**, before touching code. Everything inside `.agents/` is written in English.

## Read order (agent workflow)
1. **Constitution** — this file.
2. **Context** — `.agents/context/`: `domain_wiki.md`, `code_graph_wiki.md` (symbols, call paths, impact map), `symbolic_memory_graph.md` (runtime states), `roadmap.md` (pending work only), `user_rejected_spec.md` (never re-propose), `reflexion_memory_log.md` (lessons), `prd.md`, plus plan files such as `settings_arhivar_alignment_plan.md`.
3. **Rules** — `.agents/rules/about_rules.md` is the index: domain rules (`localization_parity.md`, `ui_rules.md`, `math_rules.md`, `swift_macos_architecture.md`) and the 42 core AI standards with how each applies here.
4. **Skills** — `.agents/skills/`: test only through `sentinel_test_skill.md`; audit persisted data with `snapshot_audit_skill.md`. Only the repository's own scripts (`run_all_tests_mac.command`, `build_app.sh`, `release.sh`) may be executed.

## Core Directives & Standards
All AI agents contributing to this codebase must adhere strictly to:
1. **Spec-Driven Development (SDD)**: Features, data schemas, and architectures must be documented in `.agents/context/` before or concurrently with implementation (`rules/github_spec_kit.md`).
2. **Language Governance**: All agent-facing documentation, rules, contexts, and skills within `.agents/` MUST be written exclusively in **English**. User-facing application strings are localized in English (`en`), Turkish (`tr`), and Romanian (`ro`).
3. **macOS Native Quality**:
   - Utilize Swift 5.x / 6.x and AppKit / SwiftUI.
   - Maintain compatibility with macOS Sonoma (14.0+) and macOS Sequoia (15.0+).
   - Support both Dark Mode and Light Mode seamlessly with semantic system colors (`NSColor.textBackgroundColor`, `.accentColor`, `.secondary`, etc.).
   - Follow Apple Human Interface Guidelines (HIG) for window management, modals, keyboard shortcuts, and typography (`rules/ui_rules.md`).
4. **Data Integrity & Privacy**:
   - All management data (residents, vendors, receipts, financial summaries) are stored locally on the user's machine (Application Support / UserDefaults).
   - Zero telemetry, zero unconsented network transmission.
   - Robust JSON export and import for user-controlled backups.
   - Never run code that writes test or sample data against the real data store. Sample data goes into in-memory stores (`InMemoryDefaults`, `ReceiptArchiveStore(fileURL: nil)`), never into a backup-and-restore of real data. The screenshot generator (`--generate-screenshots`) works this way through `ScreenshotMode`; keep it so (see `reflexion_memory_log.md`, R-001).
5. **One-to-One Localization with a Dedicated File per Language (mandatory)**: Every user-facing text must exist in every supported language with the same meaning, whatever the language: screens, alerts, menus, generated documents, WhatsApp/email messages, generated data, file names, and number/currency/percent formats. Each language has its own file (`aptreceipt/<lang>.lproj/Localizable.strings`) with an identical key set; languages are never mixed in a shared file. This applies to `en`, `tr`, `ro` and to any language added later; a partial translation or an English fallback is a bug. Follow `.agents/rules/localization_parity.md`; its parity tests must pass before every commit.
6. **Git Commit Standards**:
   - Format: `modify type @ scope: 'sentence description' - [tag]`
   - Keep atomic commits reflecting distinct units of work; list several changes on separate lines.

## Agent memory architecture (TencentDB L0–L3) in this repository

| Tier | What it is here | Where |
| --- | --- | --- |
| L0 Conversation / execution logs | Session transcripts, build and test output | Not stored in the repo; lessons go to `context/reflexion_memory_log.md` |
| L1 Atom | Persisted parameters: `ReceiptSettingsStore` keys and `Defaults`, late-fee profile defaults, version numbers, update public key | `ReceiptSettingsStore.swift`, `LateFee.swift`, `project.pbxproj`, `Info.plist` |
| L2 Scenario | Runtime states: draft editing, preview/export, settings draft, update check, backup | `context/symbolic_memory_graph.md` |
| L3 Persona & governance | User preferences, invariants, redlines | This file, `rules/`, `context/user_rejected_spec.md` |

## Verification
Run `./run_all_tests_mac.command` after every change (`skills/sentinel_test_skill.md`). Never report a task as done with failing tests. After three failed attempts on the same problem, stop and ask the user. Check UI changes in the real running window.

## Documentation
Update `CHANGELOG.md` for user-facing changes and `README.md` when features or setup change. Remove finished items from `context/roadmap.md`; record user-rejected ideas in `context/user_rejected_spec.md`.
