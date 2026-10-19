# Changelog

All notable changes to this project will be documented in this file.

## [3.4.0] - 2026-10-19

### Added
- **GitHub Release Update Checker**: Built-in update detector querying GitHub Releases API (`berkbb/aptreceipt`), featuring semver comparator (`SemverCompare`), native macOS update alert with release details and one-click download, integrated into the macOS App Menu bar (`Check for Updates...`), Settings -> About tab, and the dedicated About window.
- **Multi-Country Late Payment Compensation Engine**: Replaced hardcoded Turkish KMK naming with a toggleable, multi-country late fee framework supporting Turkey (🇹🇷 KMK Md. 20/c), Romania (🇷🇴 Legea 196/2018 Art. 77), International (🌐 HOA Bylaws), and Custom (⚙️). Includes country-specific rates, payment due thresholds, grace periods, and receipt legal citations.
- **Customizable Receipt Footnotes & Neutral Templates**: Added editable per-country and custom legal footnotes rendered on official A4 receipts and stored with receipts and backups. Removed hardcoded KMK references in WhatsApp reminders and batch dues badges.
- **Extended Unit Test Suite**: Added comprehensive test cases for `SemverCompare`, `GitHubRelease` JSON decoding, and `LateFeeCountryProfile` legal citations and presets (12/12 unit tests passing).

### Changed
- Bumped marketing version to `3.4.0` (build `7`).

## [3.3.0] - 2026-10-19

### Added
- **KMK Art. 20 Late Fee Calculator (Gecikme Tazminatı)**: Integrated Turkish Property Law (KMK No. 634 Art. 20/c) late payment compensation calculator. Includes manual rate configuration in Settings with statutory presets (%3.0, %5.0 Kanuni, %7.5, %10.0), monthly due day picker, on-the-fly override on receipt creation, 1-click magic overdue detection, and dual-itemized official A4 receipt rendering with legal footnote.
- **Corporate Branding & Package Identity**: Updated bundle identifier to `com.babadogantech.aptreceipt` and official publisher branding to **Babadogan Tech and Edu** across all views, About sheet, license viewer, and system properties.
- **Comprehensive Unit Test Suite & Test Runner**: Added unit test suite in `aptreceiptTests` covering KMK late fee math, Codable serialization backward compatibility with legacy archives, currency models, and language localization, along with the `./run_all_tests_mac.command` executable runner.
- **Dark Mode & English Screenshot Suite**: Completely refreshed the 14-piece UI screenshot gallery in `docs/screenshots/` in native macOS Dark Mode and English localization.

### Changed
- Bumped marketing version to `3.3.0` (build `6`).

## [3.2.0] - 2026-10-19

### Added
- **Receipt Archive & History**: Persistent local receipt store with real-time search, category filtering (Income, Refund, Management Expense), instant past receipt viewer, and CSV tabular export.
- **Verifiable Dynamic QR Code**: CoreImage-powered anti-tamper QR code embedded directly into the official A4 receipt PDF and live preview, encoding verifiable summary payload.
- **WhatsApp & Email Quick Share**: One-click dispatch of personalized, trilingual receipt notifications and payment summaries via WhatsApp Web/Desktop and macOS Mail.
- **Full System Backup & Restore**: One-click JSON backup export and restore covering building configuration, residents directory, vendor list, expense services, and the entire receipt archive.
- **Resident Contact Directory**: Added phone number field for each flat in the Residents Directory to power instant WhatsApp messaging.
- **Spec-Driven Development (SDD)**: Bootstrapped agent constitution and living roadmap in `.agents/`.

### Added
- Complete English and Romanian language support with 1-to-1 accurate localization across all views, receipt documents, and dialogs.
- Dedicated native About window accessible from the macOS menu bar with app icon, version, publisher badge (**Babadogan Tech and Edu**), GitHub link, and interactive GNU GPL v3 license viewer.
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
- GNU General Public License v3.0 (GPL-3.0) with publisher Babadogan Tech and Edu.
- Real-time live receipt preview card on the main dashboard.
- Modern macOS interface with two-column layout, SF Symbols, and card components.
- Modernized Settings window with TabView.
- High-resolution receipt certificate preview with crystal-clear JPEG export.

### Changed
- Upgraded macOS deployment target to macOS 13.0 (Ventura) for modern SwiftUI support.
- Bumped marketing version to 3.1.0 (build 4).
- Refactored state management to robust `@MainActor` ViewModel architecture.
