# AptReceipt Symbolic Memory Graph

- **Last updated:** 2026-10-20
- **Scope:** AptReceipt (aptreceipt)
- **Purpose:** Runtime states and transitions. Use a `node_id` to find the code symbol that owns that state.

```mermaid
stateDiagram-v2
    [*] --> launch
    launch --> screenshotRun: --generate-screenshots
    screenshotRun --> [*]: NSApp.terminate
    launch --> mainEditing: WindowGroup shows MainScreen
    launch --> updIdle: GitHubUpdateChecker.shared
    mainEditing --> validationAlert: createReceipt fails
    validationAlert --> mainEditing
    mainEditing --> archived: createReceipt succeeds
    archived --> previewSheet: previewDraft set
    previewSheet --> exportedPDF: Save as PDF
    previewSheet --> exportedJPEG: Save as JPEG
    previewSheet --> shared: WhatsApp / email
    exportedPDF --> previewSheet
    exportedJPEG --> previewSheet
    shared --> previewSheet
    previewSheet --> mainEditing: Close
    mainEditing --> archiveSheet: Archive button
    archiveSheet --> previewSheet: open record (toDraft)
    archiveSheet --> mainEditing: dismiss
    mainEditing --> financialReport: Cash summary button
    financialReport --> bulletinPDF: export bulletin
    bulletinPDF --> financialReport
    financialReport --> mainEditing: dismiss
    mainEditing --> batchDues: Batch dues button
    batchDues --> mainEditing: onComplete / dismiss
    mainEditing --> settingsDraft: SettingsWindowManager.show
    settingsDraft --> immediateWrite: language, theme, currency, logo, signature, reset
    immediateWrite --> settingsDraft
    settingsDraft --> settingsInvalid: save returns false
    settingsInvalid --> settingsDraft
    settingsDraft --> settingsSaved: Save & Close
    settingsDraft --> settingsCancelled: Cancel
    settingsSaved --> mainEditing: .settingsDidSave
    settingsCancelled --> mainEditing
    settingsDraft --> backupExport: export backup
    backupExport --> settingsDraft
    settingsDraft --> backupImport: import backup
    backupImport --> settingsDraft: load(from:) reloads the draft
    updIdle --> updChecking: launch opt-in, menu, Check Now
    updChecking --> updUpToDate
    updChecking --> updAvailable
    updChecking --> updFailed
    updAvailable --> updDownloading: downloadUpdate
    updDownloading --> updVerifying: temp DMG ready
    updVerifying --> updOpened: digest and signature OK
    updVerifying --> updDownloadFailed: checksum or signature rejected
    updDownloading --> updAvailable: cancelDownload
```

| node_id | Meaning | Owning symbol |
| --- | --- | --- |
| `launch` | App start | `AptReceiptApp`, `AppDelegate.applicationDidFinishLaunching` |
| `screenshotRun` | Screenshot mode; shared settings and archive in memory only | `ScreenshotMode`, `AppDelegate.generateScreenshots` |
| `mainEditing` | Editing the receipt form | `MainScreen`, `MainScreenViewModel` |
| `validationAlert` | Invalid form | `MainScreenViewModel.validationError` |
| `archived` | Draft built and stored | `MainScreenViewModel.createReceipt`, `ReceiptArchiveStore.add` |
| `previewSheet` | A4 preview | `MainScreenViewModel.previewDraft`, `ReceiptPreviewSheet`, `ReceiptDocumentView` |
| `exportedPDF` / `exportedJPEG` | File written | `ReceiptPreviewSheet.saveReceiptPDF` / `saveReceiptImage` |
| `shared` | WhatsApp or mail opened | `WhatsAppShareHelper.shareURL` / `emailURL` |
| `archiveSheet` | Archive list | `ReceiptArchiveSheet` (`isPresentingArchive`) |
| `financialReport` / `bulletinPDF` | Cash summary, bulletin export | `ApartmentFinancialReportSheet`, `ApartmentBulletinBoardView` |
| `batchDues` | Batch dues generation | `BatchDuesGeneratorSheet.executeBatchGeneration` |
| `settingsDraft` | Settings window open with a draft | `SettingsWindowManager`, `SettingsTabViewController.draft`, `SettingsView` |
| `immediateWrite` | Change saved outside the draft | `SettingsViewModel.selectLanguage` / `resetPreferences`, `SettingsView.themeSelection` / `currencySelection`, `ReceiptSettingsStore.importLogo` / `importSignature` |
| `settingsInvalid` | Validation alert | `SettingsViewModel.validationError` |
| `settingsSaved` / `settingsCancelled` | Committed or discarded | `SettingsViewModel.save(to:)` / `SettingsView.close()` |
| `backupExport` / `backupImport` | JSON backup | `ReceiptSettingsStore.exportSystemBackup` / `importSystemBackup` |
| `updIdle` ... `updFailed` | Check status | `UpdateCheckStatus` (`idle`, `checking`, `upToDate`, `updateAvailable`, `failed`), `UpdateCheckFailure` |
| `updDownloading` | DMG download | `GitHubUpdateChecker.downloadUpdate`, `UpdateFileDownloader`, `UpdateDownloadWindowManager` |
| `updVerifying` | SHA-256 and Ed25519 checks | `UpdateChecksums.sha256`, `UpdateSignature.isValid` |
| `updOpened` / `updDownloadFailed` | Result alert | `moveToDownloads`, `presentDownloadCompletedAlert` / `presentDownloadFailedAlert` |
