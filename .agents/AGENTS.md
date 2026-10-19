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
5. **Git Commit Standards**:
   - Format: `modify type @ scope: 'sentence description' - [tag]`
   - Keep atomic commits reflecting distinct units of work.
