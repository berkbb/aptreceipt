# Snapshot Audit Skill — Persisted Data & Backward Compatibility

- **Last updated:** 2026-10-20
- **Purpose:** Make sure a change never breaks or overwrites what users already have stored.

## What is persisted

- Settings in `UserDefaults` through `ReceiptSettingsStore` (keys in `ReceiptSettingsStore.Keys`, owners and phones per flat, vendors, services, logo, signature, late-fee configuration, per-profile saved rates).
- The receipt archive: `Application Support/aptreceipt/receipts_archive.json` (`ReceiptArchiveStore`).
- Receipt verification keys: `Application Support/aptreceipt/receipt-verification-keys` (`ReceiptVerificationKeyStore`, 32 bytes per key, current first). Never delete or replace them: printed receipts are verified with them forever; restoring a backup or a recovery code (`ReceiptRecoveryCode`, format pinned by `testRecoveryCodeFormatIsPinned`) adds keys in front and keeps the existing ones.
- User backups: the JSON package from *Export Full System Backup* (`SystemBackupPackage`, now with `receiptVerificationKeys`).

## When to use

Before changing a stored key, a `Codable` model (`ReceiptRecord`, `ReceiptDraft`, `SystemBackupPackage`, `VendorRecord`, `ExpenseServicePreset`), the reset scope or anything that writes to the archive.

## Checklist

1. **Keys** are never renamed or removed; new keys get a fresh-install value in `ReceiptSettingsStore.Defaults`.
2. **Decoding** of older JSON keeps working: new fields are optional or defaulted (see `testReceiptDraftBackwardCompatibilityWithLegacyJSON`).
3. **Backups** from older versions still import; exports stay importable by the previous version where possible.
4. **Reset** touches preferences only (language, theme, currency, late-fee configuration, launch check); never building data, residents, vendors, receipts, logo, signature or the receipt number.
5. **No silent overwrite** of the archive or settings without explicit user action (`user_rejected_spec.md`). Any tool that writes sample data must back up and restore real data or use a separate store.
6. **Tests** use `InMemoryDefaults` and `ReceiptArchiveStore(fileURL: nil)` (or a temporary file URL); verify the real archive file's checksum is unchanged after scratch runs.
