# AptReceipt Domain Wiki

- **Last updated:** 2026-10-20
- **Scope:** AptReceipt (aptreceipt)
- **Source of truth:** the Swift sources in `aptreceipt/`. This page summarizes them; update it when the code changes.

## Receipt kinds and serials
- `ReceiptKind` (`ReceiptModels.swift`): `income` (dues collection), `outcome` (resident refund / payment voucher), `managementExpense` (raw value `management_expense`, building expense paid to a vendor).
- A management expense forces flat `0` and hides the flat number. Its receiver is a vendor. Late fees apply only to `income`.
- The document serial is `<prefix>-<4-digit sequence>` (`ReceiptDocumentView.documentSerialFormatted`), and the prefix depends on the app language:

| Kind | tr | ro | en / system |
| --- | --- | --- | --- |
| income | TAH | INC | REC |
| outcome | GID | DIS | EXP |
| managementExpense | HAR | ADM | MGT |

## Drafts, archive records and sequence numbers
- `ReceiptDraft` is the receipt that is shown and exported. `MainScreenViewModel.createReceipt` checks that the issuer and receiver are set, the sequence is above 0 and the amount is at least 0. It then builds the draft, archives it and sets `seqNumber = sequence + 1`.
- `ReceiptRecord` (`ReceiptArchiveStore.swift`) is the archived form (`kindRaw`, `currencyRaw`, `createdAt`). `init(draft:)` and `toDraft()` convert between the two. Both types decode missing late-fee fields with defaults, and `baseAmount` falls back to `amount - lateFeeAmount`.
- `monthYear` ("MMMM yyyy") and `createdDate` ("d MMMM yyyy") are stored as text in the language the receipt was created in. Receiver and issuer are stored `localizedCapitalized`, and empty notes become `-`.
- The archive lives in `Application Support/aptreceipt/receipts_archive.json`, newest first. `add` replaces any record with the same `id`. Invoice attachments are copied to `Application Support/aptreceipt/invoices/` (`InvoiceAttachmentManager`). Vision OCR (`InvoiceOCRParser`) pre-fills the vendor, amount, date and invoice number. Exported PDFs get the attachment as extra pages.
- Archive sheet: filter by kind; search by receiver, notes, sequence, flat or period; open, share on WhatsApp, delete; export CSV (the CSV columns are a machine format).

## Late fee model
- The master switch `isLateFeeEnabled` is off by default. The late-fee card on the main screen appears only for income receipts while it is on.
- `LateFeeCalculator.fee = round2(base x rate/100 x months)` and `grandTotal = round2(base + fee)`, where `round2(v) = (v x 100).rounded() / 100`.
- The rate per receipt is `customLateFeeRate` (a comma is accepted) or, if that is not a number, the stored monthly rate. "Auto-detect" (`autoDetectOverdueMonths`) counts whole months from the receipt date to today, with a minimum of 1.
- The due day and grace period are stored, edited and backed up, but the calculation does not use them.

| Profile | Rate %/month | Due day | Grace days | Quick presets |
| --- | --- | --- | --- | --- |
| `turkey` | 5.0 | 15 | 0 | 3, 5, 7.5, 10 |
| `romania` | 6.0 | 20 | 30 | 3, 5, 6, 10 |
| `international` | 5.0 | 10 | 10 | 2.5, 5, 7.5, 10 |
| `custom` | 5.0 | 15 | 0 | 3, 5, 7.5, 10 |

- Default profile by language: tr -> turkey, ro -> romania, en/system -> international.
- Each profile has a `defaultFootnote(for:)` and a `defaultLegalNotice(for:)` in all three languages. The footnote is printed on the receipt when the late fee is above 0; the legal notice is shown in Settings. A non-empty custom footnote takes precedence (`effectiveLateFeeFootnote`), and the draft keeps the footnote it was created with.
- Choosing a profile resets the rate, due day, grace period and footnote. `setLateFeeCountryProfile` remembers the last rate for each profile under `late_fee_rate_<profile>`.
- Profiles must stay jurisdiction-neutral and toggleable (see `user_rejected_spec.md`).

## Residents, vendors, services
- Owners and phones are stored per flat in UserDefaults under `homeowner_<n>` and `homeowner_phone_<n>`. Owner names are read `localizedCapitalized`. Flats are numbered `1...flatCount`.
- `VendorRecord` (name, category, contactInfo) and `ExpenseServicePreset` (name, defaultDescription, iconName, suggestedVendor) are stored as JSON arrays. Tapping a service chip fills the notes, and fills the receiver with the suggested vendor when the receiver is empty.

## Sample data
- `SampleData.defaults(for:)` gives each language 12 flats, dues of `1750`, 12 residents, 5 vendors and 5 services. tr: "Güleryüz Apartmanı" in TRY; ro: "Asociația Parcul Tineretului" in RON; en/system: "Sunshine Residence" in USD.
- `ReceiptSettingsStore.init` loads the samples when there is no `aptname` key. It also loads them when the saved name is the Romanian sample or empty while the language is en/system (`isScreenshotPollution`).

