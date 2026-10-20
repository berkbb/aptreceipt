# Quality Plan — Money, Late Fee, Keys, Code Layout, Buildings

- **Status:** Proposed 2026-10-20, waiting for approval. Nothing is built yet.
- **Source:** the user's review of AptReceipt's weak points. Ad-hoc signed distribution is the user's choice and is not in scope (`user_rejected_spec.md`).
- **Decisions (user, 2026-10-20):** late months count every started month after the due day plus grace; several buildings on the Mac; a recovery code for the verification keys.

Every phase keeps existing data and behavior unless stated, ends with the full test suite green, and is committed separately.

## Phase 1 — Decimal money arithmetic

- `LateFeeCalculator` computes in `Decimal` and rounds half-up to cents (`NSDecimalNumber.RoundingMode.plain`): 1.005 → 1.01, 2.675 → 2.68, never the binary-`Double` result.
- Totals that add many amounts (cash summary, archive total, report categories, batch dues) sum in `Decimal`.
- Stored values keep their JSON number form (`Double`) so archives and backups stay compatible; they are rounded to cents when read into a calculation.
- Tests: half-cent cases, KMK 5 % examples, Romanian 0.2 % examples, sums of many amounts, archive round trip unchanged.

## Phase 2 — Due day and grace period in the late fee

- Due date = the due day in the receipt period's month (clamped to the month's last day, e.g. 31 → 30 November).
- Grace end = due date + grace days. Paid on or before the grace end → no late fee.
- Late months = every started month after the grace end up to the payment date. Example: due 15 October, grace 0, paid 3 November → 1; paid 16 November → 2.
- `MainScreenViewModel.autoDetectOverdueMonths` uses this rule (it ignored both settings) and turns the late fee off when nothing is overdue; the months stay editable by hand.
- The main screen shows the due date and grace end used, in all three languages.
- Tests: month ends, leap years, grace across a month boundary, each country profile's defaults, payment before the due day.

## Phase 3 — Late-fee profile texts into the language files

- `LateFeeCountryProfile` titles, footnotes and legal notices are written inline in Turkish, English and Romanian (12 places in `LateFee.swift`), against the one-file-per-language rule. Move them to `tr/en/ro.lproj/Localizable.strings` with identical keys.
- Extend the parity tests to fail on inline per-language patterns (`isTurkish ?`, `case .turkish: return "`).

## Phase 4 — Recovery code for the verification keys

- Settings shows, on request, the current key as a recovery code: 32 bytes plus a 2-byte checksum in Crockford Base32, 56 characters in 14 groups of 4, with Copy and a warning to keep it private.
- "Restore from Recovery Code" accepts it (spaces, dashes, lower case, O/I/L tolerated), rejects a wrong checksum, and adds the key in front of the existing ones (`ReceiptVerificationKeyStore.restore`), so older receipts keep verifying.
- All texts in three language files.
- Tests: round trip, typos caught by the checksum, restore keeps existing keys, nothing written in tests.

## Phase 5 — Code layout (no behavior change)

- Split the largest files by responsibility:
  - `ReceiptViewController.swift` (1533 lines): preview sheet, `ReceiptDocumentView`, invoice scanning and attachments, image export helpers.
  - `PreferencesViewController.swift` (1617): one file per settings tab plus the shared view model.
  - `AppDelegate.swift` (950): app scene and delegate, screenshot generator, About window, Settings window, menu bar localization.
  - `MainScreen.swift` (1083): main screen and its sub-views.
- Split `aptreceiptTests.swift` (1791 lines) into files per area with a shared test-support file.
- Only moves; the test suite and the screenshot generator output must stay identical.

## Phase 6 — Several buildings on the Mac

- A building list with an active building; switching, adding, renaming and deleting (with confirmation) from the main screen header and Settings.
- Per building: building fields, residents and phones, vendors, services, logo, signature, late-fee settings, currency, receipt number, archive. App-wide: language, theme, launch update check, verification keys.
- The existing data becomes the first building without moving anything (same keys and archive file); new buildings use prefixed keys and their own archive file.
- Backups export and import the active building; Verify Receipt compares with every building's archive.
- Screenshot runs and tests stay in memory.
- Tests: existing data unchanged after the upgrade, isolation between buildings, switching, deleting, backup per building.

## Phase 7 — Documentation and release

- CHANGELOG, README, screenshots, `.agents` notes; release after approval.
