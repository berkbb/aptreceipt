# Changelog

All notable changes to this project will be documented in this file.

## [3.2.0] - 2026-10-18

### Added
- Complete English language support with 1-to-1 accurate localization across all views and dialogs.
- Automatic theme switcher (System Default, Light, Dark) in Settings with immediate app-wide application.
- Dedicated native Settings window accessible from the macOS menu bar (`Cmd+,` / `Preferences`).
- Language selector (System Default, Turkish, English) in Settings.
- Revamped Settings window with tabbed navigation: Building, Residents, Appearance & Language, Signature, and About.
- Refined About section with updated branding, version 3.2.0, publisher berkbb, and GPL-3.0 license.
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
