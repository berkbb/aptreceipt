# AGENTS.md - Agent Constitution for AptReceipt

## Overview
`aptreceipt` is a modern, lightweight, native macOS application designed for apartment managers, building supervisors, and property administrators. It provides fast, multilingual, and elegant receipt creation, expense tracking, PDF export, printing, and archive management.

## Core Directives & Standards
All AI agents contributing to this codebase must adhere strictly to:
1. **Spec-Driven Development (SDD)**: Features, data schemas, and architectures must be documented in `.agents/context/` before or concurrently with implementation.
2. **Language Governance**: All agent-facing documentation, rules, contexts, and skills within `.agents/` MUST be written exclusively in **English**. User-facing application strings are localized in English (`en`), Turkish (`tr`), and Romanian (`ro`).
3. **macOS Native Quality**:
   - Utilize Swift 5.x / 6.x and AppKit / SwiftUI.
   - Maintain compatibility with macOS Sonoma (14.0+) and macOS Sequoia (15.0+).
   - Support both Dark Mode and Light Mode seamlessly with semantic system colors (`NSColor.textBackgroundColor`, `.accentColor`, `.secondary`, etc.).
   - Follow Apple Human Interface Guidelines (HIG) for window management, modals, keyboard shortcuts, and typography.
4. **Data Integrity & Privacy**:
   - All management data (residents, vendors, receipts, financial summaries) are stored locally on the user's machine (Application Support / UserDefaults).
   - Zero telemetry, zero unconsented network transmission.
   - Robust JSON export and import for user-controlled backups.
5. **One-to-One Localization (mandatory)**: Every user-facing text must exist in every supported language with the same meaning, whatever the language: screens, alerts, menus, generated documents, WhatsApp/email messages, generated data, file names, and number/currency/percent formats. This applies to `en`, `tr`, `ro` and to any language added later; a partial translation or an English fallback is a bug. Follow `.agents/rules/localization_parity.md`; its parity tests must pass before every commit.
6. **Git Commit Standards**:
   - Format: `modify type @ scope: 'sentence description' - [tag]`
   - Keep atomic commits reflecting distinct units of work.
