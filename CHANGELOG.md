# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed
- **WhatsApp phone numbers**: Numbers saved in local form (`0532 …`, `0722 …`) opened a wrong or missing chat because wa.me needs the international form. Turkish and Romanian buildings now complete them with `90` / `40`; numbers that already start with `+` or `00` are kept.
- **WhatsApp and email text**: A `&`, `+`, `=` or `?` in a building name or note cut the message short or turned into a space; the whole text now arrives. The email body no longer shows WhatsApp's `*bold*` asterisks.
- **WhatsApp receipt message**: Amounts use the same format as the printed receipt (e.g. `₺2.300,00` instead of `₺ 2300.00`), a late fee is shown as dues plus late fee under the total, and empty description, flat number or manager lines are left out.
- **WhatsApp payment reminder**: Greets the owner by name when known, formats the dues, late fee and total like the receipt, and writes the rate per language (`%5,0`, `5.0%`).
- **Cash summary month picker**: Periods were listed exactly as stored on each receipt, so a month created in another app language stayed untranslated ("October 2026" in Turkish), the same month could appear twice with its totals split, and the list was sorted alphabetically. Periods are now recognized in Turkish, English and Romanian, shown in the current language, merged per month and sorted newest first; paid/unpaid status, reminders, the bulletin title and the PDF file name use the same period. Unrecognized period texts are still listed as written.
- **Amounts on every screen** (cash summary, archive, main screen, live preview, bulletin PDF) were written as `1750.00 ₺` in all languages; they now use the same per-language format as the printed receipt (`₺1.750,00`, `₺1,750.00`, `1.750,00 Lei`).
- **Percentages and late-fee rates** were written Turkish-style everywhere (`%16.7 Paid`, `Late Fee (%5.0 × 3 Months)`); they now follow the language: `%16,7 Ödendi`, `16.7% Paid`, `16,7%` and `Gecikme Tazminatı (%2,5 × 3 Ay)`, `Late Fee (5.0% × 3 Months)`.
- **Batch dues receipts** always stored a Turkish description and, for flats without an owner, a Turkish recipient (`… Sakini (Daire 5)`); both now use the app language.
- **Bulletin board PDF**: the footer tagline was always Turkish, and the suggested file name was always `…_Mali_Pano_Raporu_…` with `Apartman` as the fallback building name; both now use the app language.
- **Receipt footer version**: Receipts printed `AptReceipt v3.3.0` regardless of the installed version; they now show the real version.
- The late fee on the main screen was still written as `+1750.00 ₺`, and the update download progress as `42%` in every language; both now use the per-language format.
- **Receipt preview footer**: The buttons now sit in two rows (share actions, then Close / JPEG / PDF), so every label fits in all three languages, including when an invoice is attached.

### Tests
- **Trilingual parity checks** keep Turkish, English and Romanian one to one: every catalog string is really translated (only a short, explicit allowlist may equal English), every key used in code exists in all three languages, no view contains hardcoded text, no screen uses a fixed number format, and every text the code builds per language (WhatsApp messages, legal notes, amount in words, file names, sample data, option titles) differs in each language.

## [3.5.0] - 2026-10-20

### Added
- **App update section in Settings → About**: installed version and build, last check result (with the failure kind), last-checked time, **Check Now** with the result shown inline, and a **Download** button when a newer release exists.
- **Check for updates at launch** (Settings → About): off by default; when on, a newer release is announced with the usual update alert.
- **Reset Settings…** (Settings → About): asks for confirmation, then restores language, theme, currency, late-fee configuration and the launch update check. Building details, residents, phones, vendors, services, receipts, logo, signature and the receipt number are kept.

### Changed
- **Settings window** follows the Arhivar standard: toolbar tabs in one 760 pt wide window that keeps its size and position when switching tabs and grouped native sections with headers on every tab. All existing settings, actions and validations are unchanged, and edits on all tabs still form one draft committed by **Save & Close** or discarded by **Cancel**. The language and currency cards became pickers with the same immediate behavior; the theme cards became a segmented control.
- **Update check errors**: A failed update check now explains what went wrong instead of always saying "check your internet connection": no internet connection, timeout, GitHub unreachable, no public release yet (HTTP 404), rate limit reached, GitHub server error, or an unreadable response. Messages are translated into English, Turkish and Romanian.
- **About window**: Redesigned to match Arhivar: large icon, name, version and build read from the app bundle (previously hardcoded as 3.3.0), tagline, publisher and license credit, glass link buttons (babadogan.net, GitHub, Check for Updates, License) and a copyright line with the current year. The window now sizes itself to its content and hides its title bar. The Settings → About tab shows the same content above its update and reset sections.
- **License viewer**: Shows the full, unmodified GPL-3.0 text from the repository `LICENSE` instead of a shortened, edited excerpt. It stays read-only, and a test keeps it in sync with `LICENSE`.
- Bumped marketing version to `3.5.0` (build `11`).

