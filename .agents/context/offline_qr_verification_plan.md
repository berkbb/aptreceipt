# Offline QR Verification — Plan

- **Status:** Approved 2026-10-20. Phase 1 done (verification code, key store, backup, tests). Phase 2 done (labeled QR text with the code, QR sized per module, new footer text). Phase 3 done (Verify Receipt window, File menu and Archive entry points, tests). Phase 4: screenshots (generator image 15; the hand-made About capture 07 kept), README and CHANGELOG done; released as 3.6.0 (build 13).
- **Scope:** Receipt QR code (`ReceiptDocumentView`), a verification secret, a "Verify Receipt" window in AptReceipt, Settings and the system backup.
- **Constraint:** Fully offline. No web page, no server, no domain (`user_rejected_spec.md`). A hosted verification page was proposed first and rejected.

## Goal

1. Anyone who scans the receipt QR code with a phone camera sees the receipt details as clear, labeled lines in the receipt's language — no internet needed.
2. The building manager can check any receipt in AptReceipt, offline: genuine (issued by this app installation and unchanged) or not, shown as a POS-style slip.

A phone camera cannot run code or open a local page from a QR code, so a resident's phone can show the text but cannot prove it is genuine; the proof happens in AptReceipt. The receipt text says this honestly.

## What the QR code contains

Plain UTF-8 text, one field per line, labels from the language files (tr/en/ro, 1:1):

```
AptReceipt
YILDIZ SİTESİ YÖNETİMİ
Tahsilat Makbuzu · TAH-1042
Tarih: 20.10.2026 · Dönem: Ekim 2026
Daire 12 · Ayşe Yılmaz
Aidat: ₺12.000,00
Gecikme bedeli: ₺750,50
Toplam: ₺12.750,50
Yönetici: Mehmet Şahin
Doğrulama: K7QM-2XPA-9TRB-4HWD
```

