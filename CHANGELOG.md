# Changelog

All notable changes to this project will be documented in this file.

## [3.2.0] - 2026-10-18

### Added
- Complete English and Romanian language support with 1-to-1 accurate localization across all views, receipt documents, and dialogs.
- Dedicated native About window accessible from the macOS menu bar with app icon, version, publisher badge (**berkbb**), GitHub link, and interactive GNU GPL v3 license viewer.
- Vector PDF and high-resolution JPEG export with official A4 itemized invoice format.
- Locale-aware smart filenames formatted with apartment name, document kind, flat number, and resident name.
- Modern macOS application icon set and asset catalog.
- Interactive read-only GNU GPL v3 license modal viewer accessible from both Preferences and the About window.
- Automatic theme switcher (System Default, Light, Dark) in Settings with immediate app-wide application.
- Dedicated native Settings window accessible from the macOS menu bar (`Cmd+,` / `Preferences`) and icon-only gear button.
- Revamped Settings window with tabbed navigation: Building, Residents, Appearance & Language, Signature, and About.
- High-resolution updated UI screenshot gallery in `docs/screenshots/`.

### Changed
- Bumped marketing version to `3.2.0` (build `5`).
- Updated `README.md` to English with updated screenshots and comprehensive feature documentation.

## [3.1.0] - 2026-10-18

### Added
- GNU General Public License v3.0 (GPL-3.0) with publisher berkbb.
- Real-time live receipt preview card on the main dashboard.
- Modern macOS interface with two-column layout, SF Symbols, and card components.
- Modernized Settings window with TabView.
- High-resolution receipt certificate preview with crystal-clear JPEG export.

### Changed
- Upgraded macOS deployment target to macOS 13.0 (Ventura) for modern SwiftUI support.
- Bumped marketing version to 3.1.0 (build 4).
- Refactored state management to robust `@MainActor` ViewModel architecture.