### Fixed
- **License viewer** opened twice (in the About window and in the main window) because both listened to one shared flag; it now opens only in the window whose button was pressed.
- Picking a language on a sample building no longer also saves unrelated pending edits from other Settings tabs; only the switched sample data is stored at once.
- The statutory late-fee rate chip showed its rate twice ("%5.0 (%5.0 (Statutory))"); it now reads "%5.0 (Statutory)".
- The per-flat clear button in Residents showed the "Clear All" tooltip; it now has its own text.

## [3.4.3] - 2026-10-19

### Fixed
- **Late fee grand total**: Receipts with a late fee applied computed the grand total as `(base + fee × 100) / 100` due to an operator-precedence error (e.g. 2000 + 300 late fee was saved as 320.00 instead of 2300.00). Late fee and total calculations now go through a single `LateFeeCalculator`.

### Changed
- Split the 4,900-line `ViewController.swift` into per-feature files (`L10n.swift`, `ReceiptSettingsStore.swift`, `MainScreen.swift`, `MainScreenViewModel.swift`, `ReceiptModels.swift`, `LateFee.swift`, and one file per sheet/view). No behavior changes.
- Moved all 375 UI strings from inline `tr("EN", "TR", "RO")` calls into an Xcode String Catalog (`aptreceipt/Localizable.xcstrings`). `L10n` looks keys up in the bundle of the in-app language, so the language picker keeps working independently of the system language. Added a test that every key exists in every language with matching format specifiers.
- Replaced the late fee unit test that re-implemented the formula inside the test with tests that exercise `LateFeeCalculator` and `MainScreenViewModel` directly.
- Bumped marketing version to `3.4.3` (build `10`).

## [3.4.2] - 2026-10-19

### Added
- **GitHub Release Update Checker**: Built-in update detector querying GitHub Releases API (`berkbb/aptreceipt`), featuring semver comparator (`SemverCompare`), native macOS update alert with release details and one-click download, integrated into the macOS App Menu bar (`Check for Updates...`), Settings -> About tab, and the dedicated About window.
- **In-App DMG Update Download**: **Download Update** fetches the release DMG into `~/Downloads` with a progress window and cancel button, verifies its SHA-256 checksum (`SHA256SUMS.txt`) and Ed25519 signature, and opens it for drag-to-Applications installation. Release notes are shown in a scrollable view inside the update alert. Falls back to the GitHub release page when no DMG is attached, and explains how to allow the DMG when Gatekeeper blocks opening it.
- **Signed Updates (Ed25519)**: Release DMGs are signed with an Ed25519 (EdDSA) key and published with a detached `.sig` file. The app embeds the public key (`AptReceiptUpdatePublicEDKey` in `Info.plist`) and discards any downloaded update whose signature is missing or invalid.
- **Multi-Country Late Payment Compensation Engine**: Generalized late fee calculation with a master toggle switch and dedicated country/jurisdiction profiles supporting Turkey (🇹🇷 KMK Md. 20/c statutory 5%), Romania (🇷🇴 Legea 196/2018 Art. 77 up to 0.2%/day with 30-day grace period), International (🌐 HOA Bylaws), and Custom (⚙️). Includes country-specific rates, payment due thresholds, grace periods, and receipt legal citations.
- **Customizable Receipt Footnotes & Neutral Templates**: Added editable per-country and custom legal footnotes rendered on official A4 receipts and stored with receipts and backups. Removed hardcoded KMK references in WhatsApp reminders and batch dues badges.
- **Corporate Branding & Package Identity**: Updated bundle identifier to `com.babadogantech.aptreceipt` and official publisher branding to **Babadogan Tech and Edu** across all views, About sheet, license viewer, and system properties.
- **Comprehensive Unit Test Suite & Test Runner**: Added unit test suite in `aptreceiptTests` covering semver comparisons, GitHub release JSON decoding, DMG/checksum/signature asset handling and Ed25519 verification, multi-country late fee presets, Codable serialization backward compatibility with legacy archives, currency models, and language localization, along with the `./run_all_tests_mac.command` executable runner (18/18 unit tests passing).
- **Dark Mode & English Screenshot Suite**: Completely refreshed the 14-piece UI screenshot gallery in `docs/screenshots/` in native macOS Dark Mode and English localization.

### Changed
- Bumped marketing version to `3.4.2` (build `9`).
- `build_app.sh` now ad-hoc signs the app and produces a DMG (bundling `LICENSE.txt` and an install/Gatekeeper `README.txt`) and `SHA256SUMS.txt` in `dist/`.
- Added `release.sh` to publish GitHub releases: it Ed25519-signs and verifies the DMG and checks that the keychain key matches the app's public key. Added `scripts/update_signing.swift` to generate, import, and use the signing key (stored in the login keychain, with a backup copy in the gitignored `.secrets/` folder).

### Fixed
- Added the `com.apple.security.network.client` sandbox entitlement so the GitHub update checker can reach the Releases API, and `com.apple.security.files.downloads.read-write` so updates can be saved to `~/Downloads`.

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