## Financial report, bulletin board, batch dues
- `ApartmentFinancialReportSheet` totals the archive into income, refunds (`outcome`), management expenses, and net = income - refunds - expenses. Expense categories are grouped by the first `•` segment of the notes, or by the receiver.
- `ReceiptPeriod(monthYear:)` parses "MMMM yyyy" and "LLLL yyyy" in tr_TR, en_US and ro_RO, also in lower case, so the same month written in different languages counts as one period. Its `id` is `yyyy-MM`, and its title is shown in the current locale. Text that cannot be parsed stays as a `raw:` key and is listed as written.
- Dues status: a flat counts as paid when there is an income record for it in the selected period, or in the newest period when "all" is selected. For an unpaid flat the report offers a WhatsApp payment reminder.
- Bulletin board PDF: `ApartmentBulletinBoardView` is rendered at A4 size (595x842) with `ImageRenderer`. The file is named with `L10n.bulletinPdfFileName`.
- `BatchDuesGeneratorSheet` creates one income draft per selected flat with consecutive numbers from a start number. Notes come from `batchReceiptNote`, and a flat without an owner gets `batchReceiverFallback`. The drafts go straight into the archive without a late fee, and `seqNumber` is then set to the next number.

## Sharing
- `WhatsAppShareHelper.whatsAppNumber` keeps digits only. A number starting with `+` is kept as is, and a leading `00` is removed. A local number drops its leading `0` and gets `90` (TRY, 10-digit national number) or `40` (RON, 9-digit); other currencies get no calling code.
- `encodeQueryValue` also escapes `& + = ? # /`. `shareURL` builds `https://wa.me/<number>?text=<message>`, or `https://wa.me/?text=<message>` when there is no number.
- `receiptSummary` and `paymentReminder` are written separately for each language. The reminder fee is one month at the stored rate. `emailURL` builds a `mailto:` link whose body goes through `plainText` to remove the `*` bold markers.

## Backups
- `SystemBackupPackage` (version "2.2"; "2.1" before 3.6) holds the building fields, sequence number, language, currency, residents and phones (`[Int: String]`), vendors, services, archived receipts and optional late-fee fields, and the receipt verification keys (`receiptVerificationKeys`, Base64, current first; restoring puts them first and keeps this Mac's keys).
- Export: `exportSystemBackup()` saves `AptReceipt_Backup_yyyyMMdd_HHmmss.json`. Import (`importSystemBackup`) immediately replaces the settings, owners, vendors, services and the whole archive, bypassing the draft, then posts `.settingsDidSave`.

## Update checker
- `GitHubUpdateChecker` reads `https://api.github.com/repos/berkbb/aptreceipt/releases/latest`. `SemverCompare` strips a leading `v` and any `-suffix` before comparing. The check at launch runs only when `checkUpdatesAtLaunch` is on, and it is off by default.
- Download: the `.dmg` asset is saved to `~/Downloads` without overwriting existing files. Its SHA-256 is checked against `SHA256SUMS.txt` when the release has that file. An Ed25519 `<dmg>.sig` is required when Info.plist has `AptReceiptUpdatePublicEDKey`. The DMG is then opened. A release without a DMG opens the release page instead.

## Settings model
- `ReceiptSettingsStore.shared` writes each `@Published` field to an injectable `UserDefaults` in its `didSet` (`init(defaults:)`; tests use `InMemoryDefaults`). `Keys` lists every key.
- The Settings window edits a `SettingsViewModel` draft. Save & Close (`save(to:)`) validates the flat count (> 0), the sequence (> 0), that the dues are a number, and that building and issuer are set. It then writes the values, clamping the due day to 1-31 and the grace period to 0-60. Cancel discards the draft.
- These changes are saved immediately, outside the draft: logo, signature, theme, currency, language (with its default currency, plus the sample data when the building is a sample), backup import, the launch-update toggle and Reset.
- `resetPreferencesToDefaults()` restores only `Defaults`: en, system theme, USD, late fee off at 5% with due day 15, the international profile and its 10 grace days, an empty footnote and the launch check off. It also clears the per-profile rates. Building data, residents, vendors, receipts, the logo, the signature and the sequence number are not changed.

## Formatting and localization
- `AppFormat.currency` uses `l10n.locale` with the currency symbol, for example "₺1.750,00", "$1,750.00" or "1.750,00 Lei". `AppFormat.percent` puts `%` first in Turkish. Currencies: TRY ₺, RON Lei, USD $, EUR €, GBP £. Amounts in words come from `NumberToWords.convert`.
- Each language has its own strings file, `aptreceipt/<lang>.lproj/Localizable.strings`, for en, tr and ro, with identical keys (404 each) and no `.xcstrings`. `L10n` properties call the private `tr("key")`, which looks the key up in the in-app language's bundle, then in English, then returns the key itself.
- The parity tests (see `.agents/rules/localization_parity.md`) check for identical keys and format specifiers, real translations, no hardcoded text in views and no fixed number formats.
