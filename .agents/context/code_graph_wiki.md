# AptReceipt Code Graph Wiki

- **Last updated:** 2026-10-20
- **Scope:** AptReceipt (aptreceipt)
- **Layout:** sources in `aptreceipt/`, unit tests in `aptreceiptTests/aptreceiptTests.swift`, runner `./run_all_tests_mac.command`.

## Symbol index (per file)

| File | Main symbols | Responsibility |
| --- | --- | --- |
| `AppDelegate.swift` | `AptReceiptApp` (`@main`), `ScreenshotMode`, `AppDelegate`, `AboutWindowView`, `AboutContentView`, `AppInfo`, `AboutWindowManager`, `SettingsWindowManager`, `SettingsTabViewController`, `MenuBarManager` | App scene and commands, launch, screenshot generator, About and Settings windows, localized menu bar |
| `AppSettingsEnums.swift` | `AppLanguage`, `AppTheme`, `AppCurrency` (`default(for:)`) | Language, theme and currency options |
| `ReceiptModels.swift` | `VendorRecord`, `ExpenseServicePreset`, `ValidationError`, `ReceiptKind`, `ReceiptDraft`, `SystemBackupPackage` | Core Codable models and the backup format |
| `ReceiptArchiveStore.swift` | `ReceiptRecord`, `ReceiptArchiveStore.shared`, `init(fileURL:)`, `defaultFileURL` | Archive record and JSON persistence (`receipts_archive.json`); `fileURL: nil` keeps it in memory |
| `ReceiptSettingsStore.swift` | `ReceiptSettingsStore.shared`, `Defaults`, `Keys`, `InMemoryDefaults` | UserDefaults-backed settings, owners, phones, logo, signature, backup export/import, preference reset; in-memory defaults for tests and screenshot runs |
| `LateFee.swift` | `LateFeeCountryProfile`, `LateFeeCalculator` | Profile defaults, footnotes, legal notices; fee math |
| `SampleData.swift` | `SampleData.defaults(for:)` | Per-language sample building, residents, vendors, services |
| `Extensions.swift` | `AppFormat`, `ReceiptPeriod`, `Date.monthYearString`, `Date.dayMonthYearString`, `Notification.Name.appLanguageDidChange` / `.settingsDidSave` | Formatting, period parsing, notifications |
| `SharingHelpers.swift` | `QRCodeGenerator`, `WhatsAppShareHelper` | QR bitmap (whole pixels per module, 4-module quiet zone, level L, size from `pointsPerModule`); WhatsApp/email URLs and messages |
| `ReceiptVerification.swift` | `ReceiptVerificationCode`, `ReceiptVerificationKeyStore`, `ReceiptSerial`, `ScannedReceiptVerification`, `ReceiptArchiveComparison` | Offline receipt verification: HMAC code over the normalized QR text (Crockford Base32, pinned by `testVerificationCodeIsPinnedAndIgnoresLayoutOnly`), installation keys in `Application Support/aptreceipt/receipt-verification-keys` (0600), in memory for tests and screenshot runs; receipt numbers (`TAH-1042`) per kind and language; parsing a scanned QR text and comparing it with the archive |
| `ReceiptVerificationView.swift` | `ReceiptQRReader`, `ReceiptVerificationWindowManager`, `ReceiptVerificationView`, `ReceiptSlipView` | Verify Receipt window: Vision QR reading from images and PDFs, drop/choose/paste input, POS-style slip with status stamp and archive result |
| `L10n.swift` | `L10n` (`resolvedLanguage`, `locale`, private `tr(_:)`) | Lookup in the per-language `Localizable.strings` |
| `MainScreen.swift` | `MainScreen` | Main window: receipt form, live preview, header buttons, sheets |
| `MainScreenViewModel.swift` | `MainScreenViewModel` | Form state, late-fee math, invoice import, `createReceipt` |
| `LiveReceiptPreview.swift` | `LiveReceiptPreview`, `Default2DBuildingLogo` | On-screen preview next to the form |
| `ReceiptViewController.swift` | `NumberToWords`, `buildExportFileName`, `sanitizeForFileName`, `ReceiptPreviewSheet`, `ReceiptDocumentView`, `NSImage.writeJPEG`, `InvoiceOCRParser`, `ParsedInvoiceResult`, `InvoiceAttachmentManager` | A4 document, PDF/JPEG export, sharing, OCR, attachments |
| `ReceiptArchiveSheet.swift` | `ReceiptArchiveSheet` | Archive browsing, filters, CSV export |
| `ApartmentFinancialReportSheet.swift` | `ApartmentFinancialReportSheet` | Cash summary, dues status, reminders, transactions, bulletin export |
| `ApartmentBulletinBoardView.swift` | `ApartmentBulletinBoardView` | A4 bulletin board notice |
| `BatchDuesGeneratorSheet.swift` | `BatchDuesGeneratorSheet` | Batch income receipts into the archive |
| `PreferencesViewController.swift` | `SettingsTab`, `SettingsView`, `SettingsViewModel` | Settings pages and the draft model |
| `GitHubUpdateChecker.swift` | `GitHubRelease`, `GitHubReleaseAsset`, `SemverCompare`, `UpdateCheckStatus`, `UpdateCheckFailure`, `GitHubUpdateChecker.shared`, `UpdateChecksums`, `UpdateSignature`, `UpdateDownloadError`, `UpdateFileDownloader`, `UpdateDownloadWindowManager`, `UpdateDownloadProgressView` | Release check, download, verification |
| `LicenseViewerSheet.swift` | `LicenseViewerSheet.licenseText` | Verbatim copy of `LICENSE` (GPL v3) |
| `aptreceiptTests.swift` | `aptreceiptTests` | Unit, parity and screenshot-isolation tests |