- Labels and amounts are the ones printed on the receipt (`issueDate`, `period`, payer or payee label, `baseDuesAmount`, `lateFeeCalculated`, `grandTotal`, `invoiceManagerLabel`, the receipt's own currency formatting); only `qrVerificationCodeLabel` is new. Built by `ReceiptDocumentView.qrText`.
- Lines that are hidden on the receipt (flat number, late fee) are left out; notes are left out (length).
- Long names are capped at 40 characters (`ReceiptDocumentView.qrNameLimit`) so the code stays scannable; the worst case of every language and receipt kind stays under 130 pt and is decoded in tests.

## Verification code

- HMAC-SHA256 over the QR text itself (all lines above the code line), normalized so line endings, surrounding spaces, empty lines and Unicode composition do not matter, with the domain prefix `AptReceipt receipt code v1`. Truncated to 80 bits and written as 16 Crockford Base32 characters in four groups (no I, L, O, U; typed O/I/L are read as 0/1). Covering the text instead of separate fields means verification never has to parse amounts back, and any changed character breaks the code. A pinned test value guards the algorithm, because printed codes must stay valid forever.
- Each key is 32 random bytes; the first is created on first use for this installation. Only AptReceipt checks codes, so a shared secret is enough and keeps the code short (an Ed25519 signature would add 86 characters and its public key would be useless without a page).
- 80 bits cannot be guessed; changing any field (amount, name, date) breaks the code.
- Storage: app container `Application Support/aptreceipt/receipt-verification-keys` (32 bytes per key, current first), permissions 0600; an unreadable file is moved aside, never overwritten. Not the Keychain while builds are ad-hoc signed (the Keychain would ask for the password after every update).
- Injectable store (file or in-memory), like `InMemoryDefaults`: tests and screenshot runs never touch the real secret.
- The system backup (format 2.2) carries the keys. Restoring puts the backup's keys first and keeps this Mac's keys after them, so receipts from both still verify. Reset preferences keeps them.

## Verify Receipt window (AptReceipt)

- Opened from the Archive sheet and File → Verify Receipt… (`ReceiptVerificationWindowManager`, `ReceiptVerificationView`, `ReceiptSlipView`).
- Input: drop or choose a PNG, JPEG or PDF of a receipt (QR read with Vision, already used for invoice scanning), or paste the QR text.
- Parsing: `ScannedReceiptVerification` (code line only in the printed `XXXX-XXXX-XXXX-XXXX` form, receipt number via `ReceiptSerial`); archive check: `ReceiptArchiveComparison` compares printed values, not labels, against the receipt rebuilt in its own language.
- Output, offline: a POS-style slip (monospace, 80 mm strip, dashed rules, the same fields) with a stamp:
  - **Genuine** — the code matches this installation's secret; also says whether the receipt is in the archive, and flags differences from the archived record.
  - **Altered or not from this app** — the code does not match.
  - **Older receipt without a code** — plain QR from earlier versions; shown, not verified.
- All texts in tr/en/ro language files.

## Receipt changes

- The QR code contains the text above; 0.5 mm per module, so about 100–110 pt wide, with the footer adapting.
- The footer notice changes from "Scan with phone camera to verify receipt authenticity" to an accurate text, for example "Scan to read the receipt details. The building management verifies the code with AptReceipt." in all three languages.
- Already printed receipts keep their old QR; reprints from the archive get the new one.

## Tests

- Text QR: lines and labels per language, amounts as on the receipt, hidden fields left out, caps applied; the worst case decodes from the JPEG and PDF export paths (Vision).
- Code: the same fields give the same code; any changed field fails; a different secret fails; Base32 grouping.
- Parser: the QR text of every language parses back to the same fields; old plain QR texts are recognized as "without a code".
- Secret store isolation, backup round trip, reset keeps the secret, screenshot runs use an in-memory secret.
- Verify window: decoding from an exported PDF and JPEG of a receipt; archive match and mismatch.
- Language parity for all new keys (existing parity tests).

## Phases

1. Canonical fields, verification code, secret store, backup and tests (no visible change).
2. QR text and receipt footer in three languages, QR sizing, decode tests.
3. Verify Receipt window, menu and archive entry points, tests.
4. Screenshots, README, CHANGELOG; release as 3.6.0 when approved.

## Not doing

- Any web page, server or domain, hosted or cached.
- HTML or `data:` links inside the QR code.
- Public-key signatures for residents (no way to check them offline on a phone without an app).

## Revision 2026-10-20: sealed block instead of readable text

- **Status:** released as 3.6.1 (build 14).

- **Why:** phone cameras offered a web search for the plain-text QR code of 3.6.0, which would send names and amounts to a search engine (`reflexion_memory_log.md`, R-009).
- **QR content:** only the sealed code `AR1.…` (`ReceiptDocumentView.qrContent`). The camera shows it and offers Copy (confirmed by the user on iOS); the resident sends the copied code to the management. A `mailto:` link was tried first and rejected by the user (`user_rejected_spec.md`). Upper-case letters, digits and `.` let the QR use its compact alphanumeric mode (about 73 pt).
- **Block:** `AR1.` + Crockford Base32 of nonce (12) ‖ ChaCha20-Poly1305 ciphertext ‖ tag (16) (`ReceiptQRBlock`). Key: HKDF-SHA256 of the installation key (info `AptReceipt receipt block v1`); nonce: HMAC of the plaintext with a second derived key (SIV-style, deterministic, never shared by two receipts). Plaintext format v1: version, flags (kind, language, flat shown, late fee), varints (number, flat, amount cents, late-fee base, fee, rate × 100, months), ISO currency, five length-prefixed strings (building, payer, manager, date, period; names capped at 40 characters).
- **Verification:** the block opens with one of this installation's keys → genuine; a receipt number written next to the code must match the sealed one. The receipt is rebuilt with `ReceiptPrintedText` in its own language and shown as the POS slip. 3.6.0 text codes and pre-3.6 QR texts are still recognized.
- **Tests:** privacy (the QR content is only the code), opening and tampering, foreign keys, restored keys, a pasted message with text around the code, a pinned block value that a separate Python implementation (`cryptography`) also opens.