## Key call paths

**Launch**
1. `AptReceiptApp` -> `WindowGroup` -> `MainScreen(settings: ReceiptSettingsStore.shared)`; `.commands` add About, Check for Updates, Settings (Cmd+,) and Help.
2. `AppDelegate.applicationDidFinishLaunching`: when `ScreenshotMode.isActive` (`--generate-screenshots`), it calls `generateScreenshots()` and terminates; in that process `ReceiptSettingsStore.shared` and `ReceiptArchiveStore.shared` are in memory. Otherwise it runs `applyTheme`, `MenuBarManager.install`, and `GitHubUpdateChecker.checkForUpdates(userInitiated: false, alertWhenAvailable: true)` if `checkUpdatesAtLaunch` is on.

**Receipt creation and export**
1. `MainScreen.init` -> `MainScreenViewModel.syncWithSettings`. Form edits drive `LiveReceiptPreview` (`grandTotalAmount`, `calculatedLateFee`, `effectiveLateRate`).
2. Create button -> `MainScreenViewModel.createReceipt` -> builds `ReceiptDraft` -> `ReceiptArchiveStore.shared.add(draft:)` -> `settings.seqNumber = sequence + 1` -> `previewDraft` is set.
3. `.sheet(item: $viewModel.previewDraft)` -> `ReceiptPreviewSheet` -> `ReceiptDocumentView` (`documentSerialFormatted`, `NumberToWords`, `QRCodeGenerator`, footnote).
4. `saveReceiptPDF`: `NSSavePanel` (`buildExportFileName`) -> `ImageRenderer` into a `CGContext` PDF at 595x842 -> `PDFDocument` appends the invoice attachment. `saveReceiptImage`: renders at 2x -> `NSImage.writeJPEG`.
5. `shareWhatsApp` / `shareEmail` -> `WhatsAppShareHelper.receiptSummary` -> `shareURL` / `emailURL` -> `NSWorkspace.open`.

**Archive and reports**
- `ReceiptArchiveStore`: `add`, `remove`, `replaceRecords`, `clearAll` each call `save()` (atomic JSON write). `load()` runs in `init`.
- `ReceiptArchiveSheet` -> `record.toDraft()` -> `onSelectDraft` -> `previewDraft`, which reopens the preview without archiving again.
- `ApartmentFinancialReportSheet` -> `ReceiptPeriod` keys -> `flatDuesStatusList` -> `WhatsAppShareHelper.paymentReminder`; `exportBulletinBoardPDF` -> `ApartmentBulletinBoardView`.
- `BatchDuesGeneratorSheet.executeBatchGeneration` -> `ReceiptArchiveStore.shared.add` for each flat -> `settings.seqNumber` -> `onComplete` -> `updateLiveFromSettings`.

**Settings**
1. `SettingsWindowManager.show(settings:tab:)` creates a fresh `SettingsTabViewController` on every call, so every opening starts with a new draft.
2. `SettingsTabViewController` owns one `SettingsViewModel` (`draft`) and hosts one `SettingsView` page per `SettingsTab` in an `NSHostingController`. All pages share the draft. `fitWindow` keeps the top-left corner fixed.
3. `SettingsView.onAppear` -> `viewModel.load(from:)` runs once (`isLoaded`). Save & Close -> `SettingsViewModel.save(to:)` -> on success posts `.settingsDidSave` and calls `onClose` (`SettingsWindowManager.close`). Cancel -> `close()` with no write.
4. `MainScreen` receives `.settingsDidSave` and `settings.objectWillChange` -> `MainScreenViewModel.updateLiveFromSettings`.
5. Language change -> `ReceiptSettingsStore.language.didSet` writes `AppleLanguages` and posts `.appLanguageDidChange` -> `MenuBarManager.updateMenuBar`; `SettingsTabViewController.applyTitles`.

**Update checker**
- `checkForUpdates` -> `URLSession` GET `releases/latest` -> `SemverCompare.isRemoteNewer(remote:local: AppInfo.version)` -> `status` (`.updateAvailable` / `.upToDate` / `.failed` via `UpdateCheckFailure`) and alerts when user-initiated.
- `downloadUpdate` -> `fetchExpectedDigest` (`UpdateChecksums.parse`) -> `fetchSignature` -> `UpdateFileDownloader.download` -> `UpdateChecksums.sha256` -> `UpdateSignature.isValid` -> `moveToDownloads` -> open the DMG -> completed or failed alert.

## Impact map

| If you change... | Also check / update... |
| --- | --- |
| Any user-facing text | Add the key to all three of `en.lproj`, `tr.lproj` and `ro.lproj` `Localizable.strings` (same keys and format specifiers, real translations) -> an `L10n` property using `tr("key")` -> no literal words in views -> parity tests (`testStringCatalogHasEveryKeyInEveryLanguage`, `testEveryKeyUsedInCodeExistsInAllThreeLanguages`, `testEveryCatalogStringIsReallyTranslated`, `testNoHardcodedTextInViews`) |
| Text built in code per language (`switch l10n.resolvedLanguage`) | One branch per language: `receiptSummary`, `paymentReminder`, profile footnotes and legal notices, `SampleData`, serial prefixes, `buildExportFileName`, `NumberToWords` -> `testGeneratedTextsExistInAllThreeLanguages`, `testEnumTitlesExistInAllThreeLanguages` |
| `ReceiptDraft` / `ReceiptRecord` fields | `CodingKeys` and `decodeIfPresent` defaults in both types, `ReceiptRecord.init(draft:)` and `toDraft()`, existing `receipts_archive.json` files, `SystemBackupPackage.archivedReceipts` -> `testReceiptDraftBackwardCompatibilityWithLegacyJSON`, `testReceiptDraftCodableRoundTrip` |
| `SystemBackupPackage` | Add new fields as optionals with defaults; update `exportSystemBackup` and `importSystemBackup` -> `testSystemBackupPackageCodable`, `testSystemBackupPackageWithCountryProfile` |
| A `ReceiptSettingsStore` field or key | `Keys`, the read in `init`, `Defaults` and `resetPreferencesToDefaults()` (preferences only), `SettingsViewModel.load` / `save`, the backup package -> `testPreferenceResetRestoresPreferencesAndKeepsAllData` |
| `LateFeeCountryProfile` | Rate, due day, grace period, presets, footnote and legal notice in all three languages; `SettingsViewModel.selectCountryProfile`; `setLateFeeCountryProfile`; redline in `user_rejected_spec.md` -> `testLateFeeCountryProfiles` |
| `LateFeeCalculator` | `MainScreenViewModel.calculatedLateFee` / `grandTotalAmount`, `paymentReminder`, the live preview and the document totals -> `testLateFeeCalculatorFee`, `testMainScreenViewModelLateFeeTotals` |
| Period format (`monthYearString`, "MMMM yyyy") | The `ReceiptPeriod` parsers, the report's period picker, dues status and bulletin title -> the `testReceiptPeriod*` tests |
| Displayed amounts or percentages | Use `AppFormat` only -> `testNoFixedNumberFormatsOnScreen`, `testAmountsUseTheAppLanguageFormat` |
| `ReceiptDocumentView` layout | It is reused by the preview, PDF export, JPEG export and screenshot generator; A4 size is 595x842 in light mode |
| `SettingsTab` cases | `title`, `iconName`, L10n tab keys, `SettingsTabViewController`, `show(tab:)` callers, the screenshot generator -> `testSettingsTabsStayCompleteAndLocalized`, `testEverySettingsTabUsesTheWidestWidth` |
| Version bump | `MARKETING_VERSION` (now 3.6.0) and `CURRENT_PROJECT_VERSION` (now 13) in the app target's Debug and Release configurations in `aptreceipt.xcodeproj/project.pbxproj` -> a `## [x.y.z]` section in `CHANGELOG.md` (`release.sh` takes the release notes from it and stops when it is missing) -> `AppInfo.version` is shown on receipts and in About, and is compared with tag `v<version>` |
| Update signing key | `AptReceiptUpdatePublicEDKey` in `Info.plist`, `release.sh`, `scripts/update_signing.swift` -> `testBundledUpdatePublicKeyIsValid`, `testUpdateSignatureVerification` |
| `LICENSE` | `LicenseViewerSheet.licenseText` -> `testLicenseViewerMatchesRepositoryLicense` |
| Screenshot generator (`--generate-screenshots`) | Keep every store it uses in memory: `ScreenshotMode.settingsDefaults` / `archiveFileURL`, `ReceiptSettingsStore(defaults: InMemoryDefaults())`, and the guard that stops the run when `ReceiptArchiveStore.shared.fileURL` is set -> "Screenshot Run Isolation" tests. It seeds the two sample receipts first and writes PNGs to `docs/screenshots` under the current directory. |
| `ReceiptArchiveStore` / `ReceiptVerificationKeyStore` | Tests use `fileURL: nil` (memory) or a temporary file, never `.shared`; pass them to `exportSystemBackup` / `importSystemBackup` and to `ReceiptDocumentView(verificationKeys:)` |
| `.settingsDidSave` / `.appLanguageDidChange` | `MainScreen.updateLiveFromSettings`, `MenuBarManager`, `SettingsTabViewController` titles |
| Receipt QR text (`ReceiptDocumentView.qrText`) | Its lines are what the verification code covers: changing a label, amount format or line order changes the QR of new receipts only (old codes stay valid because they cover their own printed text), the Verify Receipt parser, `testQRTextListsTheReceiptInItsLanguageWithAValidCode`, `testReceiptQRCodeScansInExportedImageAndPDF` |
